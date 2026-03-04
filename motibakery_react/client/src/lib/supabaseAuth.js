import { supabaseAuthRequest, supabaseRestRequest } from '@/lib/supabase';

function normalizeRole(value) {
  const allowedRoles = new Set(['admin', 'counter', 'cake_room']);
  return allowedRoles.has(value) ? value : 'counter';
}

async function getProfileByEmail(email, accessToken) {
  const params = new URLSearchParams({
    select: 'uid,full_name,gmail,role',
    limit: '1',
  });
  params.set('gmail', `eq.${email}`);

  const rows = await supabaseRestRequest(`/users?${params.toString()}`, {
    accessToken,
  });

  return Array.isArray(rows) ? rows[0] || null : null;
}

export async function loginWithSupabaseEmailPassword(email, password) {
  const session = await supabaseAuthRequest('/token?grant_type=password', {
    method: 'POST',
    body: { email, password },
  });

  const accessToken = session?.access_token;
  const user = session?.user;

  if (!accessToken || !user?.id) {
    throw new Error('Invalid Supabase auth response.');
  }

  const fallbackAdminEmail = import.meta.env.VITE_ADMIN_EMAIL;
  const fallbackRole = fallbackAdminEmail && user.email === fallbackAdminEmail ? 'admin' : 'counter';
  const profile = await getProfileByEmail(user.email, accessToken);
  if (!profile) {
    await supabaseAuthRequest('/logout', { method: 'POST', accessToken }).catch(() => {});
    throw new Error('No user profile found. Ask admin to create your access.');
  }

  const safeRole = normalizeRole(profile?.role || fallbackRole);

  return {
    token: accessToken,
    user: {
      id: user.id,
      name: profile?.full_name || user.user_metadata?.full_name || user.email || 'User',
      email: user.email,
      role: safeRole,
      status: 'active',
    },
  };
}

export async function logoutFromSupabase(token) {
  if (!token) return;
  await supabaseAuthRequest('/logout', {
    method: 'POST',
    accessToken: token,
  }).catch(() => {});
}
