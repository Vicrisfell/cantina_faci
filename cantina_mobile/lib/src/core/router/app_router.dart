import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/operador/data/operador_repository.dart';
import '../../features/operador/domain/operador_models.dart';
import '../../features/operador/presentation/operador_shell.dart';
import '../../features/responsavel/presentation/responsavel_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authUserIdProvider, (previous, next) => refresh.value++);
  ref.listen(perfilAcessoProvider, (previous, next) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      const transitorias = ['/', '/login', '/carregando', '/erro-sessao'];

      final session = ref.read(authUserIdProvider);
      if (session.isLoading) {
        return path == '/carregando' ? null : '/carregando';
      }
      if (session.hasError) {
        return path == '/erro-sessao' ? null : '/erro-sessao';
      }
      if (session.value == null) {
        return path == '/login' ? null : '/login';
      }

      final acesso = ref.read(perfilAcessoProvider);
      if (acesso.isLoading) {
        return path == '/carregando' ? null : '/carregando';
      }
      if (acesso.hasError) {
        return path == '/erro-sessao' ? null : '/erro-sessao';
      }

      final alvo = acesso.value == PerfilAcesso.operador
          ? '/operador'
          : '/responsavel';
      if (transitorias.contains(path)) return alvo;
      if ((path == '/operador' || path == '/responsavel') && path != alvo) {
        return alvo;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _LoadingPage()),
      GoRoute(
        path: '/carregando',
        builder: (context, state) => const _LoadingPage(),
      ),
      GoRoute(
        path: '/erro-sessao',
        builder: (context, state) => const _SessionErrorPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/responsavel',
        builder: (context, state) => const _ResponsavelRoute(),
      ),
      GoRoute(
        path: '/operador',
        builder: (context, state) => const _OperadorRoute(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}

class _ResponsavelRoute extends ConsumerWidget {
  const _ResponsavelRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authUserIdProvider);
    if (session.isLoading || session.hasError || session.value == null) {
      return const _LoadingPage();
    }
    return const ResponsavelShell();
  }
}

class _OperadorRoute extends ConsumerWidget {
  const _OperadorRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(perfilAcessoProvider);
    if (acesso.isLoading || acesso.hasError) return const _LoadingPage();
    return const OperadorShell();
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _SessionErrorPage extends ConsumerWidget {
  const _SessionErrorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível verificar a sessão.'),
            TextButton(
              onPressed: () {
                ref.invalidate(authUserIdProvider);
                ref.invalidate(perfilAcessoProvider);
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
