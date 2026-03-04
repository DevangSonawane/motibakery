import { supabaseRestRequest } from '@/lib/supabase';
import { useAuthStore } from '@/stores/authStore';
import { getValidStoredSupabaseToken } from '@/lib/authToken';

function nowIso() {
  return new Date().toISOString();
}

export async function listUsersFromSupabase() {
  const token = getValidStoredSupabaseToken();
  if (!token) {
    throw new Error('Session expired. Please sign in again.');
  }
  const params = new URLSearchParams({
    select: 'uid,full_name,gmail,role',
    order: 'full_name.asc',
  });

  try {
    const users = await supabaseRestRequest(`/users?${params.toString()}`, { accessToken: token });
    return Array.isArray(users) ? users : [];
  } catch (error) {
    const message = error?.message || '';
    if (message.toLowerCase().includes('invalid jwt')) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired or invalid. Please sign in again.');
    }
    throw error;
  }
}

export async function createUserInSupabase(payload) {
  const token = getValidStoredSupabaseToken();
  if (!token) {
    throw new Error('Please sign in again to create users.');
  }

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Supabase env missing. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
  }

  const response = await fetch(`${supabaseUrl}/functions/v1/admin-create-user`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      apikey: supabaseAnonKey,
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      full_name: payload.name,
      gmail: payload.email,
      password: payload.password,
      role: payload.role,
    }),
  });

  const body = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 401) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired or invalid. Please sign in again.');
    }

    const message =
      body?.error || body?.message || body?.msg || 'Failed to create user from Supabase Edge Function.';
    throw new Error(message);
  }

  const created = body?.user || body;
  return {
    id: created?.uid || nowIso(),
    ...created,
  };
}
