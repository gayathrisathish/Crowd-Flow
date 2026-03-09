import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";
import ProtectedRoute from "./ProtectedRoute";
import Login from "./pages/Login";
import Register from "./pages/Register";
import AdminDashboard from "./pages/AdminDashboard";
import AttendeeDashboard from "./pages/AttendeeDashboard";

function App() {
  const { user, loading } = useAuth();

  if (loading) return <div className="loading-screen">Loading…</div>;

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to={user.role === "admin" ? "/admin" : "/dashboard"} /> : <Login />} />
      <Route path="/register" element={user ? <Navigate to="/dashboard" /> : <Register />} />
      <Route path="/admin" element={<ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>} />
      <Route path="/dashboard" element={<ProtectedRoute role="attendee"><AttendeeDashboard /></ProtectedRoute>} />
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;
