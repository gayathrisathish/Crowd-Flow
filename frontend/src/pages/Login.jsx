import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { login as apiLogin, getMe } from "../api";
import { useAuth } from "../AuthContext";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { loginUser } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { data } = await apiLogin(username, password);
      console.log("Login API response:", data);
      localStorage.setItem("token", data.access_token);
      console.log("Token stored in localStorage:", localStorage.getItem("token"));
      const me = await getMe();
      console.log("getMe response:", me.data);
      loginUser(data.access_token, me.data);
      console.log("loginUser called, user:", me.data);
      navigate(me.data.role === "admin" ? "/admin" : "/dashboard");
      console.log("Navigated to:", me.data.role === "admin" ? "/admin" : "/dashboard");
    } catch (err) {
      console.log("Login error:", err);
      if (err.response) {
        setError(err.response.data?.detail || "Login failed");
      } else if (err.request) {
        setError("Cannot reach the server. Is the backend running?");
      } else {
        setError("Login failed");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <form className="auth-card" onSubmit={handleSubmit}>
        <h1>Crowd-Flow</h1>
        <p className="subtitle">Sign in to your account</p>
        {error && <div className="error-msg">{error}</div>}
        <label>Username</label>
        <input value={username} onChange={(e) => setUsername(e.target.value)} required />
        <label>Password</label>
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <button type="submit" disabled={loading}>
          {loading ? "Signing in…" : "Sign In"}
        </button>
        <p className="auth-footer">
          Don&apos;t have an account? <Link to="/register">Register</Link>
        </p>
      </form>
    </div>
  );
}
