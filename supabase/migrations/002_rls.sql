-- =============================================================
-- ETA — Escola de Tecnologias Assistidas
-- Migration 002: Row Level Security
-- =============================================================

-- -------------------------
-- Habilitar RLS em todas as tabelas
-- -------------------------
alter table public.profiles    enable row level security;
alter table public.courses     enable row level security;
alter table public.modules     enable row level security;
alter table public.lessons     enable row level security;
alter table public.enrollments enable row level security;
alter table public.progress    enable row level security;
alter table public.materials   enable row level security;

-- -------------------------
-- profiles
-- Cada aluno lê e edita apenas o próprio perfil.
-- -------------------------
create policy "profiles: leitura própria"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles: edição própria"
  on public.profiles for update
  using (auth.uid() = id);

-- -------------------------
-- courses
-- Qualquer pessoa autenticada vê cursos publicados.
-- -------------------------
create policy "courses: leitura pública de publicados"
  on public.courses for select
  using (is_published = true);

-- -------------------------
-- modules
-- Autenticado vê módulos de cursos publicados.
-- -------------------------
create policy "modules: leitura autenticada"
  on public.modules for select
  using (
    exists (
      select 1 from public.courses c
      where c.id = course_id and c.is_published = true
    )
  );

-- -------------------------
-- lessons
-- Regra por nível de acesso:
--   - is_free = true → qualquer autenticado vê
--   - is_free = false → precisa de enrollment ativo
-- -------------------------
create policy "lessons: aulas gratuitas"
  on public.lessons for select
  using (
    is_free = true
    and exists (
      select 1 from public.courses c
      where c.id = course_id and c.is_published = true
    )
  );

create policy "lessons: aulas com matrícula"
  on public.lessons for select
  using (
    is_free = false
    and exists (
      select 1 from public.enrollments e
      where e.user_id = auth.uid()
        and e.course_id = lessons.course_id
        and e.status = 'active'
        and (e.expires_at is null or e.expires_at > now())
    )
  );

-- -------------------------
-- enrollments
-- Aluno vê apenas as próprias matrículas.
-- Sistema (service_role) insere via webhook Hotmart.
-- -------------------------
create policy "enrollments: leitura própria"
  on public.enrollments for select
  using (auth.uid() = user_id);

-- -------------------------
-- progress
-- Aluno lê e escreve apenas o próprio progresso.
-- -------------------------
create policy "progress: leitura própria"
  on public.progress for select
  using (auth.uid() = user_id);

create policy "progress: inserção própria"
  on public.progress for insert
  with check (auth.uid() = user_id);

create policy "progress: atualização própria"
  on public.progress for update
  using (auth.uid() = user_id);

-- -------------------------
-- materials
-- Mesma regra das aulas: gratuitos ou com matrícula.
-- -------------------------
create policy "materials: acesso com matrícula ou gratuito"
  on public.materials for select
  using (
    -- se tem lesson_id, herda a regra da aula
    (lesson_id is not null and exists (
      select 1 from public.lessons l
      where l.id = lesson_id
        and (
          l.is_free = true
          or exists (
            select 1 from public.enrollments e
            where e.user_id = auth.uid()
              and e.course_id = l.course_id
              and e.status = 'active'
              and (e.expires_at is null or e.expires_at > now())
          )
        )
    ))
    -- se só tem course_id (material geral do curso)
    or (lesson_id is null and course_id is not null and exists (
      select 1 from public.enrollments e
      where e.user_id = auth.uid()
        and e.course_id = materials.course_id
        and e.status = 'active'
        and (e.expires_at is null or e.expires_at > now())
    ))
  );
