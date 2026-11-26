import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/cantina_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cantina_logo.dart';
import '../../data/responsavel_repository.dart';
import '../../domain/responsavel_models.dart';

/// Número da cantina, configurável via --dart-define=CANTINA_WHATSAPP=55...
const cantinaWhatsapp =
    String.fromEnvironment('CANTINA_WHATSAPP', defaultValue: '5511999999999');

Future<void> abrirWhatsApp(BuildContext context, String mensagem) async {
  final uri = Uri.parse(
    'https://wa.me/$cantinaWhatsapp?text=${Uri.encodeComponent(mensagem)}',
  );
  var abriu = false;
  try {
    abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    abriu = false;
  }
  if (!abriu && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
    );
  }
}

Future<void> mostrarRecarga(BuildContext context, Filho filho) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CantinaColors.branco,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecargaSheet(filho: filho),
  );
}

class _RecargaSheet extends StatefulWidget {
  const _RecargaSheet({required this.filho});

  final Filho filho;

  @override
  State<_RecargaSheet> createState() => _RecargaSheetState();
}

class _RecargaSheetState extends State<_RecargaSheet> {
  static const _valores = [10.0, 20.0, 30.0, 50.0];
  double _valor = 20;
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    await abrirWhatsApp(
      context,
      'Olá! Quero recarregar ${formatReais(_valor)} no saldo de '
      '${widget.filho.nome} na Cantina Fácil.',
    );
    if (mounted) {
      setState(() => _enviando = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recarregar saldo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: CantinaColors.ink,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo de ${widget.filho.nome}: ${formatReais(widget.filho.saldo)}',
            style: const TextStyle(color: CantinaColors.cinza),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final v in _valores)
                ChoiceChip(
                  label: Text(formatReais(v)),
                  selected: _valor == v,
                  selectedColor: CantinaColors.vinho,
                  labelStyle: TextStyle(
                    color: _valor == v ? Colors.white : CantinaColors.vinho,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _valor = v),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'A cantina confirma o pagamento e libera o valor no saldo.',
            style: TextStyle(fontSize: 13, color: CantinaColors.cinza),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: estiloBotaoVinho(),
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Enviar pedido pelo WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle estiloBotaoVinho() => FilledButton.styleFrom(
      backgroundColor: CantinaColors.vinho,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

class CardBranco extends StatelessWidget {
  const CardBranco({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CantinaColors.branco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.filho});

  final Filho filho;

  @override
  Widget build(BuildContext context) {
    final baixo = filho.saldoBaixo;
    final Color fundo;
    final Color texto;
    final String rotulo;
    if (baixo) {
      fundo = CantinaColors.salmao;
      texto = CantinaColors.vinho;
      rotulo = 'Saldo baixo';
    } else if (filho.ativo) {
      fundo = CantinaColors.verdeFundo;
      texto = CantinaColors.verdeTexto;
      rotulo = '• Ativo';
    } else {
      fundo = const Color(0xFFE9E6E3);
      texto = CantinaColors.cinza;
      rotulo = 'Inativo';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rotulo,
        style: TextStyle(
          color: texto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AvatarInicial extends StatelessWidget {
  const AvatarInicial({
    super.key,
    required this.inicial,
    this.selecionado = false,
    this.tamanho = 36,
  });

  final String inicial;
  final bool selecionado;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: tamanho / 2,
      backgroundColor: selecionado ? CantinaColors.vinho : CantinaColors.bege,
      child: Text(
        inicial,
        style: TextStyle(
          color: selecionado ? Colors.white : CantinaColors.vinho,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ErroCarregamento extends StatelessWidget {
  const ErroCarregamento({super.key, required this.onTentar});

  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar seus dados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTentar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class CantinaHeader extends StatelessWidget {
  const CantinaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CantinaLogo(tamanho: 34),
        const SizedBox(width: 8),
        const Text(
          'Cantina Fácil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CantinaColors.vinho,
          ),
        ),
        const Spacer(),
        Material(
          color: CantinaColors.branco,
          borderRadius: BorderRadius.circular(12),
          child: IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, color: CantinaColors.vinho),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ),
      ],
    );
  }
}

class ResponsavelCabecalhoTitulo extends StatelessWidget {
  const ResponsavelCabecalhoTitulo({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: CantinaColors.ink,
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(subtitulo!, style: const TextStyle(color: CantinaColors.cinza)),
        ],
      ],
    );
  }
}

/// Trata carregamento/erro do [responsavelDataProvider] e delega o conteúdo.
Widget carregamentoOuErro(
  AsyncValue<ResponsavelData> async,
  WidgetRef ref,
  Widget Function(ResponsavelData dados) builder,
) {
  return async.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => ErroCarregamento(
      onTentar: () => ref.invalidate(responsavelDataProvider),
    ),
    data: builder,
  );
}
