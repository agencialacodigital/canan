// Edge Function "contato": valida o formulário, salva em public.leads e avisa o time de vendas via Resend.
// Secrets: RESEND_API_KEY, SALES_EMAIL (obrigatórios) e RESEND_FROM (opcional).
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY já são injetados pelo Supabase.
import { createClient } from 'npm:@supabase/supabase-js@2';

const ALLOWED_ORIGINS = [
  'https://cananhomedecor.com.br',
  'https://www.cananhomedecor.com.br',
];

const cors = (origin: string | null) => ({
  'Access-Control-Allow-Origin': origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0],
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type',
  'Vary': 'Origin',
});

const json = (body: unknown, status: number, origin: string | null) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors(origin), 'Content-Type': 'application/json' } });

const esc = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const str = (v: unknown, max: number) => (typeof v === 'string' ? v.trim().slice(0, max) : '');

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors(origin) });
  if (req.method !== 'POST') return json({ ok: false, error: 'method_not_allowed' }, 405, origin);

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ ok: false, error: 'invalid_json' }, 400, origin); }

  // Honeypot: bots preenchem; respondemos "ok" sem salvar nem enviar.
  if (str(body.website, 200)) return json({ ok: true }, 200, origin);

  const nome = str(body.nome, 100);
  const telefone = str(body.telefone, 30);
  const email = str(body.email, 254);
  const produto = str(body.produto, 60);
  const mensagem = str(body.mensagem, 2000);

  const digits = telefone.replace(/\D/g, '');
  if (nome.length < 2) return json({ ok: false, error: 'nome_invalido' }, 400, origin);
  if (digits.length < 8 || digits.length > 15) return json({ ok: false, error: 'telefone_invalido' }, 400, origin);
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return json({ ok: false, error: 'email_invalido' }, 400, origin);
  if (!mensagem) return json({ ok: false, error: 'mensagem_obrigatoria' }, 400, origin);

  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: lead, error: insertError } = await supabase
    .from('leads')
    .insert({ nome, telefone, email: email || null, produto: produto || null, mensagem })
    .select('id')
    .single();
  if (insertError || !lead) {
    console.error('insert lead failed', insertError);
    return json({ ok: false, error: 'save_failed' }, 500, origin);
  }

  // O lead já está salvo; falha no e-mail não perde o contato, só fica registrada.
  let emailOk = false;
  let emailErr: string | null = null;
  try {
    const apiKey = Deno.env.get('RESEND_API_KEY');
    const to = Deno.env.get('SALES_EMAIL');
    if (!apiKey || !to) throw new Error('RESEND_API_KEY ou SALES_EMAIL não configurado');
    const from = Deno.env.get('RESEND_FROM') ?? 'Canan Home Decor <onboarding@resend.dev>';
    const html = `
      <h2>Novo contato pelo site</h2>
      <p><strong>Nome:</strong> ${esc(nome)}</p>
      <p><strong>Telefone:</strong> ${esc(telefone)}</p>
      <p><strong>E-mail:</strong> ${email ? esc(email) : 'não informado'}</p>
      <p><strong>Produto de interesse:</strong> ${esc(produto || 'não informado')}</p>
      <p><strong>Mensagem:</strong><br>${esc(mensagem).replace(/\n/g, '<br>')}</p>`;
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from,
        to: [to],
        ...(email ? { reply_to: email } : {}),
        subject: `Novo contato pelo site — ${produto || 'Canan'} — ${nome}`,
        html,
      }),
    });
    if (!res.ok) throw new Error(`resend ${res.status}: ${(await res.text()).slice(0, 300)}`);
    emailOk = true;
  } catch (e) {
    emailErr = e instanceof Error ? e.message : String(e);
    console.error('email failed', emailErr);
  }

  await supabase.from('leads').update({ email_enviado: emailOk, email_erro: emailErr }).eq('id', lead.id);
  return json({ ok: true }, 200, origin);
});
