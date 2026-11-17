import { createClient } from 'jsr:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const url = Deno.env.get('SUPABASE_URL')!;
  const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
  const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // 1) Identifica o chamador pelo JWT dele.
  const caller = createClient(url, anon, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data: { user } } = await caller.auth.getUser();
  if (!user) return json({ error: 'unauthorized' }, 401);

  const admin = createClient(url, service, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const body = await req.json().catch(() => null);
  if (!body?.action || !body?.id_org) return json({ error: 'bad_request' }, 400);
  const { action, id_org } = body as { action: string; id_org: string };

  // 2) Confere se o chamador é owner/admin ativo da organização.
  const { data: callerM } = await admin
    .from('membros_organizacao')
    .select('funcao')
    .eq('id_org', id_org)
    .eq('id_usuario', user.id)
    .eq('ativo', true)
    .in('funcao', ['owner', 'admin'])
    .maybeSingle();
  if (!callerM) return json({ error: 'forbidden' }, 403);
  const callerIsOwner = callerM.funcao === 'owner';

  switch (action) {
    case 'create': {
      const { email, password, funcao_org, nome } = body;
      if (funcao_org && !callerIsOwner) {
        return json({ error: 'only_owner_can_grant_org_role' }, 403);
      }
      const { data, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { nome },
      });
      if (error) return json({ error: error.message }, 400);

      if (funcao_org) {
        const { error: mErr } = await admin.from('membros_organizacao').insert({
          id_org,
          id_usuario: data.user.id,
          funcao: funcao_org,
          ativo: true,
          email,
        });
        if (mErr) return json({ error: mErr.message }, 400);
      }
      return json({ id: data.user.id });
    }

    case 'reset_password': {
      const { target_user_id, password } = body;
      const { error } = await admin.auth.admin.updateUserById(target_user_id, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    case 'set_active': {
      const { target_user_id, ativo } = body;
      const { error } = await admin.auth.admin.updateUserById(target_user_id, {
        ban_duration: ativo ? 'none' : '876000h',
      });
      if (error) return json({ error: error.message }, 400);
      await admin.from('membros_organizacao').update({ ativo })
        .eq('id_org', id_org).eq('id_usuario', target_user_id);
      await admin.from('membro_unidade').update({ ativo }).eq('id_usuario', target_user_id);
      return json({ ok: true });
    }

    default:
      return json({ error: 'unknown_action' }, 400);
  }
});
