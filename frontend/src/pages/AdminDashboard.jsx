import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";
import {
  getEvents, createEvent, updateEvent, deleteEvent,
  getAllTickets, getAlerts, createAlert,
  verifyTicket, getAuditLogs,
} from "../api";
import {
  HiOutlineCalendar, HiOutlineTicket, HiOutlineBell,
  HiOutlineShieldCheck, HiOutlineClipboardDocumentList,
  HiOutlineArrowRightStartOnRectangle, HiOutlineMapPin,
} from "react-icons/hi2";

/* ─── tiny sub-components ─── */
function Stat({ icon, label, value, color }) {
  return (
    <div className="stat-card" style={{ borderTop: `3px solid ${color}` }}>
      <div className="stat-icon" style={{ color }}>{icon}</div>
      <div>
        <p className="stat-value">{value}</p>
        <p className="stat-label">{label}</p>
      </div>
    </div>
  );
}

/* ─── Heatmap with links to monitor ─── */
function CrowdHeatmap({ events, tickets }) {
  const navigate = useNavigate();
  const data = events.map((ev) => {
    const count = tickets.filter((t) => t.event_id === ev.id && t.status === "used").length;
    const total = tickets.filter((t) => t.event_id === ev.id).length;
    const pct = total > 0 ? Math.round((count / total) * 100) : 0;
    return { ...ev, verified: count, total, pct };
  });

  return (
    <div className="panel">
      <h3><HiOutlineMapPin /> Crowd Heatmap</h3>
      <div className="heatmap-grid">
        {data.map((d) => (
          <div
            key={d.id}
            className="heatmap-cell clickable"
            style={{
              background: `rgba(34,197,94, ${Math.max(0.1, d.pct / 100)})`,
              cursor: "pointer",
            }}
            onClick={() => navigate(`/admin/monitor/${d.id}`)}
          >
            <strong>{d.name}</strong>
            <span>{d.verified}/{d.total} verified ({d.pct}%)</span>
            <span className="heatmap-link">📈 Open Crowd-Flow Monitor →</span>
          </div>
        ))}
        {data.length === 0 && <p className="muted">No event data yet.</p>}
      </div>
    </div>
  );
}

export default function AdminDashboard() {
  const { user, logout } = useAuth();
  const [tab, setTab] = useState("overview");

  const [events, setEvents] = useState([]);
  const [tickets, setTickets] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  /* form states */
  const [evForm, setEvForm] = useState({ name: "", location: "", date: "" });
  const [alertForm, setAlertForm] = useState({ event_id: "", message: "", level: "alert" });
  const [verifyId, setVerifyId] = useState("");
  const [editEvent, setEditEvent] = useState(null);

  const load = useCallback(async () => {
    try {
      const [ev, tk, al, au] = await Promise.all([
        getEvents(), getAllTickets(), getAlerts(), getAuditLogs(),
      ]);
      setEvents(ev.data);
      setTickets(tk.data);
      setAlerts(al.data);
      setAuditLogs(au.data);
    } catch { /* ignore */ }
  }, []);

  useEffect(() => { load(); }, [load]);

  /* actions */
  const handleCreateEvent = async (e) => {
    e.preventDefault();
    setError("");
    try {
      await createEvent({ ...evForm, date: new Date(evForm.date).toISOString() });
      setEvForm({ name: "", location: "", date: "" });
      load();
    } catch (err) { setError(err.response?.data?.detail || "Failed"); }
  };

  const handleUpdateEvent = async (e) => {
    e.preventDefault();
    setError("");
    try {
      await updateEvent(editEvent.id, {
        name: editEvent.name,
        location: editEvent.location,
        date: new Date(editEvent.date).toISOString(),
      });
      setEditEvent(null);
      load();
    } catch (err) { setError(err.response?.data?.detail || "Failed"); }
  };

  const handleDeleteEvent = async (id) => {
    if (!confirm("Delete this event?")) return;
    try { await deleteEvent(id); load(); }
    catch (err) { setError(err.response?.data?.detail || "Failed"); }
  };

  const handleCreateAlert = async (e) => {
    e.preventDefault();
    setError("");
    try {
      await createAlert({ ...alertForm, event_id: Number(alertForm.event_id) });
      setAlertForm({ event_id: "", message: "", level: "alert" });
      load();
    } catch (err) { setError(err.response?.data?.detail || "Failed"); }
  };

  const handleVerify = async (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    try {
      await verifyTicket(verifyId);
      setSuccess(`Ticket ${verifyId} verified successfully!`);
      setVerifyId("");
      load();
    } catch (err) { setError(err.response?.data?.detail || "Failed"); }
  };

  const activeTickets = tickets.filter((t) => t.status === "active").length;
  const usedTickets = tickets.filter((t) => t.status === "used").length;

  const TABS = [
    { key: "overview", label: "Overview", icon: <HiOutlineMapPin /> },
    { key: "events", label: "Events", icon: <HiOutlineCalendar /> },
    { key: "tickets", label: "Tickets", icon: <HiOutlineTicket /> },
    { key: "alerts", label: "Alerts", icon: <HiOutlineBell /> },
    { key: "verify", label: "Verify", icon: <HiOutlineShieldCheck /> },
    { key: "audit", label: "Audit Log", icon: <HiOutlineClipboardDocumentList /> },
  ];

  return (
    <div className="dashboard">
      {/* sidebar */}
      <aside className="sidebar">
        <div className="sidebar-logo">CF</div>
        <nav>
          {TABS.map((t) => (
            <button
              key={t.key}
              className={tab === t.key ? "active" : ""}
              onClick={() => { setTab(t.key); setError(""); setSuccess(""); }}
            >
              {t.icon} {t.label}
            </button>
          ))}
        </nav>
        <button className="logout-btn" onClick={logout}>
          <HiOutlineArrowRightStartOnRectangle /> Logout
        </button>
      </aside>

      {/* main */}
      <main className="main-content">
        <header className="topbar">
          <h2>{TABS.find((t) => t.key === tab)?.label}</h2>
          <span className="user-badge">Admin: {user?.username}</span>
        </header>

        {error && <div className="error-msg">{error}</div>}
        {success && <div className="success-msg">{success}</div>}

        {/* ── Overview ── */}
        {tab === "overview" && (
          <>
            <div className="stats-row">
              <Stat icon={<HiOutlineCalendar />} label="Events" value={events.length} color="#2563EB" />
              <Stat icon={<HiOutlineTicket />} label="Active Tickets" value={activeTickets} color="#22C55E" />
              <Stat icon={<HiOutlineShieldCheck />} label="Verified" value={usedTickets} color="#8B5CF6" />
              <Stat icon={<HiOutlineBell />} label="Alerts" value={alerts.length} color="#EF4444" />
            </div>
            <CrowdHeatmap events={events} tickets={tickets} />
            <div className="panel">
              <h3><HiOutlineBell /> Recent Alerts</h3>
              {alerts.slice(0, 5).map((a) => (
                <div key={a.id} className={`alert-row ${a.level}`}>
                  <span className="alert-badge">{a.level.toUpperCase()}</span>
                  <span>{a.message}</span>
                  <span className="muted">{new Date(a.created_at).toLocaleString()}</span>
                </div>
              ))}
              {alerts.length === 0 && <p className="muted">No alerts.</p>}
            </div>
          </>
        )}

        {/* ── Events ── */}
        {tab === "events" && (
          <div className="panel">
            <h3>Create Event</h3>
            <form className="inline-form" onSubmit={handleCreateEvent}>
              <input placeholder="Name" value={evForm.name} onChange={(e) => setEvForm({ ...evForm, name: e.target.value })} required />
              <input placeholder="Location" value={evForm.location} onChange={(e) => setEvForm({ ...evForm, location: e.target.value })} required />
              <input type="datetime-local" value={evForm.date} onChange={(e) => setEvForm({ ...evForm, date: e.target.value })} required />
              <button type="submit">Add</button>
            </form>

            {editEvent && (
              <>
                <h3 style={{ marginTop: "1.5rem" }}>Edit Event #{editEvent.id}</h3>
                <form className="inline-form" onSubmit={handleUpdateEvent}>
                  <input value={editEvent.name} onChange={(e) => setEditEvent({ ...editEvent, name: e.target.value })} required />
                  <input value={editEvent.location} onChange={(e) => setEditEvent({ ...editEvent, location: e.target.value })} required />
                  <input type="datetime-local" value={editEvent.date?.slice(0, 16)} onChange={(e) => setEditEvent({ ...editEvent, date: e.target.value })} required />
                  <button type="submit">Save</button>
                  <button type="button" className="secondary" onClick={() => setEditEvent(null)}>Cancel</button>
                </form>
              </>
            )}

            <table>
              <thead><tr><th>ID</th><th>Name</th><th>Location</th><th>Date</th><th>Actions</th></tr></thead>
              <tbody>
                {events.map((ev) => (
                  <tr key={ev.id}>
                    <td>{ev.id}</td>
                    <td>{ev.name}</td>
                    <td>{ev.location}</td>
                    <td>{new Date(ev.date).toLocaleString()}</td>
                    <td>
                      <button className="small" onClick={() => setEditEvent({ ...ev, date: ev.date?.slice(0, 16) })}>Edit</button>
                      <button className="small danger" onClick={() => handleDeleteEvent(ev.id)}>Del</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* ── Tickets ── */}
        {tab === "tickets" && (
          <div className="panel">
            <table>
              <thead><tr><th>Ticket ID</th><th>User</th><th>Event</th><th>Status</th></tr></thead>
              <tbody>
                {tickets.map((t) => (
                  <tr key={t.id}>
                    <td className="mono">{t.ticket_id}</td>
                    <td>{t.user_id}</td>
                    <td>{t.event_id}</td>
                    <td><span className={`badge ${t.status}`}>{t.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* ── Alerts ── */}
        {tab === "alerts" && (
          <div className="panel">
            <h3>Create Alert</h3>
            <form className="inline-form" onSubmit={handleCreateAlert}>
              <select value={alertForm.event_id} onChange={(e) => setAlertForm({ ...alertForm, event_id: e.target.value })} required>
                <option value="">Select event</option>
                {events.map((ev) => <option key={ev.id} value={ev.id}>{ev.name}</option>)}
              </select>
              <input placeholder="Message" value={alertForm.message} onChange={(e) => setAlertForm({ ...alertForm, message: e.target.value })} required />
              <select value={alertForm.level} onChange={(e) => setAlertForm({ ...alertForm, level: e.target.value })}>
                <option value="alert">Alert</option>
                <option value="safe">Safe</option>
              </select>
              <button type="submit">Send</button>
            </form>
            <div style={{ marginTop: "1rem" }}>
              {alerts.map((a) => (
                <div key={a.id} className={`alert-row ${a.level}`}>
                  <span className="alert-badge">{a.level.toUpperCase()}</span>
                  <span>{a.message}</span>
                  <span className="muted">Event {a.event_id} &middot; {new Date(a.created_at).toLocaleString()}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ── Verify ── */}
        {tab === "verify" && (
          <div className="panel">
            <h3>Verify Ticket</h3>
            <form className="inline-form" onSubmit={handleVerify}>
              <input placeholder="Enter Ticket UUID" value={verifyId} onChange={(e) => setVerifyId(e.target.value)} required style={{ flex: 2 }} />
              <button type="submit">Verify</button>
            </form>
          </div>
        )}

        {/* ── Audit ── */}
        {tab === "audit" && (
          <div className="panel">
            <table>
              <thead><tr><th>Time</th><th>Action</th><th>User</th><th>Details</th></tr></thead>
              <tbody>
                {auditLogs.map((l) => (
                  <tr key={l.id}>
                    <td>{new Date(l.timestamp).toLocaleString()}</td>
                    <td><span className="mono">{l.action}</span></td>
                    <td>{l.user_id ?? "—"}</td>
                    <td>{l.details ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}
