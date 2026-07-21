class FamilyPermissionService {
  const FamilyPermissionService();

  bool canManageMember({
    required String? actorNit,
    required String? targetNit,
  }) {
    final actor = actorNit?.trim() ?? '';
    final target = targetNit?.trim() ?? '';
    if (actor.isEmpty || target.isEmpty) {
      return false;
    }
    return target == actor || target.startsWith('$actor.');
  }

  bool canEditFamilyMember({
    required String? actorNit,
    required String? targetNit,
  }) {
    final actor = actorNit?.trim() ?? '';
    final target = targetNit?.trim() ?? '';
    return target != actor &&
        canManageMember(actorNit: actor, targetNit: target);
  }

  bool canDeleteFamilyMember({
    required String? actorNit,
    required String? targetNit,
  }) {
    return canEditFamilyMember(actorNit: actorNit, targetNit: targetNit);
  }
}
