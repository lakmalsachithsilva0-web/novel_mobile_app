import { useCallback, useEffect, useState } from "react";
import {
  API_BASE_URL,
  listAdminUsers,
  banUser,
  unbanUser,
  suspendUser,
  unsuspendUser,
  activateUser,
  deleteAdminUser,
  restoreUser,
  setAuthorActive,
} from "./api";

function asArray(v) {
  return Array.isArray(v) ? v : [];
}

function statusBadge(status) {
  const s = (status || "").toLowerCase();
  if (s.includes("publish") || s === "active" || s === "approved") return "badge-green";
  if (s.includes("pending") || s.includes("review") || s.includes("draft") || s.includes("schedul"))
    return "badge-orange";
  if (s.includes("reject") || s.includes("suspend") || s.includes("inactive") || s.includes("ban"))
    return "badge-red";
  return "badge-blue";
}

function coverUrl(path) {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  const base = API_BASE_URL.replace(/\/$/, "");
  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}

// PLACEHOLDER_WILL_REPLACE
