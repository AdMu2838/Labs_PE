import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/core/data/demo_lab_repository.dart';
import 'package:unsa_laboratorios/features/enrollment/domain/lab_group.dart';

void main() {
  test('Los horarios contiguos no se cruzan, los superpuestos sí', () {
    const first = LabSession(1, '08:00', '10:00');
    expect(first.overlaps(const LabSession(1, '10:00', '12:00')), isFalse);
    expect(first.overlaps(const LabSession(1, '09:00', '11:00')), isTrue);
    expect(first.overlaps(const LabSession(2, '08:00', '10:00')), isFalse);
  });
  test('Matrícula duplicada se rechaza y cambio fallido conserva el origen', () async {
    final repo = DemoLabRepository();
    await repo.enroll('g0');
    await expectLater(repo.enroll('g0'), throwsException);
    final id = (await repo.list('enrollments')).single['id'];
    await repo.save('groups', {'id': 'replacement', 'course_id': 'c0', 'period_id': 'p1', 'room_id': 'r0', 'name': 'C', 'capacity': 1, 'active': true});
    await repo.save('sessions', {'group_id': 'replacement', 'day': 2, 'start_time': '08:00', 'end_time': '10:00'});
    await repo.enroll('g1');
    await expectLater(repo.enroll('replacement', replacing: id), throwsException);
    expect((await repo.list('enrollments')).firstWhere((e) => e['id'] == id)['status'], 'active');
  });
}
