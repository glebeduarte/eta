# Escola de Tecnologias Assistidas (ETA)

Plataforma de ensino para fisioterapeutas — cursos, área de membros e conteúdo sobre tecnologias assistivas (AFOs, órteses e adaptações).

## Stack

- **Frontend**: HTML/CSS/JS vanilla, sem framework — single-file para a área de membros
- **Auth + DB**: Supabase (projeto `gayfopqjkfpnkekcwfdx`)
- **Vídeo**: Panda Vídeo
- **Pagamento**: Hotmart
- **Host**: Vercel ou Netlify

## Estrutura

```
eta/
├── public/
│   ├── index.html          # Landing page pública
│   └── membros.html        # Área de membros (requer auth)
├── supabase/
│   └── migrations/
│       ├── 001_schema.sql      # Tabelas principais
│       ├── 002_rls.sql         # Row Level Security
│       └── 003_seed.sql        # Dados iniciais (cursos, módulos)
├── functions/
│   └── hotmart-webhook/
│       └── index.ts            # Edge function: recebe eventos Hotmart
└── README.md
```

## Configuração do Supabase

1. Criar projeto em [supabase.com](https://supabase.com)
2. Executar as migrations em `supabase/migrations/` na ordem numérica
3. Adicionar variáveis de ambiente:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `HOTMART_SECRET` (para validar webhook)

## Fluxo de matrícula

1. Aluno compra no Hotmart
2. Hotmart dispara webhook para a edge function
3. Edge function cria registro em `enrollments`
4. Aluno recebe e-mail com link de acesso
5. No primeiro acesso, Supabase Auth cria a conta via magic link

## Modelo de negócio (restrição legal)

Comissão por indicação é vedada pelo Conselho Federal de Fisioterapia.  
O modelo aceito é relação de fornecimento: Leonardo fabrica a órtese com custo reduzido para o fisioterapeuta formado pela ETA, que revende com margem própria.
