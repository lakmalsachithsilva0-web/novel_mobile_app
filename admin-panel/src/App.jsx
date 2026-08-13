import { useEffect, useState } from "react";
import {
  clearAdminToken,
  getAdminToken,
  loginAdmin,
  setAdminToken,
  API_BASE_URL,
} from "./api";

/**
 * Temporary shell — replace this file with App.jsx from novel_v2_code_updates.zip
 * (NovelHub full dashboard). styles.css is already the new dark theme on GitHub.
 */
export default function App() {
  const [token, setToken] = useState(() => getAdminToken());
  const [form, setForm] = useState({ username: "", password: "" });
  const [error, setError] = useState("");

  if (!token) {
    return (
      <div className="login-page">
        <form
          className="login-card"
          onSubmit={async (e) => {
            e.preventDefault();
            try {
              const res = await loginAdmin(form);
              setAdminToken(res.token);
              setToken(res.token);
            } catch (err) {
              setError(String(err.message || err));
            }
          }}
        >
          <h1>NovelHub Admin</h1>
          <p>
            Full UI is in the download zip as <code>App.jsx</code>. Copy it to{" "}
            <code>admin-panel/src/App.jsx</code>, then refresh.
          </p>
          {error && <div className="login-error">{error}</div>}
          <label>Username</label>
          <input
            value={form.username}
            onChange={(e) => setForm((f) => ({ ...f, username: e.target.value }))}
            required
          />
          <label>Password</label>
          <input
            type="password"
            value={form.password}
            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
            required
          />
          <button type="submit">Login</button>
          <p style={{ fontSize: ".75rem", color: "var(--text-muted)" }}>API: {API_BASE_URL}</p>
        </form>
      </div>
    );
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>Install full dashboard</h1>
        <p>
          You are signed in. Replace <code>src/App.jsx</code> with the NovelHub{" "}
          <code>App.jsx</code> from <code>novel_v2_code_updates.zip</code>, then
          hard-refresh this page.
        </p>
        <button
          type="button"
          onClick={() => {
            clearAdminToken();
            setToken("");
          }}
        >
          Sign out
        </button>
      </div>
    </div>
  );
}
