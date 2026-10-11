class LabSession {
  const LabSession(this.day, this.start, this.end);
  final int day;
  final String start, end;
  static const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  String get label => '${days[day - 1]} ${start.substring(0, 5)} – ${end.substring(0, 5)}';
  bool overlaps(LabSession other) => day == other.day && start.compareTo(other.end) < 0 && end.compareTo(other.start) > 0;
  factory LabSession.fromJson(Map<String, dynamic> row) => LabSession(row['day'], row['start_time'], row['end_time']);
}

class LabGroup {
  LabGroup.fromJson(Map<String, dynamic> row)
    : id = row['id'], courseId = row['course_id'], course = row['course_name'], code = row['course_code'],
      name = row['name'], periodId = row['period_id'], period = row['period_name'],
      room = row['room_name'] ?? 'Por asignar', teacher = row['teacher_name'] ?? 'Por asignar', teacherId = row['teacher_id'],
      semester = row['semester'], capacity = row['capacity'], occupied = row['occupied'] ?? 0,
      sessions = ((row['sessions'] ?? []) as List).map((e) => LabSession.fromJson(Map<String, dynamic>.from(e))).toList();
  final String id, courseId, course, code, name, periodId, period, room, teacher;
  final String? teacherId;
  final int semester, capacity, occupied;
  final List<LabSession> sessions;
  int get available => capacity - occupied;
}
