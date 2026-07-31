import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.50.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, DELETE, OPTIONS',
};

type DeleteUserPayload = {
  uid?: string;
  id?: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'DELETE' && req.method !== 'POST') {
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
    return new Response(JSON.stringify({ error: 'Only admins can delete users.' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let body: DeleteUserPayload;
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

  if (uid === callerUserData.user.id) {
    return new Response(JSON.stringify({ error: 'You cannot delete your own admin account from here.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { data: existingUser, error: existingUserError } = await adminClient
    .from('users')
    .select('uid,full_name,gmail,role')
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

  const { error: deleteAuthError } = await adminClient.auth.admin.deleteUser(uid);
  if (deleteAuthError) {
    return new Response(JSON.stringify({ error: deleteAuthError.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ ok: true, user: existingUser }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
