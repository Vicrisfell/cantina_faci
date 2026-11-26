import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/cpf_utils.dart';
import '../../../core/widgets/cantina_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _lembrarDeMim = false;
  bool _carregando = false;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final email = loginToAuthEmail(_loginController.text);
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _senhaController.text,
      );
    } on FormatException {
      _mostrar('Informe um CPF com 11 dígitos ou um e-mail válido.');
    } on AuthRetryableFetchException {
      _mostrar('Sem conexão. Verifique sua internet e tente novamente.');
    } on AuthException {
      _mostrar('CPF/e-mail ou senha inválidos.');
    } catch (_) {
      _mostrar('Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _esqueciSenha() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: const Text(
          'Para redefinir sua senha, procure a administração da cantina ou da escola.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracao({
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A8F96)),
      prefixIcon: Icon(icone, color: const Color(0xFF6E747B)),
      suffixIcon: sufixo,
      filled: true,
      fillColor: CantinaColors.campoLogin,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: borda(const Color(0xFFD5DBE1)),
      enabledBorder: borda(const Color(0xFFD5DBE1)),
      focusedBorder: borda(CantinaColors.vinho, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rotulo = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    return Scaffold(
      backgroundColor: CantinaColors.creme,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: CantinaLogo(tamanho: 150)),
                    const SizedBox(height: 16),
                    const Text(
                      'Cantina Fácil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: CantinaColors.vinho,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Acesse sua conta para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: CantinaColors.ink),
                    ),
                    const SizedBox(height: 28),
                    const Text('CPF ou E-mail', style: rotulo),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _loginController,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: const [LoginInputFormatter()],
                      autofillHints: const [AutofillHints.username],
                      decoration: _decoracao(
                        hint: 'Digite seu CPF ou e-mail',
                        icone: Icons.person_outline,
                      ),
                      validator: (valor) {
                        final t = (valor ?? '').trim();
                        if (t.isEmpty) return 'Informe seu CPF ou e-mail.';
                        if (t.contains('@')) {
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                              ? null
                              : 'Informe um e-mail válido.';
                        }
                        final digitos = t.replaceAll(RegExp(r'\D'), '');
                        return digitos.length == 11
                            ? null
                            : 'Informe um CPF com 11 dígitos.';
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Senha', style: rotulo),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: _decoracao(
                        hint: 'Digite sua senha',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: (valor) => (valor == null || valor.isEmpty)
                          ? 'Informe sua senha.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: CantinaColors.vinho,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => _lembrarDeMim = !_lembrarDeMim),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _lembrarDeMim,
                                activeColor: CantinaColors.vinho,
                                onChanged: (v) =>
                                    setState(() => _lembrarDeMim = v ?? false),
                              ),
                              const Text('Lembrar de mim'),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _esqueciSenha,
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(color: CantinaColors.vinho),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
