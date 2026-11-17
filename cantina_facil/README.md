# Cantina Fácil: Painel Administrativo (Windows)

## Como rodar
1. Instale o Flutter (3.27 ou superior) e o Visual Studio com "Desktop development with C++".
2. Edite `run_windows.bat` com a URL e a anon key do seu projeto Supabase.
3. Execute `run_windows.bat`, ou rode manualmente:
   `flutter pub get` e `flutter run -d windows --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

Nunca coloque a `service_role` no app. Ela só existe na Edge Function.

## Estrutura
- `lib/core`: tema, formatação e sessão em memória.
- `lib/models`, `lib/services`: perfil de acesso e autenticação.
- `lib/features/auth`: login por e-mail e senha.
- `lib/features/admin_shell`: `NavigationRail` desktop.
- `lib/features/dashboard`: repositório (consultas por tabela, cruzadas em Dart), controller e telas.
- `supabase/functions/admin-users`: Edge Function para criar, redefinir senha e bloquear usuários.
- `supabase/migrations`: rascunho da RPC `estornar_venda`. Revise antes de aplicar.

## Pontos ainda pendentes
- Seletor de unidade no `NavigationRail` (o filtro de unidade já existe no cabeçalho do dashboard).
- Telas de Cantinas, Equipe, Alunos, Produtos e Vendas (hoje são placeholders nas rotas).
- Não foi possível compilar aqui: rode `flutter analyze` e envie o log se houver erro.
- Os nomes de colunas seguem a especificação. Se `criado_em` ou `id_unid` diferirem no seu schema, ajuste `dashboard_repository.dart`.
