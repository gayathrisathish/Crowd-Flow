import axios from "axios";

const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000";

const api = axios.create({ baseURL: API_BASE, timeout: 10000 });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

// ── Auth ──
export const login = (username, password) =>
  api.post("/auth/login", { username, password });

export const register = (username, password, event_id) =>
  api.post("/auth/register", { username, password, event_id });

export const getMe = () => api.get("/auth/me");

// ── Events ──
export const getEvents = () => api.get("/events/");
export const getEvent = (id) => api.get(`/events/${id}`);
export const createEvent = (data) => api.post("/events/", data);
export const updateEvent = (id, data) => api.put(`/events/${id}`, data);
export const deleteEvent = (id) => api.delete(`/events/${id}`);

// ── Tickets ──
export const getMyTickets = () => api.get("/tickets/me");
export const getAllTickets = () => api.get("/tickets/");
export const getTicket = (ticketId) => api.get(`/tickets/${ticketId}`);

// ── Alerts ──
export const getAlerts = (eventId) =>
  api.get("/alerts/", { params: eventId ? { event_id: eventId } : {} });
export const createAlert = (data) => api.post("/alerts/", data);

// ── Verification ──
export const verifyTicket = (ticket_id) =>
  api.post("/verify/", { ticket_id });

// ── Audit ──
export const getAuditLogs = () => api.get("/audit/");

export default api;
