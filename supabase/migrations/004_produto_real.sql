-- 004: campos visuais dos cursos, ementa pública e aulas de exemplo para todos os módulos

alter table courses
  add column if not exists subtitle   text,
  add column if not exists cover_url  text,
  add column if not exists bg_url     text,
  add column if not exists instructor text default 'Leonardo Dantas',
  add column if not exists instructor_bio text,
  add column if not exists outcomes   text[] default '{}',
  add column if not exists position   integer default 0;

update courses set
  subtitle = 'Prescreva e adapte AFO para pacientes neurológicos com critério clínico',
  cover_url = 'assets/afo-neurologica-cover.jpg',
  bg_url = 'assets/bg-neural.jpg',
  outcomes = array['Ler a marcha neurológica e identificar a falha que a órtese precisa corrigir','Escolher entre AFO rígida, articulada e de reação ao solo','Montar a prescrição com medidas, material e ajustes','Conduzir a adaptação e o acompanhamento do paciente'],
  position = 1
where slug = 'afo-neurologica';

update courses set
  subtitle = 'AFO na infância: o momento certo, o material certo e o ajuste ao crescimento',
  cover_url = 'assets/afo-pediatrica-cover.jpg',
  bg_url = 'assets/bg-pediatrica.jpg',
  outcomes = array['Relacionar o desenvolvimento motor ao momento de indicar a órtese','Escolher materiais e modelos para cada fase','Planejar trocas e ajustes conforme a criança cresce','Aplicar o raciocínio em casos de paralisia cerebral e mielomeningocele'],
  position = 2
where slug = 'afo-pediatrica';

update courses set
  subtitle = 'Órteses de punho, mão e dinâmicas na reabilitação do membro superior',
  cover_url = 'assets/membro-superior-cover.jpg',
  bg_url = 'assets/bg-membro-superior.jpg',
  outcomes = array['Revisar a biomecânica de punho e mão aplicada à órtese','Indicar órteses estáticas e dinâmicas','Prescrever para o paciente pós-AVE','Acompanhar a evolução funcional'],
  position = 3
where slug = 'orto-membro-superior';

update courses set
  subtitle = 'Ferramentas de IA para documentação, análise de marcha e rotina da clínica',
  bg_url = 'assets/bg-neural.jpg',
  outcomes = array['Usar IA para evoluções e relatórios clínicos','Analisar vídeos de marcha com apoio de IA','Organizar a rotina do consultório com assistentes'],
  position = 4
where slug = 'ia-clinica-reabilitacao';

-- Ementa pública: título e duração das aulas de cursos publicados, sem o vídeo.
create or replace function public.course_outline(p_slug text)
returns table (module_id uuid, module_title text, module_position int,
               lesson_id uuid, lesson_title text, lesson_position int,
               duration_min int, is_free boolean)
language sql stable security definer set search_path = public as $$
  select m.id, m.title, m.position, l.id, l.title, l.position, l.duration_min, l.is_free
  from courses c
  join modules m on m.course_id = c.id
  left join lessons l on l.module_id = m.id
  where c.slug = p_slug and c.is_published
  order by m.position, l.position;
$$;
grant execute on function public.course_outline(text) to anon, authenticated;

-- Aulas de exemplo para os módulos ainda vazios (3 por módulo; a 1ª do curso é gratuita).
insert into lessons (module_id, course_id, title, description, duration_min, position, is_free)
select m.id, m.course_id,
       m.title || ' · Aula ' || g.n,
       'Conteúdo da aula ' || g.n || ' do módulo "' || m.title || '".',
       12 + g.n * 3, g.n,
       (m.position = 1 and g.n = 1)
from modules m
cross join generate_series(1,3) as g(n)
where not exists (select 1 from lessons l where l.module_id = m.id);
