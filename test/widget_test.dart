import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/app/app.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(768, 1024), const Size(1440, 900)]) {
    testWidgets('Login y matrícula responsive ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: LabApp()));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido, agustino'), findsOneWidget);
      await tester.ensureVisible(find.text('Explorar como estudiante'));
      await tester.tap(find.text('Explorar como estudiante'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Alex 👋'), findsOneWidget);
      await tester.ensureVisible(find.text('Explorar laboratorios'));
      await tester.tap(find.text('Explorar laboratorios'));
      await tester.pumpAndSettle();
      expect(find.text('Laboratorios disponibles'), findsOneWidget);
      final button = find.text('Matricularme').first;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('¡Matrícula confirmada! Consulta tu horario.'), findsOneWidget);
    });
  }
}
