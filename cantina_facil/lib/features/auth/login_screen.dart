import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;
  bool _lembrar = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(email: _emailCtrl.text, password: _passCtrl.text);
      final acesso = await _auth.resolveAccess();
      if (!mounted) return;
      if (acesso == null || !acesso.canAccessAdminPanel) {
        Sessao.perfil = null;
        await _auth.signOut();
        _snack('Acesso não autorizado para o painel administrativo.', error: true);
        return;
      }
      Sessao.perfil = acesso;
      context.go('/admin/dashboard');
    } on AuthException catch (e) {
      _snack(_mensagemAuth(e), error: true);
    } catch (e) {
      debugPrint('[LoginScreen] Erro ao entrar: $e');
      _snack('Erro de conexão. Tente novamente.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensagemAuth(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login')) return 'E-mail ou senha inválidos.';
    if (msg.contains('email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
    return 'Não foi possível entrar. (${e.message})';
  }

  void _snack(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.vermelhoToldo : AppColors.marrom,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bege,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, size: 96, color: AppColors.bordo),
                  const SizedBox(height: 8),
                  const Text('Cantina Fácil',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.bordo)),
                  const SizedBox(height: 24),
                  const Text('Acesse sua conta para continuar',
                      style: TextStyle(fontSize: 16, color: AppColors.marrom)),
                  const SizedBox(height: 24),
                  _label('E-mail'),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Senha'),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Digite sua senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    onFieldSubmitted: (_) => _entrar(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _lembrar,
                        onChanged: (v) => setState(() => _lembrar = v ?? false),
                      ),
                      const Text('Lembrar de mim', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _snack('Recuperação de senha: em breve.'),
                        child: const Text('Esqueci minha senha', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _entrar,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}
