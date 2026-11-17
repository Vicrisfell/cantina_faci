import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'core/sessao.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
      'Passe --dart-define=SUPABASE_URL e SUPABASE_ANON_KEY.');

  await initializeDateFormatting('pt_BR');
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  // Sessão persistida de execução anterior: recarrega o perfil de acesso.
  if (Supabase.instance.client.auth.currentSession != null) {
    try {
      Sessao.perfil = await AuthService().resolveAccess();
    } catch (e) {
      debugPrint('[main] Falha ao carregar perfil da sessão: $e');
    }
  }

  runApp(const CantinaFacilApp());
}

class CantinaFacilApp extends StatelessWidget {
  const CantinaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cantina Fácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
