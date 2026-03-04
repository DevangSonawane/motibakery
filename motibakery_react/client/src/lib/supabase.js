const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabaseEnabled = Boolean(supabaseUrl && supabaseAnonKey);

if (!supabaseEnabled) {
  console.warn('Supabase config missing. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
}

function ensureSupabaseConfigured() {
  if (!supabaseEnabled) {
    throw new Error('Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
  }
}

function buildHeaders({ accessToken, admin = false, preferReturnRepresentation = false } = {}) {
  ensureSupabaseConfigured();

  if (admin) {
    throw new Error('Admin mode is not supported in frontend. Use a backend or Supabase Edge Function.');
  }

  const apiKey = supabaseAnonKey;
  if (!apiKey) {
    throw new Error('Supabase API key is missing.');
  }

  const headers = {
    apikey: apiKey,
    Authorization: `Bearer ${accessToken || apiKey}`,
    'Content-Type': 'application/json',
  };

  if (preferReturnRepresentation) {
    headers.Prefer = 'return=representation';
  }

  return headers;
}

async function parseSupabaseResponse(response) {
  const contentType = response.headers.get('content-type') || '';
  const body = contentType.includes('application/json') ? await response.json() : await response.text();

  if (response.ok) {
    return body;
  }

  const isInvalidCredentials =
    typeof body === 'object' &&
    body &&
    (body.error_code === 'invalid_credentials' || body.error === 'invalid_credentials');

  if (isInvalidCredentials) {
    throw new Error('Invalid email or password. Check your Supabase Auth user credentials.');
  }

  const message =
    (typeof body === 'object' && body && (body.msg || body.error_description || body.message || body.error)) ||
    (typeof body === 'string' && body) ||
    'Supabase request failed.';

  throw new Error(message);
}

export async function supabaseAuthRequest(path, { method = 'GET', body, accessToken, admin = false } = {}) {
  ensureSupabaseConfigured();
  const response = await fetch(`${supabaseUrl}/auth/v1${path}`, {
    method,
    headers: buildHeaders({ accessToken, admin }),
    body: body ? JSON.stringify(body) : undefined,
  });

  return parseSupabaseResponse(response);
}

export async function supabaseRestRequest(path, { method = 'GET', body, accessToken, admin = false, preferReturnRepresentation = false } = {}) {
  ensureSupabaseConfigured();
  const response = await fetch(`${supabaseUrl}/rest/v1${path}`, {
    method,
    headers: buildHeaders({ accessToken, admin, preferReturnRepresentation }),
    body: body ? JSON.stringify(body) : undefined,
  });

  return parseSupabaseResponse(response);
}
