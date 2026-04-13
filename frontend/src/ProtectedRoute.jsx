import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";

export default function ProtectedRoute({ children, role }) {
  const { user, loading, authBypass } = useAuth();

  if (loading)
    return <div className="loading-screen">Loading…</div>;

  if (authBypass) return children;

  if (!user) return <Navigate to="/login" replace />;

  if (role && user.role !== role)
    return <Navigate to={user.role === "admin" ? "/admin" : "/dashboard"} replace />;

  return children;
}
