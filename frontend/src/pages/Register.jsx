import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { register as apiRegister, getEvents, login as apiLogin, getMe } from "../api";
import { useAuth } from "../AuthContext";

export default function Register() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [eventId, setEventId] = useState("");
  const [events, setEvents] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const { loginUser } = useAuth();

  useEffect(() => {
    getEvents()
      .then((res) => {
        setEvents(res.data);
        if (res.data.length > 0) setEventId(res.data[0].id);
      })
      .catch(() => {});
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await apiRegister(username, password, Number(eventId));
      const { data } = await apiLogin(username, password);
      localStorage.setItem("token", data.access_token);
      const me = await getMe();
      loginUser(data.access_token, me.data);
    } catch (err) {
      setError(err.response?.data?.detail || "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <form className="auth-card" onSubmit={handleSubmit}>
        <h1>Crowd-Flow</h1>
        <p className="subtitle">Create an attendee account</p>
        {error && <div className="error-msg">{error}</div>}
        <label>Username</label>
        <input value={username} onChange={(e) => setUsername(e.target.value)} required />
        <label>Password</label>
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <label>Select Event</label>
        <select value={eventId} onChange={(e) => setEventId(e.target.value)} required>
          {events.length === 0 && <option value="">No events available</option>}
          {events.map((ev) => (
            <option key={ev.id} value={ev.id}>
              {ev.name} — {new Date(ev.date).toLocaleDateString()}
            </option>
          ))}
        </select>
        <button type="submit" disabled={loading || events.length === 0}>
          {loading ? "Creating…" : "Register"}
        </button>
        <p className="auth-footer">
          Already have an account? <Link to="/login">Sign in</Link>
        </p>
      </form>
    </div>
  );
}
