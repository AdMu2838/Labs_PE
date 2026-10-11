import 'dart:async';
import '../domain/lab_repository.dart';

/// Datos ficticios para explorar la interfaz sin credenciales. No persisten.
class DemoLabRepository implements LabRepository {
  DemoLabRepository() {
    final names = ['Introducción al Desarrollo de Software', 'Introducción al Desarrollo Web',
      'Estructura de Datos y Algoritmos', 'Desarrollo de Aplicaciones Web', 'Base de Datos', 'Inteligencia Artificial',
      'Sistemas Operativos', 'Taller de DevOps'];
    final codes = ['2501103', '2501210', '2502116', '2502117', '2503242', '2504146', '2503239', '2505287'];
    final semesters = [1, 2, 3, 3, 6, 7, 6, 10];
    data['courses'] = List.generate(names.length, (i) => {'id': 'c$i', 'code': codes[i], 'name': names[i], 'semester': semesters[i], 'credits': 4, 'lab_hours': 2, 'plan_id': 'plan2025', 'elective': false});
    data['plans'] = [{'id': 'plan2025', 'name': 'Plan de estudios 2025', 'year': 2025}];
    data['periods'] = [{'id': 'p1', 'name': '2026-B · Demostración', 'status': 'open', 'enrollment_start': '2026-01-01T00:00:00Z', 'enrollment_end': '2027-12-31T23:59:00Z', 'withdrawal_end': '2027-12-31T23:59:00Z', 'require_eligibility': false}];
    data['rooms'] = List.generate(3, (i) => {'id': 'r$i', 'name': 'Laboratorio ${i + 1} · Demo', 'capacity': 30, 'location': 'Pabellón Sistemas', 'equipment': 'PCs, proyector, red', 'active': true});
    data['profiles'] = [{'id': 'demo', 'full_name': 'Alex Agustino', 'email': 'demo@unsa.edu.pe', 'role': 'student', 'cui': '20250001', 'active': true, 'plan_id': 'plan2025', 'approved_credits': 0}];
    data['groups'] = List.generate(names.length, (i) => {'id': 'g$i', 'course_id': 'c$i', 'period_id': 'p1', 'room_id': 'r${i % 3}', 'teacher_id': 'demo', 'name': 'Grupo ${i.isEven ? 'A' : 'B'}', 'capacity': 30, 'active': true});
    data['sessions'] = List.generate(names.length, (i) => {'id': 's$i', 'group_id': 'g$i', 'day': i % 5 + 1, 'start_time': '${i < 5 ? '08' : '14'}:00', 'end_time': '${i < 5 ? '10' : '16'}:00'});
    data['enrollments'] = [];
    data['waitlist'] = [];
    data['requests'] = [];
    data['academic_records'] = [];
    data['eligibilities'] = [];
    data['notifications'] = [{'id': 'n1', 'student_id': 'demo', 'title': '¡Bienvenido a UNSA · LAB!', 'body': 'Esta es una demostración. Configura Supabase para usar información real.', 'is_read': false, 'created_at': DateTime.now().toIso8601String()}];
    data['announcements'] = [{'id': 'a1', 'title': 'Tu matrícula, en un solo lugar', 'body': 'Revisa los horarios y las vacantes antes de elegir tu grupo. Los ambientes y docentes de esta vista son ficticios.', 'created_at': DateTime.now().toIso8601String()}];
    data['audit_logs'] = [];
    data['prerequisites'] = [];
  }
  final Map<String, List<Record>> data = {};
  final _events = StreamController<void>.broadcast();
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  @override
  Stream<void> get changes => _events.stream;
  @override
  Future<List<Record>> list(String table) async {
    if (table == 'groups_catalog') {
      return data['groups']!.map((g) {
        final c = data['courses']!.firstWhere((c) => c['id'] == g['course_id']);
        final p = data['periods']!.firstWhere((p) => p['id'] == g['period_id']);
        final r = data['rooms']!.firstWhere((r) => r['id'] == g['room_id'], orElse: () => {'name': 'Por asignar'});
        return {...g, 'course_name': c['name'], 'course_code': c['code'], 'semester': c['semester'],
          'period_name': p['name'], 'room_name': r['name'], 'teacher_name': 'Docente de demostración',
          'occupied': (int.tryParse(g['id'].toString().replaceAll('g', '')) ?? 0) * 3 + data['enrollments']!.where((e) => e['group_id'] == g['id'] && e['status'] == 'active').length,
          'sessions': data['sessions']!.where((s) => s['group_id'] == g['id']).toList()};
      }).toList();
    }
    return data[table]?.map((r) => {...r}).toList() ?? [];
  }
  @override
  Future<void> save(String table, Record row) async {
    final rows = data.putIfAbsent(table, () => []);
    final previous = rows.where((r) => r['id'] == row['id'] && row['id'] != null).firstOrNull ?? {};
    rows.removeWhere((r) => r['id'] == row['id'] && row['id'] != null);
    rows.add({...previous, ...row, 'id': row['id'] ?? _id(), 'created_at': previous['created_at'] ?? row['created_at'] ?? DateTime.now().toIso8601String(),
      if (table == 'requests') ...{'student_id': 'demo', 'status': 'pending'}});
    _events.add(null);
  }
  @override
  Future<void> remove(String table, String id) async { data[table]?.removeWhere((r) => r['id'] == id); _events.add(null); }
  @override
  Future<String> enroll(String groupId, {bool waitlist = false, String? replacing}) async {
    final groups = await list('groups_catalog');
    final g = groups.firstWhere((g) => g['id'] == groupId);
    final active = data['enrollments']!.where((e) => e['status'] == 'active' && e['id'] != replacing).toList();
    if (active.any((e) => e['course_id'] == g['course_id'] && e['period_id'] == g['period_id'])) { throw Exception('Ya tienes matrícula en este curso.'); }
    for (final e in active) {
      final a = data['sessions']!.where((s) => s['group_id'] == e['group_id']);
      final b = data['sessions']!.where((s) => s['group_id'] == groupId);
      if (a.any((s) => b.any((t) => s['day'] == t['day'] && s['start_time'].compareTo(t['end_time']) < 0 && s['end_time'].compareTo(t['start_time']) > 0))) {
        throw Exception('El grupo se cruza con tu horario actual.');
      }
    }
    if (g['occupied'] >= g['capacity']) {
      if (!waitlist) throw Exception('El grupo está lleno.');
      if (data['waitlist']!.any((w) => w['group_id'] == groupId)) throw Exception('Ya estás en esta lista de espera.');
      await save('waitlist', {'group_id': groupId, 'student_id': 'demo', 'status': 'waiting'});
      return 'waiting';
    }
    if (replacing != null) { data['enrollments']!.firstWhere((e) => e['id'] == replacing)['status'] = 'withdrawn'; }
    await save('enrollments', {'student_id': 'demo', 'group_id': groupId, 'course_id': g['course_id'], 'period_id': g['period_id'], 'status': 'active'});
    return 'enrolled';
  }
  @override
  Future<void> withdraw(String enrollmentId) async { data['enrollments']!.firstWhere((e) => e['id'] == enrollmentId)['status'] = 'withdrawn'; _events.add(null); }
  @override
  Future<void> leaveWaitlist(String id) => remove('waitlist', id);
  @override
  Future<void> resolveRequest(String id, String status, String response) async {
    final row = data['requests']!.firstWhere((r) => r['id'] == id); row['status'] = status; row['response'] = response; _events.add(null);
  }
  @override
  Future<void> setRole(String id, String role) async { data['profiles']!.firstWhere((r) => r['id'] == id)['role'] = role; _events.add(null); }
  @override
  Future<void> markRead(String id) async { data['notifications']!.firstWhere((r) => r['id'] == id)['is_read'] = true; _events.add(null); }
  @override
  Future<void> importAcademic(List<Record> rows, String kind) async { for (final row in rows) { await save(kind, row); } }
}
