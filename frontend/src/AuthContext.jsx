import { createContext, useContext, useState, useEffect } from "react";
import { getMe, login as apiLogin } from "./api";

const AuthContext = createContext(null);

const AUTH_BYPASS = import.meta.env.VITE_AUTH_BYPASS === "true";
const BYPASS_ROLE = import.meta.env.VITE_BYPASS_ROLE || "admin";
const BYPASS_USERNAME = import.meta.env.VITE_BYPASS_USERNAME || "";
const BYPASS_PASSWORD = import.meta.env.VITE_BYPASS_PASSWORD || "";
const BYPASS_TOKEN = import.meta.env.VITE_BYPASS_TOKEN || "";

function getFallbackBypassUser() {
  return {
    id: 0,
    username: BYPASS_USERNAME || `dev-${BYPASS_ROLE}`,
    role: BYPASS_ROLE,
    registered_at: new Date().toISOString(),
  };
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const bootstrapBypassAuth = async () => {
    try {
      if (BYPASS_TOKEN) {
        localStorage.setItem("token", BYPASS_TOKEN);
        const me = await getMe();
        setUser(me.data);
        return;
      }

      if (BYPASS_USERNAME && BYPASS_PASSWORD) {
        const { data } = await apiLogin(BYPASS_USERNAME, BYPASS_PASSWORD);
        localStorage.setItem("token", data.access_token);
        const me = await getMe();
        setUser(me.data);
        return;
      }
    } catch {
      // Fall back to local bypass identity if backend auth is unavailable.
    }

    setUser(getFallbackBypassUser());
  };

  useEffect(() => {
    if (AUTH_BYPASS) {
      bootstrapBypassAuth().finally(() => setLoading(false));
      return;
    }

    const token = localStorage.getItem("token");
    if (!token) {
      setUser(null);
      setLoading(false);
      return;
    }
    getMe()
      .then((res) => {
        setUser(res.data);
        setLoading(false);
      })
      .catch(() => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        setUser(null);
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    if (AUTH_BYPASS) return;
    const handleForceLogout = () => setUser(null);
    window.addEventListener("auth:logout", handleForceLogout);
    return () => window.removeEventListener("auth:logout", handleForceLogout);
  }, []);

  const loginUser = (token, userData) => {
    localStorage.setItem("token", token);
    localStorage.setItem("user", JSON.stringify(userData));
    setUser(userData);
  };

  const logout = () => {
    if (AUTH_BYPASS) {
      setUser(getFallbackBypassUser());
      return;
    }

    localStorage.removeItem("token");
    localStorage.removeItem("user");
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, loginUser, logout, authBypass: AUTH_BYPASS }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
