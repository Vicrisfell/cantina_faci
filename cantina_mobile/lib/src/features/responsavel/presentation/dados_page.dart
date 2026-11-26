import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/responsavel_repository.dart';
import '../domain/responsavel_models.dart';
import 'responsavel_ui_state.dart';
import 'widgets/responsavel_widgets.dart';

class DadosPage extends ConsumerWidget {
  const DadosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return carregamentoOuErro(
      ref.watch(responsavelDataProvider),
      ref,
      (dados) => _DadosConteudo(dados: dados),
    );
  }
}

class _DadosConteudo extends ConsumerWidget {
  const _DadosConteudo({required this.dados});

  final ResponsavelData dados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = dados.perfil;
    final filhos = dados.filhos;
    final selecionadoId = ref.watch(selectedChildIdProvider);
    final Filho? filhoRecarga = filhos.isEmpty
        ? null
        : filhos.firstWhere(
            (f) => f.id == selecionadoId,
            orElse: () => filhos.first,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const CantinaHeader(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => ref.read(shellIndexProvider.notifier).irPara(0),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Início'),
            style: TextButton.styleFrom(foregroundColor: CantinaColors.vinho),
          ),
        ),
        const ResponsavelCabecalhoTitulo(
          titulo: 'Dados cadastrais',
          subtitulo: 'Seus dados e os de seus filhos cadastrados.',
        ),
        const SizedBox(height: 16),
        _Secao(
          icone: Icons.person_outline,
          titulo: 'Dados do responsável',
          campos: [
            _Campo('Responsável', p.nome),
            _Campo('CPF', formatCpf(p.cpf)),
            _Campo('Telefone principal (WhatsApp)', formatTelefone(p.celular)),
            _Campo('Contato alternativo', textoOuPadrao(p.nomeAlternativo)),
            _Campo('Telefone alternativo', formatTelefone(p.celularAlternativo)),
          ],
        ),
        const SizedBox(height: 16),
        _Secao(
          icone: Icons.location_on_outlined,
          titulo: 'Endereço',
          campos: [
            _Campo(
              'Logradouro',
              p.endereco == null
                  ? 'Não informado'
                  : '${p.endereco}${p.numEnd == null ? '' : ', ${p.numEnd}'}',
            ),
            _Campo('Bairro', textoOuPadrao(p.bairro)),
            _Campo('CEP', textoOuPadrao(p.cep)),
            Row(
              children: [
                Expanded(child: _Campo('Cidade', textoOuPadrao(p.cidade))),
                const SizedBox(width: 12),
                Expanded(child: _Campo('Estado', textoOuPadrao(p.estado))),
              ],
            ),
            _Campo('Complemento', textoOuPadrao(p.complemento)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Dependentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              '${filhos.length} ${filhos.length == 1 ? 'dependente' : 'dependentes'}',
              style: const TextStyle(fontSize: 13, color: CantinaColors.cinza),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filhos.isEmpty)
          const CardBranco(child: Text('Nenhum dependente vinculado.'))
        else
          for (final f in filhos)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardBranco(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarInicial(inicial: f.inicial, tamanho: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        StatusBadge(filho: f),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Campo('Instituição', f.instituicao),
                    _Campo('Ano / Turma', f.serie),
                  ],
                ),
              ),
            ),
        if (filhoRecarga != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: CantinaColors.vinho,
                side: const BorderSide(color: CantinaColors.vinho),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => mostrarRecarga(context, filhoRecarga),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Solicitar recarga'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => abrirWhatsApp(
              context,
              'Olá! Preciso de ajuda com meus dados na Cantina Fácil.',
            ),
            style: TextButton.styleFrom(foregroundColor: CantinaColors.vinho),
            child: const Text('Precisa de ajuda? Fale com o admin'),
          ),
        ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.icone,
    required this.titulo,
    required this.campos,
  });

  final IconData icone;
  final String titulo;
  final List<Widget> campos;

  @override
  Widget build(BuildContext context) {
    return CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: CantinaColors.vinho, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined, color: CantinaColors.vinho),
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Para alterar seus dados, fale com a cantina.',
                      ),
                    ),
                  ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...campos,
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CantinaColors.campoCreme,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(valor),
          ),
        ],
      ),
    );
  }
}
