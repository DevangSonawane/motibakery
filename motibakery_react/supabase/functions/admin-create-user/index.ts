import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.50.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type CreateUserPayload = {
  full_name?: string;
  fullName?: string;
  gmail?: string;
  email?: string;
  password?: string;
  role?: 'counter' | 'cake_room' | 'admin';
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const adminKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_SECRET_KEY');
  const clientKey = Deno.env.get('SUPABASE_ANON_KEY') || Deno.env.get('SUPABASE_PUBLISHABLE_KEY');
  const authHeader = req.headers.get('Authorization');

  if (!supabaseUrl || !adminKey || !clientKey) {
    return new Response(JSON.stringify({ error: 'Missing required function environment variables.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing bearer token.' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const callerClient = createClient(supabaseUrl, clientKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: callerUserData, error: callerUserError } = await callerClient.auth.getUser();
  if (callerUserError || !callerUserData.user) {
    return new Response(JSON.stringify({ error: 'Invalid auth token.' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const adminClient = createClient(supabaseUrl, adminKey);

  const { data: callerProfile, error: callerProfileError } = await adminClient
    .from('users')
    .select('role')
    .eq('uid', callerUserData.user.id)
    .maybeSingle();

  if (callerProfileError) {
    return new Response(JSON.stringify({ error: callerProfileError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!callerProfile || callerProfile.role !== 'admin') {
    return new Response(JSON.stringify({ error: 'Only admins can create users.' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let body: CreateUserPayload;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON payload.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const fullName = (body.full_name || body.fullName || '').trim();
  const gmail = (body.gmail || body.email || '').trim().toLowerCase();
  const password = body.password || '';
  const role = body.role || 'counter';

  if (!fullName || fullName.length < 2) {
    return new Response(JSON.stringify({ error: 'Name must be at least 2 characters.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!gmail || !gmail.endsWith('@gmail.com')) {
    return new Response(JSON.stringify({ error: 'Valid @gmail.com address is required.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!password || password.length < 8) {
    return new Response(JSON.stringify({ error: 'Password must be at least 8 characters.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!['admin', 'counter', 'cake_room'].includes(role)) {
    return new Response(JSON.stringify({ error: 'Invalid role.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { data: createdAuth, error: createAuthError } = await adminClient.auth.admin.createUser({
    email: gmail,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      role,
    },
  });

  if (createAuthError || !createdAuth.user) {
    return new Response(JSON.stringify({ error: createAuthError?.message || 'Failed to create auth user.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const row = {
    uid: createdAuth.user.id,
    full_name: fullName,
    gmail,
    password,
    role,
  };

  const { data: inserted, error: insertError } = await adminClient
    .from('users')
    .insert(row)
    .select('uid,full_name,gmail,role')
    .single();

  if (insertError) {
    await adminClient.auth.admin.deleteUser(createdAuth.user.id).catch(() => {});
    return new Response(JSON.stringify({ error: insertError.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ user: inserted }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
