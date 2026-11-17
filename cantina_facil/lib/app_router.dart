import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/sessao.dart';
import 'features/admin_shell/admin_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final logado = Supabase.instance.client.auth.currentSession != null;
    final naTelaLogin = state.matchedLocation == '/login';

    if (!logado || Sessao.perfil == null) return naTelaLogin ? null : '/login';
    if (naTelaLogin) return '/admin/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/admin/cantinas', builder: (_, __) => const _EmBreve('Cantinas')),
        GoRoute(path: '/admin/equipe', builder: (_, __) => const _EmBreve('Equipe & Admins')),
        GoRoute(path: '/admin/alunos', builder: (_, __) => const _EmBreve('Pais e Alunos')),
        GoRoute(path: '/admin/produtos', builder: (_, __) => const _EmBreve('Produtos & Estoque')),
        GoRoute(path: '/admin/vendas', builder: (_, __) => const _EmBreve('Vendas & Carteiras')),
      ],
    ),
  ],
);

class _EmBreve extends StatelessWidget {
  const _EmBreve(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Center(child: Text('$titulo: em breve'));
}
