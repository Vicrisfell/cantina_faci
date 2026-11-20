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

  try {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw Exception(
        'As chaves SUPABASE_URL ou SUPABASE_ANON_KEY chegaram vazias no build.\n'
        'URL: "$_supabaseUrl"\n'
        'KEY vazia: ${_supabaseAnonKey.isEmpty}',
      );
    }

    await initializeDateFormatting('pt_BR');
    await Supabase.initialize(
      url: _supabaseUrl.trim(),
      anonKey: _supabaseAnonKey.trim(),
    );

    if (Supabase.instance.client.auth.currentSession != null) {
      try {
        Sessao.perfil = await AuthService().resolveAccess();
      } catch (e) {
        debugPrint('[main] Falha ao carregar perfil da sessão: $e');
      }
    }

    runApp(const CantinaFacilApp());
  } catch (erro, stack) {
    debugPrint('[main] ERRO FATAL: $erro\n$stack');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF5EBD6),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Erro ao iniciar o Cantina Fácil:\n\n$erro',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5E1914),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
