import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/widgets/cantina_logo.dart';
import 'historico_vendas_page.dart';
import 'operador_drawer.dart';
import 'operador_state.dart';
import 'venda_cliente_page.dart';
import 'venda_conferir_page.dart';
import 'venda_pagamento_page.dart';

class OperadorShell extends ConsumerWidget {
  const OperadorShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(operadorTabProvider);
    return Scaffold(
      backgroundColor: CantinaColors.creme,
      appBar: AppBar(
        backgroundColor: CantinaColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CantinaLogo(tamanho: 28),
            SizedBox(width: 8),
            Text(
              'Cantina Fácil',
              style: TextStyle(
                color: CantinaColors.vinho,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu, color: CantinaColors.vinho),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const OperadorDrawer(),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: const [
            VendaClientePage(),
            VendaConferirPage(),
            VendaPagamentoPage(),
            HistoricoVendasPage(),
          ],
        ),
      ),
      bottomNavigationBar: _BarraOperador(
        tab: tab,
        onTap: (i) => ref.read(operadorTabProvider.notifier).irPara(i),
      ),
    );
  }
}

class _BarraOperador extends StatelessWidget {
  const _BarraOperador({required this.tab, required this.onTap});

  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final historico = tab == 3;
    final itens = historico
        ? const [
            (Icons.add, 'Nova venda', 0),
            (Icons.schedule, 'Histórico', 3),
          ]
        : const [
            (Icons.storefront_outlined, 'Cliente e produtos', 0),
            (Icons.receipt_long_outlined, 'Conferir itens', 1),
            (Icons.payments_outlined, 'Finalizar', 2),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: CantinaColors.branco,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final it in itens)
                Expanded(
                  child: _ItemBarra(
                    icone: it.$1,
                    rotulo: it.$2,
                    ativo: tab == it.$3,
                    onTap: () => onTap(it.$3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemBarra extends StatelessWidget {
  const _ItemBarra({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? CantinaColors.vinho : CantinaColors.cinza;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? CantinaColors.bege : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? CantinaColors.vinho : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 22, color: cor),
            const SizedBox(height: 2),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: ativo ? FontWeight.w800 : FontWeight.w500,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
