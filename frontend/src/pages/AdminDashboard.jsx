import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";
import {
  HiOutlineCalendar, HiOutlineTicket, HiOutlineBell,
  HiOutlineShieldCheck, HiOutlineClipboardDocumentList,
  HiOutlineArrowRightStartOnRectangle, HiOutlineMapPin,
} from "react-icons/hi2";

const INITIAL_EVENTS = [
  { id: 1, name: "Tech Summit 2026", location: "Chennai", date: "2026-04-20T10:00:00" },
  { id: 2, name: "Music Fest", location: "Mumbai", date: "2026-04-25T18:00:00" },
  { id: 3, name: "Startup Expo", location: "Bangalore", date: "2026-05-01T09:30:00" },
];

const INITIAL_TICKETS = [
  { id: 1, ticket_id: "TKT-001", user: "john_doe", event: "Tech Summit 2026", event_id: 1, status: "active" },
  { id: 2, ticket_id: "TKT-002", user: "jane_smith", event: "Music Fest", event_id: 2, status: "used" },
  { id: 3, ticket_id: "TKT-003", user: "alex_k", event: "Startup Expo", event_id: 3, status: "active" },
];

const INITIAL_ALERTS = [
  { id: 1, level: "alert", message: "High queue at Gate A", created_at: "2026-04-13T10:02:00", event_id: 1 },
  { id: 2, level: "safe", message: "Gate B flow normalized", created_at: "2026-04-13T10:07:00", event_id: 2 },
];

const INITIAL_AUDIT_LOGS = [
  { id: 1, timestamp: "2026-04-13T10:00:00", action: "USER_LOGIN", user: "admin", details: "Admin logged in" },
  { id: 2, timestamp: "2026-04-13T10:05:00", action: "EVENT_CREATE", user: "admin", details: "Created Tech Summit 2026" },
  { id: 3, timestamp: "2026-04-13T10:10:00", action: "TICKET_VERIFY", user: "admin", details: "Verified TKT-001" },
];

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
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  /* form states */
  const [evForm, setEvForm] = useState({ name: "", location: "", date: "" });
  const [alertForm, setAlertForm] = useState({ event_id: "", message: "", level: "alert" });
  const [verifyId, setVerifyId] = useState("");
  const [editEvent, setEditEvent] = useState(null);

  const addAuditLog = (action, details) => {
    setAuditLogs((prev) => {
      const nextId = prev.length > 0 ? Math.max(...prev.map((l) => Number(l.id) || 0)) + 1 : 1;
      return [
        {
          id: nextId,
          timestamp: new Date().toISOString(),
          action,
          user: "admin",
          details,
        },
        ...prev,
      ];
    });
  };

  /* actions */
  const handleCreateEvent = (e) => {
    e.preventDefault();
    setError("");
    const eventDate = new Date(evForm.date);
    if (Number.isNaN(eventDate.getTime())) {
      setError("Invalid event date");
      return;
    }

    const nextId = events.length > 0 ? Math.max(...events.map((ev) => Number(ev.id) || 0)) + 1 : 1;
    const newEvent = {
      id: nextId,
      name: evForm.name,
      location: evForm.location,
      date: eventDate.toISOString(),
    };

    setEvents((prev) => [...prev, newEvent]);
    setEvForm({ name: "", location: "", date: "" });
    addAuditLog("EVENT_CREATE", `Created ${newEvent.name}`);
  };

  const handleUpdateEvent = (e) => {
    e.preventDefault();
    setError("");
    const updatedDate = new Date(editEvent.date);
    if (Number.isNaN(updatedDate.getTime())) {
      setError("Invalid event date");
      return;
    }

    setEvents((prev) => prev.map((ev) => (
      ev.id === editEvent.id
        ? { ...ev, name: editEvent.name, location: editEvent.location, date: updatedDate.toISOString() }
        : ev
    )));
    setEditEvent(null);
  };

  const handleDeleteEvent = (id) => {
    if (!confirm("Delete this event?")) return;
    setEvents((prev) => prev.filter((ev) => ev.id !== id));
  };

  const handleCreateAlert = (e) => {
    e.preventDefault();
    setError("");
    const eventId = Number(alertForm.event_id);
    if (!eventId) {
      setError("Please select an event");
      return;
    }

    const nextId = alerts.length > 0 ? Math.max(...alerts.map((a) => Number(a.id) || 0)) + 1 : 1;
    const newAlert = {
      id: nextId,
      event_id: eventId,
      message: alertForm.message,
      level: alertForm.level,
      created_at: new Date().toISOString(),
    };

    setAlerts((prev) => [newAlert, ...prev]);
    setAlertForm({ event_id: "", message: "", level: "alert" });
    addAuditLog("ALERT_CREATE", `Created ${newAlert.level} alert for event ${eventId}`);
  };

  const handleVerify = (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    const normalized = verifyId.trim();
    let found = false;
    setTickets((prev) => prev.map((t) => {
      if (t.ticket_id === normalized) {
        found = true;
        return { ...t, status: "used" };
      }
      return t;
    }));

    if (!found) {
      setError("Ticket not found");
      return;
    }

    setSuccess(`Ticket ${normalized} verified successfully!`);
    setVerifyId("");
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
