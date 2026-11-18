-- 005: produtos de ticket baixo (materiais prontos) ao lado dos cursos

alter table courses
  add column if not exists kind text not null default 'curso' check (kind in ('curso','material','formacao')),
  add column if not exists price numeric(10,2),
  add column if not exists checkout_url text,
  add column if not exists format text;

update courses set price = 97 where kind = 'curso' and price is null;

insert into courses (slug, title, subtitle, description, category, level, kind, price, format, is_published, position, outcomes, cover_url, bg_url)
values
('guia-prescricao-afo', 'Guia de Prescrição de AFO',
 'O passo a passo para escolher, medir e prescrever AFO com segurança',
 'E-book de consulta rápida para o consultório: tipos de AFO, indicações por padrão de marcha, contraindicações e o roteiro da prescrição.',
 'E-book', 'iniciante', 'material', 47, 'E-book em PDF · 60 páginas', true, 10,
 array['Tabela de indicação por padrão de marcha','Diferenças entre AFO rígida, articulada e de reação ao solo','Roteiro de prescrição em 7 passos','Erros comuns e como evitar'],
 'assets/afo-neurologica-cover.jpg','assets/bg-neural.jpg'),
('kit-fichas-avaliacao', 'Kit de Fichas de Avaliação',
 'Fichas editáveis para avaliar e prescrever órteses no consultório e no domicílio',
 'Fichas prontas para membros inferiores, avaliação neurológica, pediátrica e membro superior, em formato editável e para impressão.',
 'Material clínico', 'iniciante', 'material', 67, '4 fichas editáveis (Word, PDF e Google Docs)', true, 11,
 array['Ficha de membros inferiores','Ficha de avaliação neurológica','Ficha pediátrica com acompanhamento de crescimento','Ficha de membro superior'],
 'assets/afo-pediatrica-cover.jpg','assets/bg-pediatrica.jpg'),
('modelos-laudo-relatorio', 'Modelos de Laudo e Relatório',
 'Textos-base para justificar a órtese ao paciente, ao médico e ao plano de saúde',
 'Modelos de laudo técnico, relatório de evolução e justificativa para convênio, com campos para adaptar a cada caso.',
 'Material clínico', 'iniciante', 'material', 57, '12 modelos editáveis', true, 12,
 array['Laudo de indicação de órtese','Relatório de evolução funcional','Justificativa para plano de saúde','Termo de orientação de uso ao paciente'],
 'assets/membro-superior-cover.jpg','assets/bg-membro-superior.jpg'),
('guia-medidas-moldagem', 'Guia de Medidas e Moldagem',
 'Como tirar as medidas certas para a órtese chegar ajustada ao paciente',
 'Guia ilustrado com os pontos de referência, a sequência de medidas e vídeos curtos de demonstração.',
 'Guia prático', 'iniciante', 'material', 47, 'PDF ilustrado + 5 vídeos curtos', true, 13,
 array['Pontos anatômicos de referência','Sequência de medidas por tipo de órtese','Fotos e vídeo para envio ao laboratório','Checklist antes de enviar o pedido'],
 'assets/afo-neurologica-cover.jpg','assets/bg-neural.jpg'),
('kit-clinico-eta', 'Kit Clínico ETA',
 'Fichas, laudos, guia de prescrição e guia de medidas em um só pacote',
 'Os quatro materiais prontos da ETA reunidos, com preço menor que a soma das partes.',
 'Pacote', 'iniciante', 'material', 97, '4 materiais em um pacote', true, 14,
 array['Guia de Prescrição de AFO','Kit de Fichas de Avaliação','Modelos de Laudo e Relatório','Guia de Medidas e Moldagem'],
 'assets/afo-pediatrica-cover.jpg','assets/bg-pediatrica.jpg')
on conflict (slug) do nothing;
