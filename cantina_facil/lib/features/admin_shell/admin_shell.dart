import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/sessao.dart';
import '../../core/theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _destinos = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/admin/dashboard'),
    (icon: Icons.store_outlined, label: 'Cantinas', route: '/admin/cantinas'),
    (icon: Icons.groups_outlined, label: 'Equipe & Admins', route: '/admin/equipe'),
    (icon: Icons.family_restroom_outlined, label: 'Pais e Alunos', route: '/admin/alunos'),
    (icon: Icons.inventory_2_outlined, label: 'Produtos & Estoque', route: '/admin/produtos'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Vendas & Carteiras', route: '/admin/vendas'),
  ];

  int _indexAtual(String caminho) {
    final i = _destinos.indexWhere((d) => caminho.startsWith(d.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final caminho = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1200,
            backgroundColor: AppColors.branco,
            selectedIndex: _indexAtual(caminho),
            selectedIconTheme: const IconThemeData(color: AppColors.vermelhoToldo),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.vermelhoToldo,
              fontWeight: FontWeight.w700,
            ),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.storefront, size: 40, color: AppColors.bordo),
                  SizedBox(height: 4),
                  Text('Cantina Fácil',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.bordo)),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: IconButton(
                tooltip: 'Sair',
                icon: const Icon(Icons.logout, color: AppColors.bordo),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  Sessao.perfil = null;
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            destinations: [
              for (final d in _destinos)
                NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
            ],
            onDestinationSelected: (i) => context.go(_destinos[i].route),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
