import { useState, useEffect } from "react";
import { QRCodeSVG } from "qrcode.react";
import { useAuth } from "../AuthContext";
import { getMyTickets, getEvents, getAlerts } from "../api";
import {
  HiOutlineTicket, HiOutlineCalendar, HiOutlineBell,
  HiOutlineArrowRightStartOnRectangle, HiOutlineQrCode,
} from "react-icons/hi2";

export default function AttendeeDashboard() {
  const { user, logout } = useAuth();
  const [tab, setTab] = useState("ticket");
  const [tickets, setTickets] = useState([]);
  const [events, setEvents] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [selectedTicket, setSelectedTicket] = useState(null);

  useEffect(() => {
    Promise.all([getMyTickets(), getEvents(), getAlerts()])
      .then(([tk, ev, al]) => {
        setTickets(tk.data);
        setEvents(ev.data);
        setAlerts(al.data);
        if (tk.data.length > 0) setSelectedTicket(tk.data[0]);
      })
      .catch(() => {});
  }, []);

  const eventMap = Object.fromEntries(events.map((e) => [e.id, e]));

  const TABS = [
    { key: "ticket", label: "My Ticket", icon: <HiOutlineQrCode /> },
    { key: "events", label: "Events", icon: <HiOutlineCalendar /> },
    { key: "alerts", label: "Alerts", icon: <HiOutlineBell /> },
  ];

  return (
    <div className="dashboard">
      <aside className="sidebar">
        <div className="sidebar-logo">CF</div>
        <nav>
          {TABS.map((t) => (
            <button key={t.key} className={tab === t.key ? "active" : ""} onClick={() => setTab(t.key)}>
              {t.icon} {t.label}
            </button>
          ))}
        </nav>
        <button className="logout-btn" onClick={logout}>
          <HiOutlineArrowRightStartOnRectangle /> Logout
        </button>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <h2>{TABS.find((t) => t.key === tab)?.label}</h2>
          <span className="user-badge">{user?.username}</span>
        </header>

        {/* ── My Ticket (QR) ── */}
        {tab === "ticket" && (
          <div className="panel ticket-panel">
            {tickets.length === 0 ? (
              <p className="muted">No tickets assigned yet.</p>
            ) : (
              <>
                {tickets.length > 1 && (
                  <div className="ticket-selector">
                    {tickets.map((t) => (
                      <button
                        key={t.id}
                        className={selectedTicket?.id === t.id ? "active" : ""}
                        onClick={() => setSelectedTicket(t)}
                      >
                        <HiOutlineTicket /> {eventMap[t.event_id]?.name || `Event #${t.event_id}`}
                      </button>
                    ))}
                  </div>
                )}
                {selectedTicket && (
                  <div className="qr-container">
                    <QRCodeSVG
                      value={selectedTicket.ticket_id}
                      size={220}
                      bgColor="#1E293B"
                      fgColor="#E2E8F0"
                      level="H"
                    />
                    <div className="ticket-info">
                      <p><strong>Ticket ID</strong></p>
                      <p className="mono">{selectedTicket.ticket_id}</p>
                      <p><strong>Event</strong></p>
                      <p>{eventMap[selectedTicket.event_id]?.name || "—"}</p>
                      <p><strong>Status</strong></p>
                      <p><span className={`badge ${selectedTicket.status}`}>{selectedTicket.status}</span></p>
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {/* ── Events ── */}
        {tab === "events" && (
          <div className="panel">
            <div className="event-cards">
              {events.map((ev) => (
                <div key={ev.id} className="event-card">
                  <h4>{ev.name}</h4>
                  <p><HiOutlineCalendar /> {new Date(ev.date).toLocaleString()}</p>
                  <p style={{ color: "#94A3B8" }}>{ev.location}</p>
                </div>
              ))}
              {events.length === 0 && <p className="muted">No events available.</p>}
            </div>
          </div>
        )}

        {/* ── Alerts ── */}
        {tab === "alerts" && (
          <div className="panel">
            {alerts.map((a) => (
              <div key={a.id} className={`alert-row ${a.level}`}>
                <span className="alert-badge">{a.level.toUpperCase()}</span>
                <span>{a.message}</span>
                <span className="muted">{new Date(a.created_at).toLocaleString()}</span>
              </div>
            ))}
            {alerts.length === 0 && <p className="muted">No alerts.</p>}
          </div>
        )}
      </main>
    </div>
  );
}
