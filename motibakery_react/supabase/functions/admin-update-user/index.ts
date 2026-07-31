import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.50.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'PATCH, OPTIONS',
};

type UpdateUserPayload = {
  uid?: string;
  id?: string;
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

  if (req.method !== 'PATCH') {
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
    return new Response(JSON.stringify({ error: 'Only admins can update users.' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let body: UpdateUserPayload;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON payload.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const uid = (body.uid || body.id || '').trim();
  if (!uid) {
    return new Response(JSON.stringify({ error: 'User id is required.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { data: existingUser, error: existingUserError } = await adminClient
    .from('users')
    .select('uid,full_name,gmail,password,role')
    .eq('uid', uid)
    .maybeSingle();

  if (existingUserError) {
    return new Response(JSON.stringify({ error: existingUserError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!existingUser) {
    return new Response(JSON.stringify({ error: 'User not found.' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const fullName = (body.full_name || body.fullName || existingUser.full_name || '').trim();
  const gmail = (body.gmail || body.email || existingUser.gmail || '').trim().toLowerCase();
  const password = body.password || '';
  const role = body.role || existingUser.role || 'counter';

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

  if (password && password.length < 8) {
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

  const { data: gmailConflict, error: gmailConflictError } = await adminClient
    .from('users')
    .select('uid')
    .eq('gmail', gmail)
    .neq('uid', uid)
    .maybeSingle();

  if (gmailConflictError) {
    return new Response(JSON.stringify({ error: gmailConflictError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (gmailConflict) {
    return new Response(JSON.stringify({ error: 'That Gmail address is already in use.' }), {
      status: 409,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const authUpdatePayload: Record<string, unknown> = {
    email: gmail,
    user_metadata: {
      full_name: fullName,
      role,
    },
  };

  if (password) {
    authUpdatePayload.password = password;
  }

  const { data: updatedAuth, error: updateAuthError } = await adminClient.auth.admin.updateUserById(uid, authUpdatePayload);
  if (updateAuthError || !updatedAuth.user) {
    return new Response(JSON.stringify({ error: updateAuthError?.message || 'Failed to update auth user.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const updateRow: Record<string, unknown> = {
    full_name: fullName,
    gmail,
    role,
  };

  if (password) {
    updateRow.password = password;
  }

  const { data: updatedUser, error: updateUserError } = await adminClient
    .from('users')
    .update(updateRow)
    .eq('uid', uid)
    .select('uid,full_name,gmail,role')
    .single();

  if (updateUserError) {
    const rollbackPayload: Record<string, unknown> = {
      email: existingUser.gmail,
      user_metadata: {
        full_name: existingUser.full_name,
        role: existingUser.role,
      },
    };

    if (existingUser.password) {
      rollbackPayload.password = existingUser.password;
    }

    await adminClient.auth.admin.updateUserById(uid, rollbackPayload).catch(() => {});

    return new Response(JSON.stringify({ error: updateUserError.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ user: updatedUser }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
