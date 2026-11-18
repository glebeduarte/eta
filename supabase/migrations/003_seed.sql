-- =============================================================
-- ETA — Escola de Tecnologias Assistidas
-- Migration 003: Dados iniciais (cursos e módulos)
-- =============================================================

-- -------------------------
-- Cursos
-- -------------------------
insert into public.courses (slug, title, description, cover_color, cover_icon, category, level, duration_min, is_published)
values
  (
    'afo-neurologica',
    'AFO Neurológica na Prática',
    'Domine a prescrição e adaptação de órteses tornozelo-pé para pacientes neurológicos. Do raciocínio clínico ao follow-up com o paciente e família.',
    'cover-neuro',
    '🧠',
    'Neurologia',
    'intermediário',
    480,
    true
  ),
  (
    'afo-pediatrica',
    'AFO Pediátrica: Crescimento e Adaptação',
    'Prescrição de órteses para crianças em crescimento — timing correto, materiais adequados e como adaptar conforme o desenvolvimento motor.',
    'cover-ped',
    '👶',
    'Pediátrica',
    'intermediário',
    360,
    true
  ),
  (
    'orto-membro-superior',
    'Órteses de Membro Superior na Reabilitação',
    'Órteses para mão, punho e cotovelo: da avaliação à adaptação funcional, incluindo casos pós-AVE e lesões de plexo braquial.',
    'cover-orto',
    '🦾',
    'Membro Superior',
    'avançado',
    420,
    true
  ),
  (
    'ia-clinica-reabilitacao',
    'IA na Clínica de Reabilitação',
    'Como usar ferramentas de IA no dia a dia clínico: documentação, análise de marcha, comunicação com paciente e gestão da clínica.',
    'cover-ia',
    '🤖',
    'Tecnologia',
    'iniciante',
    240,
    true
  );

-- -------------------------
-- Módulos — AFO Neurológica
-- -------------------------
with c as (select id from public.courses where slug = 'afo-neurologica')
insert into public.modules (course_id, title, position, is_free)
select c.id, m.title, m.position, m.is_free
from c, (values
  ('Fundamentos da Marcha Neurológica', 1, true),
  ('Prescrição Clínica de AFO', 2, false),
  ('Adaptação e Follow-up', 3, false),
  ('Casos Clínicos Comentados', 4, false)
) as m(title, position, is_free);

-- -------------------------
-- Módulos — AFO Pediátrica
-- -------------------------
with c as (select id from public.courses where slug = 'afo-pediatrica')
insert into public.modules (course_id, title, position, is_free)
select c.id, m.title, m.position, m.is_free
from c, (values
  ('Desenvolvimento Motor e Timing', 1, true),
  ('Materiais e Tipos de AFO Pediátrica', 2, false),
  ('Casos: Paralisia Cerebral e MMC', 3, false)
) as m(title, position, is_free);

-- -------------------------
-- Módulos — Membro Superior
-- -------------------------
with c as (select id from public.courses where slug = 'orto-membro-superior')
insert into public.modules (course_id, title, position, is_free)
select c.id, m.title, m.position, m.is_free
from c, (values
  ('Anatomia Funcional e Biomecânica', 1, true),
  ('Órteses de Punho e Mão', 2, false),
  ('Órteses Dinâmicas', 3, false),
  ('Reabilitação pós-AVE', 4, false)
) as m(title, position, is_free);

-- -------------------------
-- Módulos — IA na Clínica
-- -------------------------
with c as (select id from public.courses where slug = 'ia-clinica-reabilitacao')
insert into public.modules (course_id, title, position, is_free)
select c.id, m.title, m.position, m.is_free
from c, (values
  ('IA no Consultório: Visão Geral', 1, true),
  ('Documentação com IA', 2, false),
  ('Análise de Marcha e Vídeo', 3, false)
) as m(title, position, is_free);

-- -------------------------
-- Aulas — Módulo 1 de AFO Neurológica (5 aulas, todas gratuitas)
-- -------------------------
with m as (
  select mo.id as module_id, c.id as course_id
  from public.modules mo
  join public.courses c on c.id = mo.course_id
  where c.slug = 'afo-neurologica' and mo.position = 1
)
insert into public.lessons (module_id, course_id, title, duration_min, position, is_free)
select m.module_id, m.course_id, l.title, l.duration, l.position, true
from m, (values
  ('O ciclo da marcha em 10 minutos', 8, 1),
  ('Padrões patológicos: espasticidade, steppage, Trendelenburg', 12, 2),
  ('Avaliação funcional da marcha', 15, 3),
  ('Introdução às órteses tornozelo-pé', 10, 4),
  ('Checklist de avaliação pré-prescrição', 7, 5)
) as l(title, duration, position);

-- -------------------------
-- Aulas — Módulo 2 de AFO Neurológica (5 aulas, pagas)
-- -------------------------
with m as (
  select mo.id as module_id, c.id as course_id
  from public.modules mo
  join public.courses c on c.id = mo.course_id
  where c.slug = 'afo-neurologica' and mo.position = 2
)
insert into public.lessons (module_id, course_id, title, duration_min, position, is_free)
select m.module_id, m.course_id, l.title, l.duration, l.position, false
from m, (values
  ('Tipos de AFO: sólida, articulada, dinâmica', 20, 1),
  ('Indicação por diagnóstico: AVE, TCE, Parkinson', 18, 2),
  ('Materiais: polipropileno, carbono, termoplásticos', 15, 3),
  ('Comunicação com o ortesista', 12, 4),
  ('Documentação e laudos', 10, 5)
) as l(title, duration, position);
