import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/lab_repository.dart';
import '../../core/data/providers.dart';
import '../../core/domain/form_field_spec.dart';
import '../presentation_labels.dart';
export '../../core/domain/form_field_spec.dart';

Future<bool> editRecord(BuildContext context, String table, String title, List<FormFieldSpec> fields, {Record? initial}) async =>
  await showDialog<bool>(context: context, builder: (_) => RecordForm(table: table, title: title, fields: fields, initial: initial)) ?? false;

class RecordForm extends ConsumerStatefulWidget {
  const RecordForm({super.key, required this.table, required this.title, required this.fields, this.initial});
  final String table, title;
  final List<FormFieldSpec> fields;
  final Record? initial;
  @override
  ConsumerState<RecordForm> createState() => _RecordFormState();
}
class _RecordFormState extends ConsumerState<RecordForm> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Record _values = {};
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final value = widget.initial?[f.key];
      if (f.kind == 'bool') { _values[f.key] = value ?? true; }
      else if (f.options != null || f.table != null) { _values[f.key] = value; }
      else {
        final text = f.kind == 'date' && value != null ? DateTime.parse('$value').toLocal().toString().substring(0, 16) : value?.toString() ?? '';
        _controllers[f.key] = TextEditingController(text: text);
      }
    }
  }
  @override
  void dispose() { for (final c in _controllers.values) { c.dispose(); } super.dispose(); }
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final row = <String, dynamic>{if (widget.initial?['id'] != null) 'id': widget.initial!['id']};
    for (final f in widget.fields) {
      if (f.kind == 'bool' || f.options != null || f.table != null) { row[f.key] = _values[f.key]; }
      else {
        final text = _controllers[f.key]!.text.trim();
        row[f.key] = text.isEmpty ? null : f.kind == 'int' ? int.parse(text) : f.kind == 'number' ? num.parse(text) : f.kind == 'date' ? DateTime.parse(text).toUtc().toIso8601String() : text;
      }
    }
    try {
      await ref.read(labRepositoryProvider).save(widget.table, row);
      ref.read(revisionProvider.notifier).refresh();
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) setState(() { _error = errorLabel(e); _busy = false; }); }
  }
  Widget _field(FormFieldSpec f) {
    if (f.kind == 'bool') return SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(f.label), value: _values[f.key] == true, onChanged: _busy ? null : (v) => setState(() => _values[f.key] = v));
    if (f.table != null) {
      final options = ref.watch(recordsProvider(f.table!));
      return options.when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Error al cargar ${f.label}: ${errorLabel(e)}'), data: (rows) {
        final filtered = rows.where((r) => f.key == 'teacher_id' ? r['role'] == 'teacher' && r['active'] == true : f.key == 'student_id' ? r['role'] == 'student' : true);
        final entries = filtered.map((r) => (r['id'].toString(), '${r[f.optionLabel]}')).toList();
        return _dropdown(f, entries);
      });
    }
    if (f.options != null) return _dropdown(f, f.options!.map((v) => (v, presentationLabel(v))).toList());
    return TextFormField(controller: _controllers[f.key], enabled: !_busy, maxLines: f.kind == 'long' ? 3 : 1,
      decoration: InputDecoration(labelText: f.label, helperText: f.kind == 'date' ? 'AAAA-MM-DD HH:MM (hora local)' : f.kind == 'time' ? 'HH:MM, formato de 24 horas' : null),
      keyboardType: f.kind == 'int' || f.kind == 'number' ? TextInputType.number : TextInputType.text,
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return f.required ? 'Campo obligatorio' : null;
        if (f.kind == 'int' && int.tryParse(value) == null) return 'Ingresa un número entero';
        if (f.kind == 'cui' && !RegExp(r'^\d{8}$').hasMatch(value)) return 'Ingresa un CUI de 8 dígitos';
        if (f.kind == 'number' && num.tryParse(value) == null) return 'Ingresa un número';
        if (f.kind == 'date' && DateTime.tryParse(value) == null) return 'Fecha inválida';
        if (f.kind == 'time' && !RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$').hasMatch(value)) return 'Usa HH:MM';
        return null;
      });
  }
  Widget _dropdown(FormFieldSpec f, List<(String, String)> entries) => DropdownButtonFormField<String>(
    isExpanded: true, initialValue: entries.any((e) => e.$1 == _values[f.key]) ? _values[f.key] : null,
    decoration: InputDecoration(labelText: f.label), items: [if (!f.required) const DropdownMenuItem(value: null, child: Text('Sin asignar')),
      for (final e in entries) DropdownMenuItem(value: e.$1, child: Text(e.$2, overflow: TextOverflow.ellipsis))],
    onChanged: _busy ? null : (v) => _values[f.key] = v,
    validator: (v) => f.required && v == null ? 'Selecciona una opción' : null);
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final content = Form(key: _form, child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final f in widget.fields) Padding(padding: const EdgeInsets.only(bottom: 16), child: _field(f)),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ])));
    final buttons = [TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
      FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Guardando…' : 'Guardar'))];
    if (mobile) return Dialog.fullscreen(child: Scaffold(appBar: AppBar(title: Text(widget.title)), body: content, bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons)))));
    return AlertDialog(title: Text(widget.title), content: SizedBox(width: 520, child: content), actions: buttons);
  }
}
