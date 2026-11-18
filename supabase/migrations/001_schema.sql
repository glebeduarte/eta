-- =============================================================
-- ETA — Escola de Tecnologias Assistidas
-- Migration 001: Schema principal
-- =============================================================

-- -------------------------
-- Extensões
-- -------------------------
create extension if not exists "uuid-ossp";

-- -------------------------
-- Tabela: profiles
-- Criada automaticamente quando um usuário é criado no Supabase Auth.
-- Contém dados públicos do aluno.
-- -------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  email       text unique not null,
  avatar_url  text,
  bio         text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- -------------------------
-- Tabela: courses
-- Cursos disponíveis na plataforma.
-- -------------------------
create table if not exists public.courses (
  id            uuid primary key default uuid_generate_v4(),
  slug          text unique not null,
  title         text not null,
  description   text,
  cover_color   text default 'cover-neuro',   -- classe CSS da capa
  cover_icon    text default '🧠',
  category      text not null,
  level         text check (level in ('iniciante','intermediário','avançado')) default 'intermediário',
  duration_min  integer default 0,            -- duração total em minutos
  is_published  boolean default false,
  hotmart_product_id text,                    -- ID do produto no Hotmart
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- -------------------------
-- Tabela: modules
-- Módulos de um curso.
-- -------------------------
create table if not exists public.modules (
  id          uuid primary key default uuid_generate_v4(),
  course_id   uuid not null references public.courses(id) on delete cascade,
  title       text not null,
  position    integer not null default 0,
  is_free     boolean default false,          -- módulo disponível sem matrícula
  created_at  timestamptz default now()
);

-- -------------------------
-- Tabela: lessons
-- Aulas dentro de um módulo.
-- -------------------------
create table if not exists public.lessons (
  id              uuid primary key default uuid_generate_v4(),
  module_id       uuid not null references public.modules(id) on delete cascade,
  course_id       uuid not null references public.courses(id) on delete cascade,
  title           text not null,
  description     text,
  panda_video_id  text,                       -- ID do vídeo no Panda Vídeo
  duration_min    integer default 0,
  position        integer not null default 0,
  is_free         boolean default false,
  created_at      timestamptz default now()
);

-- -------------------------
-- Tabela: enrollments
-- Matrícula de um aluno em um curso.
-- -------------------------
create table if not exists public.enrollments (
  id                  uuid primary key default uuid_generate_v4(),
  user_id             uuid not null references public.profiles(id) on delete cascade,
  course_id           uuid not null references public.courses(id) on delete cascade,
  status              text check (status in ('active','expired','cancelled')) default 'active',
  hotmart_transaction text unique,            -- código de transação do Hotmart
  enrolled_at         timestamptz default now(),
  expires_at          timestamptz,            -- nulo = acesso vitalício
  unique (user_id, course_id)
);

-- -------------------------
-- Tabela: progress
-- Progresso de um aluno por aula.
-- -------------------------
create table if not exists public.progress (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  lesson_id     uuid not null references public.lessons(id) on delete cascade,
  course_id     uuid not null references public.courses(id) on delete cascade,
  completed     boolean default false,
  watched_pct   integer default 0 check (watched_pct between 0 and 100),
  last_watched  timestamptz default now(),
  unique (user_id, lesson_id)
);

-- -------------------------
-- Tabela: materials
-- Materiais complementares de uma aula.
-- -------------------------
create table if not exists public.materials (
  id          uuid primary key default uuid_generate_v4(),
  lesson_id   uuid references public.lessons(id) on delete cascade,
  course_id   uuid references public.courses(id) on delete cascade,
  title       text not null,
  type        text check (type in ('pdf','link','planilha','apresentação','outro')) default 'pdf',
  url         text not null,
  created_at  timestamptz default now()
);

-- -------------------------
-- Trigger: atualiza updated_at automaticamente
-- -------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger courses_updated_at
  before update on public.courses
  for each row execute procedure public.set_updated_at();

-- -------------------------
-- Trigger: cria profile automaticamente ao criar usuário no Auth
-- -------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
