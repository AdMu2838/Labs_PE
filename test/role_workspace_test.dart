import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/app/app.dart';
import 'package:unsa_laboratorios/core/data/demo_lab_repository.dart';
import 'package:unsa_laboratorios/core/data/providers.dart';
import 'package:unsa_laboratorios/features/auth/domain/session.dart';
import 'package:unsa_laboratorios/features/auth/presentation/auth_controller.dart';
import 'package:unsa_laboratorios/shared/widgets/ui.dart';

void main() {
  for (final role in AppRole.values) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('Inicio y navegación de ${role.name} a $width px', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const ProviderScope(child: LabApp()));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
        container.read(demoSessionProvider.notifier).enter(role);
        await tester.pumpAndSettle();
        final action = switch (role) {
          AppRole.student => 'Explorar laboratorios',
          AppRole.teacher => 'Consultar mis grupos',
          AppRole.coordinator => 'Atender solicitudes',
          AppRole.admin => 'Gestionar usuarios',
        };
        expect(find.text(action), findsWidgets);
        if (role != AppRole.student) expect(find.text('Elige tu grupo.\nDale forma a tu horario.'), findsNothing);
        await tester.ensureVisible(find.text(action).last);
        await tester.tap(find.text(action).last);
        await tester.pumpAndSettle();
        if (role == AppRole.admin) expect(find.text('Cambiar rol ▾'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('El resumen respeta matrículas personales y grupos asignados', (tester) async {
    final repository = DemoLabRepository();
    repository.data['groups']![1]['teacher_id'] = 'otro-docente';
    repository.data['enrollments'] = [
      {'id': 'e1', 'student_id': 'demo', 'group_id': 'g0', 'status': 'active'},
      {'id': 'e2', 'student_id': 'otro-estudiante', 'group_id': 'g1', 'status': 'active'},
    ];
    await tester.pumpWidget(ProviderScope(overrides: [labRepositoryProvider.overrideWithValue(repository)], child: const LabApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
    container.read(demoSessionProvider.notifier).enter(AppRole.student);
    await tester.pumpAndSettle();
    final personalStat = find.ancestor(of: find.text('Mis matrículas'), matching: find.byType(Panel));
    expect(find.descendant(of: personalStat, matching: find.text('1')), findsOneWidget);
    container.read(demoSessionProvider.notifier).enter(AppRole.teacher);
    await tester.pumpAndSettle();
    final teacherStat = find.ancestor(of: find.text('Matrículas en mis grupos'), matching: find.byType(Panel));
    expect(find.descendant(of: teacherStat, matching: find.text('1')), findsOneWidget);
    expect(find.text('Introducción al Desarrollo Web · Grupo B'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opciones en español guardan los códigos originales', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LabApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
    container.read(demoSessionProvider.notifier).enter(AppRole.student);
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/requests');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('schedule'), findsNothing);
    await tester.tap(find.text('Horario').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Asunto'), 'Consulta de horario');
    await tester.enterText(find.widgetWithText(TextFormField, 'Describe tu solicitud'), 'Necesito revisar mi horario.');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final repository = container.read(labRepositoryProvider) as DemoLabRepository;
    expect(repository.data['requests']!.single['type'], 'schedule');
    expect(tester.takeException(), isNull);
  });
}
