import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/cantina_colors.dart';
import '../data/operador_repository.dart';
import '../domain/operador_models.dart';
import 'operador_state.dart';
import 'operador_utilidades_page.dart';

class OperadorDrawer extends ConsumerWidget {
  const OperadorDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unidades = ref.watch(unidadesProvider).value ?? const <Unidade>[];
    final ativaId = ref.watch(unidadeAtivaIdProvider);
    final nav = Navigator.of(context);

    return Drawer(
      backgroundColor: CantinaColors.creme,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Unidade ativa',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CantinaColors.vinho,
                  fontSize: 16,
                ),
              ),
            ),
            for (final u in unidades)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: u.id == ativaId ? CantinaColors.bege : null,
                leading: const Icon(Icons.storefront_outlined, color: CantinaColors.vinho),
                title: Text(
                  u.nome,
                  style: TextStyle(
                    fontWeight: u.id == ativaId ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                trailing: u.id == ativaId
                    ? const Icon(Icons.check_circle, color: CantinaColors.vinho)
                    : null,
                onTap: () {
                  ref.read(unidadeSelecionadaProvider.notifier).selecionar(u.id);
                  ref.read(vendaProvider.notifier).limpar();
                  ref.invalidate(catalogoProvider);
                  ref.invalidate(historicoVendasProvider);
                  nav.pop();
                },
              ),
            const Divider(height: 24),
            _item(Icons.add_circle_outline, 'Nova venda', () {
              ref.read(operadorTabProvider.notifier).irPara(0);
              nav.pop();
            }),
            _item(Icons.receipt_long_outlined, 'Histórico de vendas', () {
              ref.read(operadorTabProvider.notifier).irPara(3);
              nav.pop();
            }),
            _item(Icons.account_balance_wallet_outlined, 'Recarga de carteira', () {
              nav.pop();
              nav.push(MaterialPageRoute(builder: (_) => const RecargaPage()));
            }),
            _item(Icons.inventory_2_outlined, 'Consulta / ajuste de estoque', () {
              nav.pop();
              nav.push(MaterialPageRoute(builder: (_) => const EstoquePage()));
            }),
            const Divider(height: 24),
            _item(Icons.logout, 'Sair', () {
              Supabase.instance.client.auth.signOut();
              nav.pop();
            }),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icone, String rotulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icone, color: CantinaColors.vinho),
      title: Text(rotulo),
      onTap: onTap,
    );
  }
}
