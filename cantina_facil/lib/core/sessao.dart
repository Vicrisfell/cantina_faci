import '../models/access_profile.dart';

/// Perfil de acesso do usuário logado, mantido em memória durante a sessão.
class Sessao {
  Sessao._();
  static AccessProfile? perfil;
}
