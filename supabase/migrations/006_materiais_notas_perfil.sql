-- 006: anotações por aula, campos extras do perfil e materiais de apoio dos cursos

create table if not exists notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references lessons(id) on delete cascade,
  body text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);
alter table notes enable row level security;
create policy "notes: dono lê"     on notes for select using (auth.uid() = user_id);
create policy "notes: dono cria"   on notes for insert with check (auth.uid() = user_id);
create policy "notes: dono edita"  on notes for update using (auth.uid() = user_id);
create policy "notes: dono apaga"  on notes for delete using (auth.uid() = user_id);

alter table profiles
  add column if not exists whatsapp text,
  add column if not exists area text,
  add column if not exists city text,
  add column if not exists state text;

alter table materials alter column url drop not null;
alter table materials drop constraint if exists materials_type_check;
alter table materials add constraint materials_type_check check (type in ('pdf','link','planilha','apresentação','outro','ebook','slides','checklist','ficha','modelo','video'));
alter table materials
  add column if not exists size_label text,
  add column if not exists position integer default 0;

alter table courses add column if not exists instructor_bio text;
update courses set instructor_bio = 'Fisioterapeuta com atuação em tecnologias assistivas no Rio Grande do Norte. Professor de prática clínica em cursos de graduação e responsável por órteses, próteses e adaptações em clínicas parceiras de Natal, Mossoró e Parelhas.'
where instructor_bio is null;

-- materiais de apoio dos cursos (arquivo a ser enviado: url fica vazia até o upload)
insert into materials (course_id, title, type, size_label, position)
select c.id, m.title, m.type, m.size_label, m.pos
from courses c
join (values
  ('afo-neurologica','Protocolo de Avaliação Biomecânica','pdf','PDF',1),
  ('afo-neurologica','Tabela de Escalas de Espasticidade','pdf','PDF',2),
  ('afo-neurologica','Slides: Tipos de AFO e Indicações','slides','PDF',3),
  ('afo-neurologica','Checklist de Prescrição de AFO','checklist','PDF',4),
  ('afo-neurologica','Referências Bibliográficas','pdf','PDF',5),
  ('afo-pediatrica','Protocolo Pediátrico de Avaliação','pdf','PDF',1),
  ('afo-pediatrica','Tabela de Crescimento e Ajuste','pdf','PDF',2),
  ('afo-pediatrica','Slides: Paralisia Cerebral e AFO','slides','PDF',3),
  ('orto-membro-superior','Protocolo de Avaliação de Punho e Mão','pdf','PDF',1),
  ('orto-membro-superior','Slides: Órteses Estáticas e Dinâmicas','slides','PDF',2),
  ('ia-clinica-reabilitacao','Prompts para Evolução Clínica','pdf','PDF',1),
  ('ia-clinica-reabilitacao','Guia de Ferramentas de IA para a Clínica','pdf','PDF',2),
  ('guia-prescricao-afo','Guia de Prescrição de AFO','ebook','E-book PDF',1),
  ('kit-fichas-avaliacao','Ficha de Membros Inferiores','ficha','Editável',1),
  ('kit-fichas-avaliacao','Ficha de Avaliação Neurológica','ficha','Editável',2),
  ('kit-fichas-avaliacao','Ficha Pediátrica','ficha','Editável',3),
  ('kit-fichas-avaliacao','Ficha de Membro Superior','ficha','Editável',4),
  ('modelos-laudo-relatorio','Modelos de Laudo e Relatório','modelo','Editável',1),
  ('guia-medidas-moldagem','Guia de Medidas e Moldagem','pdf','PDF ilustrado',1),
  ('kit-clinico-eta','Guia de Prescrição de AFO','ebook','E-book PDF',1),
  ('kit-clinico-eta','Kit de Fichas de Avaliação','ficha','Editável',2),
  ('kit-clinico-eta','Modelos de Laudo e Relatório','modelo','Editável',3),
  ('kit-clinico-eta','Guia de Medidas e Moldagem','pdf','PDF ilustrado',4)
) as m(slug,title,type,size_label,pos) on m.slug = c.slug
where not exists (select 1 from materials x where x.course_id = c.id and x.title = m.title);

-- conta admin: acesso aos materiais também
insert into enrollments (user_id, course_id, status, hotmart_transaction)
select u.id, c.id, 'active', 'admin-' || c.slug
from auth.users u cross join courses c
where u.email = 'glebejr@gmail.com' and c.kind = 'material'
on conflict (user_id, course_id) do nothing;
