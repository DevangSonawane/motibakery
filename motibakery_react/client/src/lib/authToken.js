import { useAuthStore } from '@/stores/authStore';

function decodeBase64Url(value) {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized + '='.repeat((4 - (normalized.length % 4 || 4)) % 4);
  return atob(padded);
}

function parseJwtPayload(token) {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;

  try {
    const payload = decodeBase64Url(parts[1]);
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

export function isSupabaseTokenValid(token) {
  const payload = parseJwtPayload(token);
  if (!payload) return false;

  const nowSeconds = Math.floor(Date.now() / 1000);
  if (!payload.exp || payload.exp <= nowSeconds) return false;

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  if (!supabaseUrl) return false;

  const expectedIssuer = `${supabaseUrl}/auth/v1`;
  if (payload.iss !== expectedIssuer) return false;

  return true;
}

export function getValidStoredSupabaseToken() {
  const { token, clearAuth } = useAuthStore.getState();
  if (!token) return null;

  if (!isSupabaseTokenValid(token)) {
    clearAuth();
    return null;
  }

  return token;
}
