import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/responsavel_repository.dart';
import '../domain/responsavel_models.dart';
import 'responsavel_ui_state.dart';
import 'widgets/responsavel_widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return carregamentoOuErro(
      ref.watch(responsavelDataProvider),
      ref,
      (dados) => _HomeConteudo(dados: dados),
    );
  }
}

class _HomeConteudo extends ConsumerWidget {
  const _HomeConteudo({required this.dados});

  final ResponsavelData dados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filhos = dados.filhos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const CantinaHeader(),
        const SizedBox(height: 20),
        Text(
          'Olá, ${dados.perfil.nome}!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: CantinaColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        _CardInformacoes(dados: dados),
        const SizedBox(height: 20),
        if (filhos.isEmpty)
          const CardBranco(
            child: Text(
              'Nenhum aluno vinculado ainda. Procure a cantina para '
              'vincular seus filhos.',
            ),
          )
        else
          ..._secaoFilhos(context, ref),
      ],
    );
  }

  List<Widget> _secaoFilhos(BuildContext context, WidgetRef ref) {
    final selecionadoId = ref.watch(selectedChildIdProvider);
    final filho = dados.filhos.firstWhere(
      (f) => f.id == selecionadoId,
      orElse: () => dados.filhos.first,
    );
    final compras = dados.movimentos
        .where((m) => m.alunoId == filho.id && m.isCompra)
        .take(3)
        .toList();
    final outrosBaixos = dados.filhos.where(
      (f) => f.id != filho.id && f.saldoBaixo,
    );

    return [
      const Text(
        'Meus filhos',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 2),
      const Text(
        'Selecione para acompanhar o crédito.',
        style: TextStyle(fontSize: 13, color: CantinaColors.cinza),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dados.filhos.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final f = dados.filhos[i];
            return _ChipFilho(
              filho: f,
              selecionado: f.id == filho.id,
              onTap: () =>
                  ref.read(selectedChildIdProvider.notifier).selecionar(f.id),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      _CardSaldo(filho: filho),
      for (final f in outrosBaixos) ...[
        const SizedBox(height: 12),
        _AlertaSaldo(filho: f),
      ],
      const SizedBox(height: 24),
      Row(
        children: [
          const Text(
            'Compras recentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => ref.read(shellIndexProvider.notifier).irPara(2),
            child: const Text('Ver tudo →'),
          ),
        ],
      ),
      if (compras.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Nenhuma compra registrada ainda.',
            style: TextStyle(color: CantinaColors.cinza),
          ),
        )
      else
        for (final m in compras)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CompraTile(movimento: m, filho: filho),
          ),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: () => abrirWhatsApp(
            context,
            'Olá! Preciso de ajuda com a Cantina Fácil.',
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Precisa de ajuda? Fale com a cantina'),
          style: TextButton.styleFrom(foregroundColor: CantinaColors.vinho),
        ),
      ),
    ];
  }
}

class _CardInformacoes extends StatelessWidget {
  const _CardInformacoes({required this.dados});

  final ResponsavelData dados;

  @override
  Widget build(BuildContext context) {
    final desde = dados.vinculoDesde;
    return CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: CantinaColors.vinho, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informações',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              Text(
                'RESPONSÁVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: CantinaColors.cinza.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${dados.filhos.length} filhos cadastrados · '
            '${dados.instituicoesCount} instituições',
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: CantinaColors.cinza),
              const SizedBox(width: 6),
              Text(formatTelefone(dados.perfil.celular)),
              if (desde != null) ...[
                const SizedBox(width: 8),
                Text(
                  formatDesde(desde),
                  style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipFilho extends StatelessWidget {
  const _ChipFilho({
    required this.filho,
    required this.selecionado,
    required this.onTap,
  });

  final Filho filho;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destacarBaixo = filho.saldoBaixo && !selecionado;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 176,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? CantinaColors.bege : CantinaColors.branco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado ? CantinaColors.vinho : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AvatarInicial(inicial: filho.inicial, selecionado: selecionado),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filho.nome.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selecionado
                        ? 'Selecionado'
                        : '${formatReais(filho.saldo)}'
                            '${filho.saldoBaixo ? ' • baixo' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: destacarBaixo
                          ? CantinaColors.vinho
                          : CantinaColors.cinza,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSaldo extends StatelessWidget {
  const _CardSaldo({required this.filho});

  final Filho filho;

  @override
  Widget build(BuildContext context) {
    final progresso = (filho.saldo / metaSaldo).clamp(0.0, 1.0);
    return CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filho.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${filho.instituicao} · ${filho.serie}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CantinaColors.cinza,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(filho: filho),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Saldo disponível',
            style: TextStyle(fontSize: 13, color: CantinaColors.cinza),
          ),
          Text(
            formatReais(filho.saldo),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: CantinaColors.vinho,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              backgroundColor: CantinaColors.trilho,
              color: CantinaColors.vinho,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'R\$ 0',
                style: TextStyle(fontSize: 12, color: CantinaColors.cinza),
              ),
              const Spacer(),
              Text(
                'Meta: ${formatReais(metaSaldo)}',
                style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: estiloBotaoVinho(),
              onPressed: () => mostrarRecarga(context, filho),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Recarregar via WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaSaldo extends StatelessWidget {
  const _AlertaSaldo({required this.filho});

  final Filho filho;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CantinaColors.bege,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: CantinaColors.vinho, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${filho.nome} - ${filho.instituicao} - ${filho.serie} | '
              'Saldo baixo: ${formatReais(filho.saldo)}',
              style: const TextStyle(
                fontSize: 13,
                color: CantinaColors.vinho,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompraTile extends StatelessWidget {
  const _CompraTile({required this.movimento, required this.filho});

  final Movimento movimento;
  final Filho filho;

  @override
  Widget build(BuildContext context) {
    final itens = movimento.venda?.itens ?? const <ItemVenda>[];
    final titulo = itens.isEmpty
        ? 'Compra'
        : itens.length == 1
            ? itens.first.produto
            : '${itens.first.produto} +${itens.length - 1}';
    final quantidade = itens.fold<double>(0, (soma, i) => soma + i.quantidade);

    return CardBranco(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CantinaColors.bege,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lunch_dining, color: CantinaColors.vinho),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filho.nome} · ${filho.instituicao}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDataHora(movimento.criadoEm),
                  style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatReais(movimento.valor.abs()),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: CantinaColors.vinho,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatQuantidade(quantidade),
                style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
