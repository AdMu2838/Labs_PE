import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/shared/widgets/ui.dart';

void main() {
  testWidgets('El desplegable de un panel no absorbe títulos ni instrucciones', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Panel(child: Column(children: [
      const Text('Importación académica'),
      DropdownButtonFormField<String>(initialValue: 'habilitados',
        decoration: const InputDecoration(labelText: 'Tipo de datos'),
        items: const [DropdownMenuItem(value: 'habilitados', child: Text('Cursos habilitados'))],
        onChanged: (_) {}),
      const Text('Instrucciones para importar registros'),
    ])))));
    final node = tester.getSemantics(find.byType(DropdownButtonFormField<String>));
    expect(node.label, contains('Cursos habilitados'));
    expect(node.label, isNot(contains('Importación académica')));
      expect(node.label, isNot(contains('Instrucciones para importar registros')));
    } finally {
      semantics.dispose();
    }
  });
}
