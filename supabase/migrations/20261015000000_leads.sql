-- Leads do formulário de contato do site Canan Home Decor.
-- Acesso somente pela Edge Function "contato" (service role). Sem policies = anon/authenticated bloqueados.
create table if not exists public.leads (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  nome          text not null check (char_length(nome) between 2 and 100),
  telefone      text not null check (char_length(telefone) between 8 and 30),
  email         text check (email is null or char_length(email) <= 254),
  produto       text check (produto is null or char_length(produto) <= 60),
  mensagem      text check (mensagem is null or char_length(mensagem) <= 2000),
  origem        text not null default 'site',
  email_enviado boolean not null default false,
  email_erro    text
);

alter table public.leads enable row level security;
revoke all on public.leads from anon, authenticated;

create index if not exists leads_created_at_idx on public.leads (created_at desc);
