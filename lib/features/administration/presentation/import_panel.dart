import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/domain/lab_repository.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/ui.dart';

class ImportPanel extends ConsumerStatefulWidget {
  const ImportPanel({super.key});
  @override
  ConsumerState<ImportPanel> createState() => _ImportPanelState();
}
class _ImportPanelState extends ConsumerState<ImportPanel> {
  String _kind = 'eligibilities';
  bool _busy = false;
  List<Record> _preview = [];
  String? _error;
  Future<void> _pick() async {
    try {
      final file = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (file == null) return;
      final text = utf8.decode(file.files.single.bytes!).replaceFirst('\uFEFF', '').replaceAll('\r\n', '\n');
      final parsed = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(text);
      if (parsed.length < 2) throw const FormatException('El archivo no contiene registros.');
      final headers = parsed.first.map((v) => '$v'.trim()).toList();
      final expected = _kind == 'eligibilities' ? ['cui', 'course_code', 'period_name'] : ['cui', 'course_code', 'grade'];
      if (!expected.every(headers.contains)) throw FormatException('Columnas requeridas: ${expected.join(', ')}');
      if (parsed.length > 501) throw const FormatException('Importa como máximo 500 filas por archivo.');
      final rows = <Record>[];
      for (final line in parsed.skip(1)) {
        if (line.every((v) => '$v'.trim().isEmpty)) continue;
        if (line.length != headers.length) throw const FormatException('Una fila tiene un número incorrecto de columnas.');
        rows.add({for (var i = 0; i < headers.length; i++) headers[i]: '${line[i]}'.trim()});
      }
      setState(() { _preview = rows; _error = null; });
    } catch (e) { setState(() => _error = '$e'); }
  }
  Future<void> _import() async {
    setState(() => _busy = true);
    try { await ref.read(labRepositoryProvider).importAcademic(_preview, _kind); ref.read(revisionProvider.notifier).refresh(); if (mounted) { notify(context, 'Importación completada: ${_preview.length} registros.'); setState(() => _preview = []); } }
    catch (e) { if (mounted) setState(() => _error = '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Importación académica', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
    DropdownButtonFormField<String>(initialValue: _kind, decoration: const InputDecoration(labelText: 'Tipo de datos'), items: const [DropdownMenuItem(value: 'eligibilities', child: Text('Cursos habilitados por periodo')), DropdownMenuItem(value: 'academic_records', child: Text('Historial académico'))], onChanged: _busy ? null : (v) => setState(() { _kind = v!; _preview = []; })),
    const SizedBox(height: 16), Text(_kind == 'eligibilities' ? 'CSV: cui,course_code,period_name\nEjemplo: 20250001,2501103,2026-B' : 'CSV: cui,course_code,grade\nEjemplo: 20250001,2501103,16'),
    const SizedBox(height: 12), const Text('Los usuarios deben estar registrados. Los códigos se validan contra su plan de estudios. La importación es transaccional: una fila inválida cancela todo el lote.'),
    const SizedBox(height: 20), OutlinedButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.upload_file), label: const Text('Seleccionar CSV')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    if (_preview.isNotEmpty) ...[const SizedBox(height: 20), Text('${_preview.length} registros listos para importar'), for (final r in _preview.take(5)) Text(r.values.join(' · ')), const SizedBox(height: 20), FilledButton(onPressed: _busy ? null : _import, child: Text(_busy ? 'Importando…' : 'Confirmar importación'))],
  ]));
}
