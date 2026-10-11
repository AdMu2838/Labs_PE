import 'package:flutter/material.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/ui.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});
  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}
class _CurriculumPageState extends State<CurriculumPage> {
  String _query = '';
  bool _labs = false;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const PageHeading('Plan de estudios', 'Asignaturas, créditos y horas de laboratorio de Ingeniería de Sistemas.'),
    Panel(child: Column(children: [TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar asignatura o código'), onChanged: (v) => setState(() => _query = v.toLowerCase())),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Mostrar solo cursos con laboratorio'), value: _labs, onChanged: (v) => setState(() => _labs = v))])), const SizedBox(height: 20),
    RecordsView('courses', builder: (rows) => Column(children: [for (var semester = 1; semester <= 10; semester++) Builder(builder: (context) {
      final courses = rows.where((r) => r['semester'] == semester && '${r['name']} ${r['code']}'.toLowerCase().contains(_query) && (!_labs || (r['lab_hours'] as num) > 0)).toList()..sort((a, b) => '${a['code']}'.compareTo('${b['code']}'));
      if (courses.isEmpty) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(bottom: 14), child: Panel(padding: 8, child: ExpansionTile(initiallyExpanded: _query.isNotEmpty || semester == 1, title: Text('Semestre $semester', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${courses.length} asignaturas'), children: [
        for (final c in courses) ListTile(isThreeLine: true, title: Text(c['name']), subtitle: Text('${c['code']} · ${c['credits']} créditos · ${c['lab_hours']} h laboratorio\n${c['elective'] == true ? 'Electivo' : 'Obligatorio'}'), leading: const Icon(Icons.menu_book_outlined)),
      ])));
    })])),
  ]);
}
