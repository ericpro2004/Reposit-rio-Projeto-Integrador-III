-- =====================================================================
-- BusCaqui — Schema completo (Supabase / PostgreSQL)
-- Execute no SQL Editor do Supabase, de cima para baixo.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Extensões
-- ---------------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- 1. Tipos enumerados (ENUMs)
-- ---------------------------------------------------------------------
do $$ begin
  create type tipo_usuario   as enum ('motorista', 'responsavel', 'passageiro');
exception when duplicate_object then null; end $$;

do $$ begin
  create type status_presenca as enum ('presente', 'ausente', 'justificado');
exception when duplicate_object then null; end $$;

do $$ begin
  create type origem_presenca  as enum ('manual', 'qrcode', 'codigo');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- 2. Tabela: usuarios  (perfil estendido de auth.users)
--    A PK = id de auth.users (1:1 com o usuário autenticado)
-- ---------------------------------------------------------------------
create table if not exists public.usuarios (
  id           uuid primary key references auth.users (id) on delete cascade,
  nome         text not null,
  email        text not null,
  telefone     text,
  tipo_usuario tipo_usuario not null default 'passageiro',
  foto_url     text,
  criado_em    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. Tabela: responsaveis
--    usuario_id permite (opcionalmente) que um responsável tenha login.
-- ---------------------------------------------------------------------
create table if not exists public.responsaveis (
  id         uuid primary key default uuid_generate_v4(),
  usuario_id uuid references public.usuarios (id) on delete set null,
  nome       text not null,
  telefone   text,
  email      text,
  criado_em  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. Tabela: conexoes  (a "van"/grupo de transporte do motorista)
-- ---------------------------------------------------------------------
create table if not exists public.conexoes (
  id           uuid primary key default uuid_generate_v4(),
  nome_conexao text not null,
  codigo       text unique not null,
  qrcode_data  text,
  motorista_id uuid not null references public.usuarios (id) on delete cascade,
  criado_em    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 5. Tabela: passageiros
-- ---------------------------------------------------------------------
create table if not exists public.passageiros (
  id             uuid primary key default uuid_generate_v4(),
  nome           text not null,
  idade          int check (idade is null or idade between 0 and 120),
  responsavel_id uuid references public.responsaveis (id) on delete set null,
  conexao_id     uuid references public.conexoes (id) on delete set null,
  usuario_id     uuid references public.usuarios (id) on delete set null, -- se o aluno tem login
  foto_url       text,
  criado_em      timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 6. Tabela: presencas
--    UNIQUE (passageiro_id, data) evita duplo registro no mesmo dia.
-- ---------------------------------------------------------------------
create table if not exists public.presencas (
  id               uuid primary key default uuid_generate_v4(),
  passageiro_id    uuid not null references public.passageiros (id) on delete cascade,
  data             date not null default current_date,
  status           status_presenca not null,
  origem           origem_presenca not null,
  horario_registro timestamptz not null default now(),
  registrado_por   uuid references public.usuarios (id) on delete set null,
  unique (passageiro_id, data)
);

-- ---------------------------------------------------------------------
-- 7. Tabela: localizacoes  (tracking em tempo real da van)
-- ---------------------------------------------------------------------
create table if not exists public.localizacoes (
  id           uuid primary key default uuid_generate_v4(),
  motorista_id uuid not null references public.usuarios (id) on delete cascade,
  latitude     double precision not null,
  longitude    double precision not null,
  capturado_em timestamptz not null default now()
);
create index if not exists idx_localizacoes_motorista
  on public.localizacoes (motorista_id, capturado_em desc);

-- ---------------------------------------------------------------------
-- 8. Tabela: alertas  (feed de notificações ao responsável)
-- ---------------------------------------------------------------------
create table if not exists public.alertas (
  id            uuid primary key default uuid_generate_v4(),
  passageiro_id uuid not null references public.passageiros (id) on delete cascade,
  mensagem      text not null,
  lido          boolean not null default false,
  criado_em     timestamptz not null default now()
);

-- =====================================================================
-- 9. TRIGGERS
-- =====================================================================

-- 9.1 Cria o perfil em public.usuarios automaticamente após o signup.
--     Os metadados (nome, telefone, tipo_usuario) devem ser passados em
--     options.data no signUp do app.
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
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 9.2 Gera um alerta automático quando uma ausência é registrada.
create or replace function public.gerar_alerta_ausencia()
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
      format('%s não realizou presença em %s. Motivo: Ausência sem justificativa às %s.',
             coalesce(v_nome, 'Passageiro'),
             to_char(new.data, 'DD/MM/YYYY'),
             to_char(new.horario_registro, 'HH24:MI'))
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_alerta_ausencia on public.presencas;
create trigger trg_alerta_ausencia
  after insert or update of status on public.presencas
  for each row execute function public.gerar_alerta_ausencia();

-- =====================================================================
-- 10. REALTIME — habilita streaming nas tabelas dinâmicas
-- =====================================================================
do $$ begin
  alter publication supabase_realtime add table public.localizacoes;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.presencas;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.alertas;
exception when duplicate_object then null; end $$;

-- =====================================================================
-- 11. STORAGE — bucket para fotos de perfil
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Qualquer usuário autenticado pode subir/atualizar seu avatar;
-- leitura é pública (bucket público).
create policy "avatars upload autenticado"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars');
create policy "avatars update dono"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and owner = auth.uid());
create policy "avatars leitura publica"
  on storage.objects for select to public
  using (bucket_id = 'avatars');

-- =====================================================================
-- 12. ROW LEVEL SECURITY (isolamento por perfil)
-- =====================================================================
alter table public.usuarios     enable row level security;
alter table public.responsaveis enable row level security;
alter table public.conexoes     enable row level security;
alter table public.passageiros  enable row level security;
alter table public.presencas    enable row level security;
alter table public.localizacoes enable row level security;
alter table public.alertas      enable row level security;

-- Função auxiliar: retorna o tipo do usuário logado (evita recursão de RLS)
create or replace function public.tipo_do_usuario()
returns tipo_usuario
language sql stable security definer set search_path = public
as $$ select tipo_usuario from public.usuarios where id = auth.uid() $$;

-- --- usuarios ---------------------------------------------------------
create policy "usuario le proprio perfil"
  on public.usuarios for select to authenticated
  using (id = auth.uid());
create policy "usuario edita proprio perfil"
  on public.usuarios for update to authenticated
  using (id = auth.uid());

-- --- conexoes ---------------------------------------------------------
-- Motorista gerencia as próprias conexões; qualquer autenticado pode ler
-- (necessário para o passageiro entrar via código).
create policy "conexoes leitura autenticada"
  on public.conexoes for select to authenticated using (true);
create policy "motorista gerencia conexoes"
  on public.conexoes for all to authenticated
  using (motorista_id = auth.uid())
  with check (motorista_id = auth.uid());

-- --- passageiros ------------------------------------------------------
-- Motorista vê passageiros das suas conexões; responsável vê seus filhos;
-- o próprio passageiro vê a si mesmo.
create policy "passageiros visiveis aos envolvidos"
  on public.passageiros for select to authenticated
  using (
    usuario_id = auth.uid()
    or exists (select 1 from public.conexoes c
               where c.id = passageiros.conexao_id and c.motorista_id = auth.uid())
    or exists (select 1 from public.responsaveis r
               where r.id = passageiros.responsavel_id and r.usuario_id = auth.uid())
  );
create policy "passageiro/responsavel gerencia vinculo"
  on public.passageiros for insert to authenticated with check (true);
create policy "passageiro/responsavel atualiza vinculo"
  on public.passageiros for update to authenticated
  using (
    usuario_id = auth.uid()
    or exists (select 1 from public.responsaveis r
               where r.id = passageiros.responsavel_id and r.usuario_id = auth.uid())
  );

-- --- presencas --------------------------------------------------------
create policy "presencas visiveis aos envolvidos"
  on public.presencas for select to authenticated
  using (
    exists (
      select 1 from public.passageiros p
      left join public.conexoes c    on c.id = p.conexao_id
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = presencas.passageiro_id
        and (p.usuario_id = auth.uid()
             or c.motorista_id = auth.uid()
             or r.usuario_id = auth.uid())
    )
  );
-- Registro de presença: motorista (chamada manual) ou o próprio passageiro (check-in QR)
create policy "registro de presenca"
  on public.presencas for insert to authenticated
  with check (
    exists (
      select 1 from public.passageiros p
      left join public.conexoes c on c.id = p.conexao_id
      where p.id = presencas.passageiro_id
        and (c.motorista_id = auth.uid() or p.usuario_id = auth.uid())
    )
  );
create policy "atualizacao de presenca pelo motorista"
  on public.presencas for update to authenticated
  using (
    exists (select 1 from public.passageiros p
            join public.conexoes c on c.id = p.conexao_id
            where p.id = presencas.passageiro_id and c.motorista_id = auth.uid())
  );

-- --- localizacoes -----------------------------------------------------
-- Motorista escreve a própria posição; responsáveis dos passageiros da
-- conexão podem ler.
create policy "motorista escreve localizacao"
  on public.localizacoes for insert to authenticated
  with check (motorista_id = auth.uid());
create policy "localizacao visivel aos vinculados"
  on public.localizacoes for select to authenticated
  using (
    motorista_id = auth.uid()
    or exists (
      select 1 from public.passageiros p
      join public.conexoes c     on c.id = p.conexao_id
      join public.responsaveis r on r.id = p.responsavel_id
      where c.motorista_id = localizacoes.motorista_id
        and (r.usuario_id = auth.uid() or p.usuario_id = auth.uid())
    )
  );

-- --- alertas ----------------------------------------------------------
create policy "alertas visiveis aos vinculados"
  on public.alertas for select to authenticated
  using (
    exists (
      select 1 from public.passageiros p
      left join public.conexoes c     on c.id = p.conexao_id
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = alertas.passageiro_id
        and (p.usuario_id = auth.uid()
             or c.motorista_id = auth.uid()
             or r.usuario_id = auth.uid())
    )
  );
create policy "marcar alerta como lido"
  on public.alertas for update to authenticated
  using (
    exists (
      select 1 from public.passageiros p
      left join public.responsaveis r on r.id = p.responsavel_id
      where p.id = alertas.passageiro_id
        and (p.usuario_id = auth.uid() or r.usuario_id = auth.uid())
    )
  );

-- --- responsaveis -----------------------------------------------------
create policy "responsavel le/edita proprio registro"
  on public.responsaveis for all to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- =====================================================================
-- FIM DO SCHEMA
-- =====================================================================
