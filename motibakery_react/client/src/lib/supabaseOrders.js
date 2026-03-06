import { supabaseRestRequest } from '@/lib/supabase';
import { getValidStoredSupabaseToken } from '@/lib/authToken';
import { useAuthStore } from '@/stores/authStore';

function requireToken() {
  const token = getValidStoredSupabaseToken();
  if (!token) {
    throw new Error('Session expired. Please sign in again.');
  }
  return token;
}

function normalizeOrderRow(row) {
  return {
    ...row,
    id: row.id || row.uid || row.order_id,
    orderId: row.order_id || row.orderId || row.id,
    status: row.status || 'new',
    createdAt: row.created_at || row.createdAt || null,
  };
}

function toMillis(value) {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
}

export async function listOrdersFromSupabase() {
  const token = requireToken();
  const params = new URLSearchParams({
    select: '*',
    order: 'created_at.desc',
  });

  try {
    const rows = await supabaseRestRequest(`/orders?${params.toString()}`, { accessToken: token });
    if (!Array.isArray(rows)) return [];
    return rows
      .map(normalizeOrderRow)
      .sort((a, b) => toMillis(b.createdAt || b.created_at) - toMillis(a.createdAt || a.created_at));
  } catch (error) {
    const message = String(error?.message || '').toLowerCase();
    if (message.includes('jwt') || message.includes('invalid')) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired or invalid. Please sign in again.');
    }

    // If orders table is not yet created in Supabase, keep dashboard usable.
    if (
      (message.includes('relation') && message.includes('orders')) ||
      (message.includes("table 'public.orders'") && message.includes('schema cache')) ||
      (message.includes('could not find the table') && message.includes('orders'))
    ) {
      return [];
    }

    throw error;
  }
}

export async function deleteOrderInSupabase({ id, orderId } = {}) {
  const token = requireToken();
  if (!id && !orderId) {
    throw new Error('Order id is required for delete.');
  }

  const filter = id ? `uid=eq.${id}` : `order_id=eq.${orderId}`;

  try {
    await supabaseRestRequest(`/orders?${filter}`, {
      method: 'DELETE',
      accessToken: token,
    });
    return { success: true };
  } catch (error) {
    const message = String(error?.message || '').toLowerCase();
    if (message.includes('jwt') || message.includes('invalid')) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired or invalid. Please sign in again.');
    }
    throw error;
  }
}
