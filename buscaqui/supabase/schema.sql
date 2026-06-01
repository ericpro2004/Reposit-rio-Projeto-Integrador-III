-- ============================================================================
--  BusCaqui — Schema PostgreSQL (Supabase)
--  Inclui: tipos ENUM, tabelas, relacionamentos, índices, RLS e triggers.
--  Ordem de execução respeita as dependências de chave estrangeira.
-- ============================================================================

-- Extensão para geração de UUID (já disponível no Supabase).
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. TIPOS ENUMERADOS
-- ----------------------------------------------------------------------------
do $$ begin
  create type tipo_usuario as enum ('motorista', 'responsavel', 'passageiro');
exception when duplicate_object then null; end $$;

do $$ begin
  create type presenca_status as enum ('presente', 'ausente', 'justificado');
exception when duplicate_object then null; end $$;

do $$ begin
  create type presenca_origem as enum ('manual', 'qrcode', 'codigo');
exception when duplicate_object then null; end $$;

-- ----------------------------------------------------------------------------
-- 2. USUARIOS  (perfil estendido de auth.users)
-- ----------------------------------------------------------------------------
create table if not exists public.usuarios (
  id           uuid primary key references auth.users (id) on delete cascade,
  nome         text        not null,
  email        text        not null unique,
  telefone     text,
  tipo_usuario tipo_usuario not null,
  foto_url     text,
  criado_em    timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 3. RESPONSAVEIS
-- ----------------------------------------------------------------------------
create table if not exists public.responsaveis (
  id        uuid primary key default gen_random_uuid(),
  -- Liga opcionalmente ao usuário autenticado responsável.
  usuario_id uuid references public.usuarios (id) on delete set null,
  nome      text not null,
  telefone  text,
  email     text,
  criado_em timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 4. CONEXOES  (rotas/vans criadas por um motorista)
-- ----------------------------------------------------------------------------
create table if not exists public.conexoes (
  id            uuid primary key default gen_random_uuid(),
  nome_conexao  text not null,
  codigo        text not null unique,          -- código alfanumérico de entrada
  qrcode_data   text not null unique,          -- payload do QR (token assinado)
  motorista_id  uuid not null references public.usuarios (id) on delete cascade,
  criado_em     timestamptz not null default now()
);

create index if not exists idx_conexoes_motorista on public.conexoes (motorista_id);

-- ----------------------------------------------------------------------------
-- 5. PASSAGEIROS
-- ----------------------------------------------------------------------------
create table if not exists public.passageiros (
  id             uuid primary key default gen_random_uuid(),
  -- Liga opcionalmente ao usuário autenticado passageiro.
  usuario_id     uuid references public.usuarios (id) on delete set null,
  nome           text not null,
  idade          int  check (idade >= 0 and idade <= 120),
  responsavel_id uuid references public.responsaveis (id) on delete set null,
  conexao_id     uuid references public.conexoes (id) on delete set null,
  criado_em      timestamptz not null default now()
);

create index if not exists idx_passageiros_conexao on public.passageiros (conexao_id);
create index if not exists idx_passageiros_responsavel on public.passageiros (responsavel_id);

-- ----------------------------------------------------------------------------
-- 6. PRESENCAS  (registro de chamada)
-- ----------------------------------------------------------------------------
create table if not exists public.presencas (
  id                uuid primary key default gen_random_uuid(),
  passageiro_id     uuid not null references public.passageiros (id) on delete cascade,
  data              date not null default current_date,
  status            presenca_status not null,
  origem            presenca_origem not null,
  horario_registro  timestamptz not null default now(),
  -- Garante 1 registro por passageiro por dia (upsert na chamada).
  unique (passageiro_id, data)
);

create index if not exists idx_presencas_passageiro_data
  on public.presencas (passageiro_id, data);

-- ----------------------------------------------------------------------------
-- 7. LOCALIZACOES  (tracking em tempo real — Realtime ativo)
-- ----------------------------------------------------------------------------
create table if not exists public.localizacoes (
  id           uuid primary key default gen_random_uuid(),
  motorista_id uuid not null references public.usuarios (id) on delete cascade,
  latitude     double precision not null,
  longitude    double precision not null,
  "timestamp"  timestamptz not null default now()
);

create index if not exists idx_localizacoes_motorista_ts
  on public.localizacoes (motorista_id, "timestamp" desc);

-- ----------------------------------------------------------------------------
-- 8. ALERTAS  (notificações enviadas aos responsáveis)
-- ----------------------------------------------------------------------------
create table if not exists public.alertas (
  id            uuid primary key default gen_random_uuid(),
  passageiro_id uuid not null references public.passageiros (id) on delete cascade,
  mensagem      text not null,
  lido          boolean not null default false,
  criado_em     timestamptz not null default now()
);

create index if not exists idx_alertas_passageiro on public.alertas (passageiro_id);

-- ============================================================================
--  TRIGGERS
-- ============================================================================

-- (A) Cria automaticamente o perfil em `usuarios` quando um usuário se
--     registra via Supabase Auth. O tipo e o nome vêm do metadata do signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.usuarios (id, nome, email, telefone, tipo_usuario)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', new.email),
    new.email,
    new.raw_user_meta_data ->> 'telefone',
    coalesce((new.raw_user_meta_data ->> 'tipo_usuario')::tipo_usuario, 'passageiro')
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- (B) Gera código e payload de QR únicos ao criar uma conexão, caso não venham
--     preenchidos pelo cliente.
create or replace function public.gen_connection_code()
returns trigger
language plpgsql set search_path = public
as $$
begin
  if new.codigo is null or new.codigo = '' then
    -- 6 caracteres alfanuméricos em maiúsculas (ex.: 'A3F9KZ').
    new.codigo := upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 6));
  end if;
  if new.qrcode_data is null or new.qrcode_data = '' then
    new.qrcode_data := 'buscaqui://conexao/' || new.id || '?c=' || new.codigo;
  end if;
  return new;
end $$;

drop trigger if exists before_conexao_insert on public.conexoes;
create trigger before_conexao_insert
  before insert on public.conexoes
  for each row execute function public.gen_connection_code();

-- (C) Ao registrar uma presença com status 'ausente', cria um alerta para o
--     responsável (consumido pela tela de Alertas e por push via Edge Function).
create or replace function public.notify_absence()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_nome text;
begin
  if new.status = 'ausente' then
    select nome into v_nome from public.passageiros where id = new.passageiro_id;
    insert into public.alertas (passageiro_id, mensagem)
    values (
      new.passageiro_id,
      coalesce(v_nome, 'Passageiro') ||
      ' não realizou presença hoje. Motivo: Ausência sem justificativa às ' ||
      to_char(new.horario_registro, 'HH24:MI') || '.'
    );
  end if;
  return new;
end $$;

drop trigger if exists after_presenca_absence on public.presencas;
create trigger after_presenca_absence
  after insert or update on public.presencas
  for each row execute function public.notify_absence();

-- ============================================================================
--  RPCs (SECURITY DEFINER) — operações que contornam o RLS de forma controlada
-- ============================================================================

-- (R1) Passageiro entra em uma conexão pelo CÓDIGO. Necessário SECURITY DEFINER
--      porque, antes de virar membro, o RLS impede o SELECT em `conexoes`.
create or replace function public.join_connection(p_codigo text)
returns public.conexoes
language plpgsql
security definer set search_path = public
as $$
declare
  v_conexao public.conexoes;
  v_updated int;
begin
  select * into v_conexao
    from public.conexoes
    where upper(codigo) = upper(trim(p_codigo))
    limit 1;

  if v_conexao.id is null then
    raise exception 'Conexão não encontrada para o código informado.'
      using errcode = 'P0002';
  end if;

  -- Vincula os passageiros sob a conta atual (passageiro ou responsável).
  update public.passageiros p
    set conexao_id = v_conexao.id
    where p.usuario_id = auth.uid()
       or p.responsavel_id in (
            select r.id from public.responsaveis r where r.usuario_id = auth.uid()
          );
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Nenhum passageiro vinculado à sua conta. Cadastre o aluno antes.'
      using errcode = 'P0001';
  end if;

  return v_conexao;
end $$;

-- (R2) Motorista regenera o token/código da conexão (invalida o anterior).
create or replace function public.refresh_connection_token(p_id uuid)
returns public.conexoes
language plpgsql
security definer set search_path = public
as $$
declare
  v_conexao public.conexoes;
  v_code text;
begin
  v_code := upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 6));
  update public.conexoes
    set codigo = v_code,
        qrcode_data = 'buscaqui://conexao/' || p_id || '?c=' || v_code
    where id = p_id and motorista_id = auth.uid()
    returning * into v_conexao;

  if v_conexao.id is null then
    raise exception 'Conexão não encontrada ou você não tem permissão.';
  end if;
  return v_conexao;
end $$;

-- (R3) Check-in do próprio passageiro via QR ou código (Tela 8). SECURITY
--      DEFINER porque o RLS só permite que o motorista escreva em `presencas`.
create or replace function public.register_presence(p_token text, p_origem presenca_origem)
returns public.presencas
language plpgsql
security definer set search_path = public
as $$
declare
  v_conexao public.conexoes;
  v_passageiro_id uuid;
  v_presenca public.presencas;
begin
  select * into v_conexao from public.conexoes
    where qrcode_data = p_token or upper(codigo) = upper(trim(p_token))
    limit 1;
  if v_conexao.id is null then
    raise exception 'QR Code inválido. Tente novamente ou insira o código manualmente.'
      using errcode = 'P0002';
  end if;

  select p.id into v_passageiro_id from public.passageiros p
    where p.conexao_id = v_conexao.id
      and (p.usuario_id = auth.uid()
           or p.responsavel_id in (
                select r.id from public.responsaveis r where r.usuario_id = auth.uid()))
    limit 1;
  if v_passageiro_id is null then
    raise exception 'Você não está vinculado a esta van. Entre na conexão primeiro.'
      using errcode = 'P0001';
  end if;

  insert into public.presencas (passageiro_id, data, status, origem)
  values (v_passageiro_id, current_date, 'presente', p_origem)
  on conflict (passageiro_id, data)
  do update set status = 'presente', origem = excluded.origem, horario_registro = now()
  returning * into v_presenca;
  return v_presenca;
end $$;

-- ============================================================================
--  REALTIME — habilita streaming de localização (e alertas)
-- ============================================================================
alter publication supabase_realtime add table public.localizacoes;
alter publication supabase_realtime add table public.alertas;

-- ============================================================================
--  ROW LEVEL SECURITY (RLS) — isolamento por perfil
-- ============================================================================
alter table public.usuarios     enable row level security;
alter table public.responsaveis enable row level security;
alter table public.conexoes     enable row level security;
alter table public.passageiros  enable row level security;
alter table public.presencas    enable row level security;
alter table public.localizacoes enable row level security;
alter table public.alertas      enable row level security;

-- USUARIOS: cada um lê/edita o próprio perfil.
create policy "usuarios_self_select" on public.usuarios
  for select using (auth.uid() = id);
create policy "usuarios_self_update" on public.usuarios
  for update using (auth.uid() = id);

-- RESPONSAVEIS: o próprio usuário responsável gerencia seu registro (Tela 4).
create policy "responsaveis_owner_select" on public.responsaveis
  for select using (usuario_id = auth.uid());
create policy "responsaveis_owner_insert" on public.responsaveis
  for insert with check (usuario_id = auth.uid());
create policy "responsaveis_owner_update" on public.responsaveis
  for update using (usuario_id = auth.uid());

-- CONEXOES: motorista gerencia as suas; membros conseguem ler.
create policy "conexoes_owner_all" on public.conexoes
  for all using (auth.uid() = motorista_id) with check (auth.uid() = motorista_id);
create policy "conexoes_member_select" on public.conexoes
  for select using (
    exists (
      select 1 from public.passageiros p
      where p.conexao_id = conexoes.id and p.usuario_id = auth.uid()
    )
  );

-- PASSAGEIROS: o próprio passageiro, o motorista da conexão ou o responsável.
create policy "passageiros_visibility" on public.passageiros
  for select using (
    usuario_id = auth.uid()
    or exists (select 1 from public.conexoes c
               where c.id = passageiros.conexao_id and c.motorista_id = auth.uid())
    or exists (select 1 from public.responsaveis r
               where r.id = passageiros.responsavel_id and r.usuario_id = auth.uid())
  );
-- INSERT/UPDATE do vínculo (Tela 4) pelo próprio usuário; motorista também edita.
create policy "passageiros_self_insert" on public.passageiros
  for insert with check (
    usuario_id = auth.uid()
    or responsavel_id in (
      select r.id from public.responsaveis r where r.usuario_id = auth.uid()
    )
  );
create policy "passageiros_self_update" on public.passageiros
  for update using (
    usuario_id = auth.uid()
    or responsavel_id in (
      select r.id from public.responsaveis r where r.usuario_id = auth.uid()
    )
    or exists (select 1 from public.conexoes c
               where c.id = passageiros.conexao_id and c.motorista_id = auth.uid())
  );

-- PRESENCAS: visíveis para o motorista da conexão e para o passageiro/responsável.
create policy "presencas_select" on public.presencas
  for select using (
    exists (
      select 1 from public.passageiros p
      join public.conexoes c on c.id = p.conexao_id
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = presencas.passageiro_id
        and (c.motorista_id = auth.uid()
             or p.usuario_id = auth.uid()
             or r.usuario_id = auth.uid())
    )
  );
-- Apenas o motorista da conexão registra/edita presença.
create policy "presencas_motorista_write" on public.presencas
  for all using (
    exists (
      select 1 from public.passageiros p
      join public.conexoes c on c.id = p.conexao_id
      where p.id = presencas.passageiro_id and c.motorista_id = auth.uid()
    )
  );

-- LOCALIZACOES: motorista escreve a sua; membros da conexão leem.
create policy "localizacoes_owner_write" on public.localizacoes
  for all using (auth.uid() = motorista_id) with check (auth.uid() = motorista_id);
create policy "localizacoes_member_select" on public.localizacoes
  for select using (
    exists (
      select 1 from public.conexoes c
      join public.passageiros p on p.conexao_id = c.id
      where c.motorista_id = localizacoes.motorista_id
        and (p.usuario_id = auth.uid()
             or exists (select 1 from public.responsaveis r
                        where r.id = p.responsavel_id and r.usuario_id = auth.uid()))
    )
  );

-- ALERTAS: visíveis ao responsável/passageiro do aluno; marca como lido.
create policy "alertas_select" on public.alertas
  for select using (
    exists (
      select 1 from public.passageiros p
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = alertas.passageiro_id
        and (p.usuario_id = auth.uid() or r.usuario_id = auth.uid())
    )
  );
create policy "alertas_update_read" on public.alertas
  for update using (
    exists (
      select 1 from public.passageiros p
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = alertas.passageiro_id
        and (p.usuario_id = auth.uid() or r.usuario_id = auth.uid())
    )
  );

-- ============================================================================
--  PRIVILÉGIOS DE EXECUÇÃO (mínimo necessário)
-- ============================================================================
-- Funções de trigger não são endpoints de API — revoga acesso por RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.notify_absence() from public, anon, authenticated;
revoke execute on function public.gen_connection_code() from public, anon, authenticated;

-- RPCs de negócio: apenas usuários autenticados (nunca anônimos).
revoke execute on function public.join_connection(text) from public, anon;
revoke execute on function public.refresh_connection_token(uuid) from public, anon;
revoke execute on function public.register_presence(text, presenca_origem) from public, anon;
grant execute on function public.join_connection(text) to authenticated;
grant execute on function public.refresh_connection_token(uuid) to authenticated;
grant execute on function public.register_presence(text, presenca_origem) to authenticated;
