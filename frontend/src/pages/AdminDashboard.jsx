import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";
import {
  createAlert,
  createEvent,
  deleteEvent,
  getAlerts,
  getAllTickets,
  getAuditLogs,
  getEvents,
  updateEvent,
  verifyTicket,
} from "../api";
import {
  HiOutlineCalendar, HiOutlineTicket, HiOutlineBell,
  HiOutlineShieldCheck, HiOutlineClipboardDocumentList,
  HiOutlineArrowRightStartOnRectangle, HiOutlineMapPin,
} from "react-icons/hi2";

const INITIAL_EVENTS = [];
const INITIAL_TICKETS = [];
const INITIAL_ALERTS = [];
const INITIAL_AUDIT_LOGS = [];

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
              background: "var(--surface2)",
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

  const [events, setEvents] = useState(INITIAL_EVENTS);
  const [tickets, setTickets] = useState(INITIAL_TICKETS);
  const [alerts, setAlerts] = useState(INITIAL_ALERTS);
  const [auditLogs, setAuditLogs] = useState(INITIAL_AUDIT_LOGS);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  /* form states */
  const [evForm, setEvForm] = useState({ name: "", location: "", date: "" });
  const [alertForm, setAlertForm] = useState({ event_id: "", message: "", level: "alert" });
  const [verifyId, setVerifyId] = useState("");
  const [editEvent, setEditEvent] = useState(null);

  const loadDashboardData = useCallback(async () => {
    try {
      const [eventsRes, ticketsRes, alertsRes, auditRes] = await Promise.all([
        getEvents(),
        getAllTickets(),
        getAlerts(),
        getAuditLogs(),
      ]);

      setEvents((eventsRes.data || []).map((ev) => ({
        id: ev.event_id,
        name: ev.name,
        location: ev.location,
        date: ev.date,
      })));

      setTickets((ticketsRes.data || []).map((t) => ({
        id: t.ticket_pk_id,
        ticket_id: t.ticket_id,
        user: t.user_id,
        event_id: t.event_id,
        status: t.status,
      })));

      setAlerts((alertsRes.data || []).map((a) => ({
        id: a.alert_id,
        event_id: a.event_id,
        message: a.message,
        level: a.level,
        created_at: a.created_at,
      })));

      setAuditLogs((auditRes.data || []).map((l) => ({
        id: l.audit_id,
        timestamp: l.timestamp,
        action: l.action,
        user: l.user_id,
        details: l.details,
      })));

      setError("");
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to load dashboard data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadDashboardData();
    const interval = setInterval(loadDashboardData, 5000);
    return () => clearInterval(interval);
  }, [loadDashboardData]);

  /* actions */
  const handleCreateEvent = async (e) => {
    e.preventDefault();
    setError("");
    const eventDate = new Date(evForm.date);
    if (Number.isNaN(eventDate.getTime())) {
      setError("Invalid event date");
      return;
    }

    try {
      await createEvent({
        name: evForm.name,
        location: evForm.location,
        date: eventDate.toISOString(),
      });
      setEvForm({ name: "", location: "", date: "" });
      setSuccess("Event created");
      loadDashboardData();
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to create event");
    }
  };

  const handleUpdateEvent = async (e) => {
    e.preventDefault();
    setError("");
    const updatedDate = new Date(editEvent.date);
    if (Number.isNaN(updatedDate.getTime())) {
      setError("Invalid event date");
      return;
    }

    try {
      await updateEvent(editEvent.id, {
        name: editEvent.name,
        location: editEvent.location,
        date: updatedDate.toISOString(),
      });
      setEditEvent(null);
      setSuccess("Event updated");
      loadDashboardData();
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to update event");
    }
  };

  const handleDeleteEvent = async (id) => {
    if (!confirm("Delete this event?")) return;
    setError("");
    try {
      await deleteEvent(id);
      setSuccess("Event deleted");
      loadDashboardData();
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to delete event");
    }
  };

  const handleCreateAlert = async (e) => {
    e.preventDefault();
    setError("");
    const eventId = Number(alertForm.event_id);
    if (!eventId) {
      setError("Please select an event");
      return;
    }

    try {
      await createAlert({
        event_id: eventId,
        message: alertForm.message,
        level: alertForm.level,
      });
      setAlertForm({ event_id: "", message: "", level: "alert" });
      setSuccess("Alert created");
      loadDashboardData();
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to create alert");
    }
  };

  const handleVerify = async (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    const normalized = verifyId.trim();
    if (!normalized) {
      setError("Ticket id is required");
      return;
    }

    try {
      await verifyTicket(normalized);
      setSuccess(`Ticket ${normalized} verified successfully!`);
      setVerifyId("");
      loadDashboardData();
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to verify ticket");
    }
  };

  const eventMap = Object.fromEntries(events.map((ev) => [ev.id, ev]));

  const activeTickets = tickets.filter((t) => t.status === "active").length;
  const usedTickets = tickets.filter((t) => t.status === "used").length;
  const totalEvents = events.length;
  const totalAlerts = alerts.length;

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
        <div className="sidebar-logo">Crowd Flow</div>
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

        {loading && <div className="panel"><p className="muted">Loading data from backend...</p></div>}

        {error && <div className="error-msg">{error}</div>}
        {success && <div className="success-msg">{success}</div>}

        {/* ── Overview ── */}
        {tab === "overview" && (
          <>
            <div className="stats-row">
              <Stat icon={<HiOutlineCalendar />} label="Events" value={totalEvents} color="#2563EB" />
              <Stat icon={<HiOutlineTicket />} label="Active Tickets" value={activeTickets} color="#22C55E" />
              <Stat icon={<HiOutlineShieldCheck />} label="Verified" value={usedTickets} color="#8B5CF6" />
              <Stat icon={<HiOutlineBell />} label="Alerts" value={totalAlerts} color="#EF4444" />
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
                    <td>{t.user ?? t.username ?? t.user_id ?? "-"}</td>
                    <td>{t.event ?? eventMap[t.event_id]?.name ?? t.event_id ?? "-"}</td>
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
                    <td>{l.user ?? l.user_id ?? "—"}</td>
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
