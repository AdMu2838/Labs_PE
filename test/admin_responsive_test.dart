import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/app/app.dart';
import 'package:unsa_laboratorios/features/auth/domain/session.dart';
import 'package:unsa_laboratorios/features/auth/presentation/auth_controller.dart';

void main() {
  testWidgets('Docente: horario y grupos sin matrícula, con texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: LabApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
    container.read(demoSessionProvider.notifier).enter(AppRole.teacher);
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/schedule');
    await tester.pumpAndSettle();
    expect(find.text('Introducción al Desarrollo de Software'), findsOneWidget);
    container.read(routerProvider).go('/enrollments');
    await tester.pumpAndSettle();
    expect(find.text('Mis grupos asignados'), findsOneWidget);
  });
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets('Módulos administrativos y formulario a $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: LabApp()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
      container.read(demoSessionProvider.notifier).enter(AppRole.admin);
      await tester.pumpAndSettle();
      for (final route in ['/curriculum', '/requests', '/notifications', '/profile', '/reports', '/admin']) {
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Crear registro'));
      await tester.tap(find.text('Crear registro'));
      await tester.pumpAndSettle();
      expect(find.text('Periodo (ej. 2026-B)'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Grupos'));
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear registro'));
      await tester.tap(find.text('Crear registro'));
      await tester.pumpAndSettle();
      expect(find.text('Asignatura'), findsOneWidget);
    });
  }
}
