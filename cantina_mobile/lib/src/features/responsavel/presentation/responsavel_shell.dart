import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import 'dados_page.dart';
import 'historico_page.dart';
import 'home_page.dart';
import 'responsavel_ui_state.dart';

class ResponsavelShell extends ConsumerWidget {
  const ResponsavelShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    return Scaffold(
      backgroundColor: CantinaColors.creme,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: const [HomePage(), DadosPage(), HistoricoPage()],
        ),
      ),
      bottomNavigationBar: _BarraNavegacao(
        index: index,
        onTap: (i) => ref.read(shellIndexProvider.notifier).irPara(i),
      ),
    );
  }
}

class _Aba {
  const _Aba(this.icone, this.iconeAtivo, this.rotulo);

  final IconData icone;
  final IconData iconeAtivo;
  final String rotulo;
}

const _abas = <_Aba>[
  _Aba(Icons.home_outlined, Icons.home, 'Home'),
  _Aba(Icons.person_outline, Icons.person, 'Dados'),
  _Aba(Icons.schedule, Icons.schedule, 'Histórico de compras'),
];

class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CantinaColors.branco,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              for (final e in _abas.indexed)
                Expanded(
                  child: _ItemNavegacao(
                    aba: e.$2,
                    ativo: e.$1 == index,
                    onTap: () => onTap(e.$1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    required this.aba,
    required this.ativo,
    required this.onTap,
  });

  final _Aba aba;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: ativo ? CantinaColors.vinho : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ativo ? aba.iconeAtivo : aba.icone,
              size: 22,
              color: ativo ? Colors.white : CantinaColors.cinza,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            aba.rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: ativo ? FontWeight.w800 : FontWeight.w500,
              color: ativo ? CantinaColors.vinho : CantinaColors.cinza,
            ),
          ),
        ],
      ),
    );
  }
}
