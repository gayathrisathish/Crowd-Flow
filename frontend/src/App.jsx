import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";
import ProtectedRoute from "./ProtectedRoute";
import Register from "./pages/Register";
import AdminDashboard from "./pages/AdminDashboard";
import AttendeeDashboard from "./pages/AttendeeDashboard";
import CrowdMonitor from "./pages/CrowdMonitor";

function App() {
  const { user, loading } = useAuth();

  if (loading) return <div className="loading-screen">Loading…</div>;

  const homePath = !user ? "/register" : user.role === "attendee" ? "/dashboard" : "/admin";

  return (
    <Routes>
      <Route path="/" element={<Navigate to={homePath} replace />} />
      <Route path="/login" element={<Navigate to="/register" replace />} />
      <Route path="/register" element={user ? <Navigate to={homePath} replace /> : <Register />} />
      <Route path="/admin" element={<ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>} />
      <Route path="/admin/monitor/:eventId" element={<ProtectedRoute role="admin"><CrowdMonitor /></ProtectedRoute>} />
      <Route path="/dashboard" element={<ProtectedRoute role="attendee"><AttendeeDashboard /></ProtectedRoute>} />
      <Route path="*" element={<Navigate to={homePath} replace />} />
    </Routes>
  );
}

export default App;
