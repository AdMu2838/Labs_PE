enum AppRole { student, teacher, coordinator, admin }

class AppSession {
  const AppSession({required this.id, required this.name, required this.email, required this.role, this.cui = ''});
  final String id, name, email, cui;
  final AppRole role;
  bool get manages => role == AppRole.admin || role == AppRole.coordinator;
  String get roleLabel => switch (role) {
    AppRole.student => 'Estudiante', AppRole.teacher => 'Docente',
    AppRole.coordinator => 'Coordinación', AppRole.admin => 'Administrador',
  };
  factory AppSession.fromJson(Map<String, dynamic> row) => AppSession(
    id: row['id'], name: row['full_name'] ?? '', email: row['email'] ?? '', cui: row['cui'] ?? '',
    role: AppRole.values.byName(row['role'] ?? 'student'));
}
