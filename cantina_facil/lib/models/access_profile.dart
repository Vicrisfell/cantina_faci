enum OrgRole { owner, admin }
enum UnitRole { manager, cashier, inventory }

class AccessProfile {
  final String userId;
  final String? orgId;
  final OrgRole? orgRole;
  final Map<String, UnitRole> units; // id_unid -> funcao

  const AccessProfile({
    required this.userId,
    this.orgId,
    this.orgRole,
    this.units = const {},
  });

  /// Acesso ao painel: admin/owner da organização ou gerente de alguma unidade.
  bool get canAccessAdminPanel =>
      orgRole != null || units.values.any((r) => r == UnitRole.manager);

  bool get isOrgAdmin => orgRole != null;

  List<String> get managedUnitIds =>
      units.entries.where((e) => e.value == UnitRole.manager).map((e) => e.key).toList();
}
