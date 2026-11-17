@echo off
REM Preencha com os dados do seu projeto Supabase (Project Settings > API).
set SUPABASE_URL=https://SEU-PROJETO.supabase.co
set SUPABASE_ANON_KEY=SUA_ANON_KEY
flutter pub get
flutter run -d windows --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
