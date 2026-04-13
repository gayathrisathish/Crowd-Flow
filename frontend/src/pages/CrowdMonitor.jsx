import { useState, useEffect, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";
import { MapContainer, TileLayer, CircleMarker, Circle, Popup, useMap } from "react-leaflet";
import { getCrowdData, simulateCrowd, resetCrowd, getEvent } from "../api";
import "leaflet/dist/leaflet.css";
import "./CrowdMonitor.css";

const MAP_CENTER = [13.0840, 80.2150]; // Chennai — matches hotspot zones

function FitBounds({ points }) {
  const map = useMap();
  useEffect(() => {
    if (points.length > 0) {
      const lats = points.map(p => p.lat);
      const lngs = points.map(p => p.lng);
      map.fitBounds([
        [Math.min(...lats) - 0.005, Math.min(...lngs) - 0.005],
        [Math.max(...lats) + 0.005, Math.max(...lngs) + 0.005],
      ]);
    }
  }, [points, map]);
  return null;
}

export default function CrowdMonitor() {
  const { eventId } = useParams();
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const [data, setData] = useState({
    points: [],
    clusters: [],
    total_users: 0,
    active_clusters: 0,
    high_density: 0,
    threshold: 40,
    system_density: 0,
  });
  const [event, setEvent] = useState(null);
  const [selectedCluster, setSelectedCluster] = useState(null);
  const [refreshInterval, setRefreshInterval] = useState(5);
  const [loading, setLoading] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const res = await getCrowdData(eventId);
      setData((prev) => ({
        ...prev,
        ...res.data,
        system_density: res.data?.system_density ?? prev.system_density ?? 0,
      }));
    } catch (err) {
      console.error("Failed to load crowd data", err);
    }
  }, [eventId]);

  const getEventCenter = () => {
    const lat = Number(event?.lat ?? event?.latitude ?? MAP_CENTER[0]);
    const lng = Number(event?.lng ?? event?.longitude ?? MAP_CENTER[1]);
    return [lat, lng];
  };

  const createRandomPoints = (count) => {
    const [centerLat, centerLng] = getEventCenter();
    return Array.from({ length: count }, (_, idx) => {
      const angle = Math.random() * Math.PI * 2;
      const distance = Math.sqrt(Math.random()) * 0.01;
      return {
        id: `local-${Date.now()}-${idx}`,
        lat: Number((centerLat + Math.cos(angle) * distance).toFixed(6)),
        lng: Number((centerLng + Math.sin(angle) * distance).toFixed(6)),
      };
    });
  };

  const createOfflineClusters = (totalUsers, activeClusters, highDensityCount, threshold) => {
    const [centerLat, centerLng] = getEventCenter();
    const base = Math.max(1, Math.floor(totalUsers / activeClusters));
    const clusterIds = Array.from({ length: activeClusters }, (_, i) => i);
    const shuffled = [...clusterIds].sort(() => Math.random() - 0.5);
    const highDensitySet = new Set(shuffled.slice(0, Math.min(highDensityCount, activeClusters)));

    return clusterIds.map((id) => {
      const angle = Math.random() * Math.PI * 2;
      const distance = 0.001 + Math.random() * 0.004;
      const jitter = Math.floor(Math.random() * 5) - 2;
      const isHighDensity = highDensitySet.has(id);
      const size = Math.max(1, base + jitter + (isHighDensity ? Math.floor(Math.random() * 8) + 4 : 0));

      return {
        id,
        lat: Number((centerLat + Math.cos(angle) * distance).toFixed(6)),
        lng: Number((centerLng + Math.sin(angle) * distance).toFixed(6)),
        size,
        exceeds_threshold: isHighDensity || size > threshold,
        status: isHighDensity || size > threshold ? "CROWDED" : "NORMAL",
      };
    });
  };

  const applyOfflineSimulation = () => {
    const newPoints = createRandomPoints(20);
    const randomActiveClusters = Math.floor(Math.random() * 4) + 3; // 3-6
    const randomHighDensity = Math.floor(Math.random() * 3) + 1; // 1-3
    const densityIncrease = Math.floor(Math.random() * 11) + 15; // 15-25

    setData((prev) => {
      const nextTotalUsers = (prev.total_users || 0) + 20;
      const threshold = prev.threshold || 40;
      const offlineClusters = createOfflineClusters(nextTotalUsers, randomActiveClusters, randomHighDensity, threshold);

      return {
        ...prev,
        points: [...(prev.points || []), ...newPoints],
        clusters: offlineClusters,
        total_users: nextTotalUsers,
        active_clusters: randomActiveClusters,
        high_density: randomHighDensity,
        system_density: Math.min(100, (prev.system_density || 0) + densityIncrease),
        threshold,
      };
    });
  };

  useEffect(() => {
    loadData();
    getEvent(eventId).then(res => setEvent(res.data)).catch(() => {});
  }, [eventId, loadData]);

  // Auto-refresh
  useEffect(() => {
    const timer = setInterval(loadData, refreshInterval * 1000);
    return () => clearInterval(timer);
  }, [loadData, refreshInterval]);

  const handleSimulate = async () => {
    setLoading(true);
    try {
      const res = await simulateCrowd(eventId);
      setData((prev) => ({
        ...prev,
        ...res.data,
        system_density: res.data?.system_density ?? prev.system_density ?? 0,
      }));
    } catch (err) {
      console.error("Simulate failed", err);
      applyOfflineSimulation();
    }
    setLoading(false);
  };

  const handleReset = async () => {
    if (!confirm("Reset all crowd data for this event?")) return;
    try {
      await resetCrowd(eventId);
      setData({
        points: [],
        clusters: [],
        total_users: 0,
        active_clusters: 0,
        high_density: 0,
        threshold: 40,
        system_density: 0,
      });
      setSelectedCluster(null);
    } catch (err) {
      console.error("Reset failed", err);
      setData({
        points: [],
        clusters: [],
        total_users: 0,
        active_clusters: 0,
        high_density: 0,
        threshold: 40,
        system_density: 0,
      });
      setSelectedCluster(null);
    }
  };

  const threshold = Number(data?.threshold ?? 40);
  const normalizedClusters = (data?.clusters || []).map((c) => {
    const size = Number(c.size || 0);
    const exceedsThreshold = size >= threshold;
    return {
      ...c,
      size,
      exceeds_threshold: exceedsThreshold,
      status: exceedsThreshold ? "CROWDED" : "NORMAL",
    };
  });
  const alertClusters = normalizedClusters.filter((c) => c.exceeds_threshold);
  const highDensityCount = alertClusters.length;
  const computedDensity = data?.total_users
    ? Math.min(100, Math.round((data.total_users / (data.threshold * data.active_clusters || 1)) * 100))
    : 0;
  const systemDensity = data?.system_density ?? computedDensity;

  return (
    <div className="crowd-monitor">
      {/* Top Bar */}
      <header className="cm-topbar">
        <div className="cm-topbar-left">
          <span className="cm-logo">🚨 DensityX Monitor</span>
        </div>
        <div className="cm-topbar-center">
          <span className="cm-live-badge">🟢 Live</span>
          <button className="cm-logout-btn" onClick={logout}>🔴 Logout</button>
        </div>
        <div className="cm-topbar-right">
          <button className="cm-back-btn" onClick={() => navigate("/admin")}>← Back to Dashboard</button>
        </div>
      </header>

      {/* Alert Banner */}
      {alertClusters.length > 0 && (
        <div className="cm-alert-banner">
          ⚠️ Cluster detected — Crowded area! ({alertClusters.length} zone{alertClusters.length > 1 ? "s" : ""} exceeding {data?.threshold} people)
        </div>
      )}

      <div className="cm-body">
        {/* Map Area */}
        <div className="cm-map-area">
          <MapContainer
            center={MAP_CENTER}
            zoom={14}
            className="cm-map"
            scrollWheelZoom={true}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            {data?.points?.length > 0 && <FitBounds points={data.points} />}

            {/* Individual people markers */}
            {data?.points?.map(p => (
              <CircleMarker
                key={p.id}
                center={[p.lat, p.lng]}
                radius={4}
                pathOptions={{
                  color: "#2563eb",
                  fillColor: "#3b82f6",
                  fillOpacity: 0.8,
                  weight: 1,
                }}
              />
            ))}

            {/* Cluster circles */}
            {normalizedClusters.map(c => (
              <Circle
                key={`cluster-${c.id}`}
                center={[c.lat, c.lng]}
                radius={c.exceeds_threshold ? 45 + c.size * 2 : 25 + c.size * 1.5}
                pathOptions={{
                  color: c.exceeds_threshold ? "#ff0000" : "#ff8800",
                  fillColor: c.exceeds_threshold ? "#ff0000" : "#ff8800",
                  fillOpacity: c.exceeds_threshold ? 0.4 : 0.2,
                  weight: 2,
                }}
                eventHandlers={{
                  click: () => setSelectedCluster(c),
                }}
              >
                <Popup>
                  <div className="cm-popup">
                    <strong>Cluster {c.id + 1}</strong><br />
                    <b>Size:</b> {c.size} users<br />
                    <b>Center:</b> {c.lat}, {c.lng}<br />
                    <b>Status:</b> <span className={c.exceeds_threshold ? "high-risk" : "normal"}>
                      {c.exceeds_threshold ? "🔴 CROWDED" : "🟢 NORMAL"}
                    </span>
                  </div>
                </Popup>
              </Circle>
            ))}
          </MapContainer>

          {/* Map controls overlay */}
          <div className="cm-map-controls">
            <button
              className="cm-simulate-btn"
              onClick={handleSimulate}
              disabled={loading}
            >
              {loading ? "Simulating..." : "➕ Simulate Crowd (+20)"}
            </button>
            <button className="cm-reset-btn" onClick={handleReset}>
              🔄 Reset
            </button>
          </div>

          <div className="cm-map-info">
            📍 Map Info — {event?.name || `Event #${eventId}`} · {event?.location || "Chennai"}
          </div>
        </div>

        {/* Control Panel (Right Sidebar) */}
        <aside className="cm-control-panel">
          <div className="cm-panel-header">
            <span>⚙️ Control Panel</span>
            <button className="cm-refresh-icon" onClick={loadData} title="Refresh">🔄</button>
          </div>

          {/* Alerts Active */}
          {alertClusters.length > 0 && (
            <div className="cm-alerts-section">
              <h3>🚨 ALERTS ACTIVE ({alertClusters.length})</h3>
              {alertClusters.map(c => (
                <div key={c.id} className="cm-alert-card" onClick={() => setSelectedCluster(c)}>
                  <div className="cm-alert-title">Cluster {c.id + 1}</div>
                  <div>👥 Users: {c.size}</div>
                  <div>📍 Center: {c.lat}, {c.lng}</div>
                  <div className="cm-alert-warning">⚠️ Exceeds threshold ({data?.threshold} users)</div>
                </div>
              ))}
            </div>
          )}

          {/* Stats */}
          <div className="cm-stat-card">
            <div className="cm-stat-label">Total Users</div>
            <div className="cm-stat-value">{data?.total_users || 0} <span className="cm-stat-icon">👥</span></div>
          </div>

          <div className="cm-stat-card">
            <div className="cm-stat-label">Active Clusters</div>
            <div className="cm-stat-value accent-red">{data?.active_clusters || 0} <span className="cm-stat-icon">📍</span></div>
          </div>

          <div className="cm-stat-card">
            <div className="cm-stat-label">High Density</div>
            <div className="cm-stat-value accent-red">{highDensityCount} <span className="cm-stat-icon">🚨</span></div>
          </div>

          <div className="cm-stat-card">
            <div className="cm-stat-label">System Density</div>
            <div className="cm-stat-value" style={{ color: systemDensity > 80 ? "#ff4444" : "#22c55e" }}>
              {systemDensity}% <span className="cm-stat-icon">📊</span>
            </div>
          </div>

          {/* Cluster Details */}
          <div className="cm-cluster-details">
            <h4>📋 Cluster Details</h4>
            {normalizedClusters.map(c => (
              <div
                key={c.id}
                className={`cm-cluster-card ${c.exceeds_threshold ? "danger" : ""}`}
                onClick={() => setSelectedCluster(c)}
              >
                <div className="cm-cluster-name">Cluster {c.id + 1}</div>
                <div>📍 Size: {c.size} users</div>
                <div>📌 Lat: {c.lat}</div>
                <div>📌 Lon: {c.lng}</div>
                <span className={`cm-density-badge ${c.exceeds_threshold ? "high" : "low"}`}>
                  {c.exceeds_threshold ? "CROWDED" : "NORMAL"}
                </span>
              </div>
            ))}
            {normalizedClusters.length === 0 && (
              <p className="cm-muted">No clusters yet. Click "Simulate Crowd" to add people.</p>
            )}
          </div>

          {/* Refresh Interval */}
          <div className="cm-refresh-section">
            <label>🟢 Refresh Interval</label>
            <select value={refreshInterval} onChange={e => setRefreshInterval(Number(e.target.value))}>
              <option value={2}>2 seconds</option>
              <option value={5}>5 seconds</option>
              <option value={10}>10 seconds</option>
              <option value={30}>30 seconds</option>
            </select>
          </div>

          {/* Selected Cluster */}
          {selectedCluster && (
            <div className="cm-selected-cluster">
              <h4>📍 Selected Cluster</h4>
              <div>ID: {selectedCluster.id + 1}</div>
              <div>Size: {selectedCluster.size} users</div>
              <div>Status: {selectedCluster.status}</div>
              <div>Lat: {selectedCluster.lat}</div>
              <div>Lng: {selectedCluster.lng}</div>
            </div>
          )}
        </aside>
      </div>
    </div>
  );
}
