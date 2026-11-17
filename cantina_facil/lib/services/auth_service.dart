import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_profile.dart';

class AuthService {
  SupabaseClient get _db => Supabase.instance.client;

  Future<void> signInWithEmail({required String email, required String password}) =>
      _db.auth.signInWithPassword(email: email.trim().toLowerCase(), password: password);

  Future<void> signOut() => _db.auth.signOut();

  Future<AccessProfile?> resolveAccess() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final orgRows = await _db
          .from('membros_organizacao')
          .select('id_org, funcao')
          .eq('id_usuario', uid)
          .eq('ativo', true)
          .inFilter('funcao', ['owner', 'admin'])
          .limit(1);

      final unitRows = await _db
          .from('membro_unidade')
          .select('id_unid, funcao')
          .eq('id_usuario', uid)
          .eq('ativo', true)
          .inFilter('funcao', ['manager', 'cashier', 'inventory']);

      OrgRole? orgRole;
      String? orgId;
      if (orgRows.isNotEmpty) {
        orgId = orgRows.first['id_org'] as String;
        orgRole = OrgRole.values.byName(orgRows.first['funcao'] as String);
      }

      final units = <String, UnitRole>{
        for (final r in unitRows)
          r['id_unid'] as String: UnitRole.values.byName(r['funcao'] as String),
      };

      return AccessProfile(userId: uid, orgId: orgId, orgRole: orgRole, units: units);
    } on PostgrestException catch (e) {
      debugPrint('[AuthService] PostgrestException em resolveAccess: '
          'code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}');
      rethrow;
    }
  }
}
