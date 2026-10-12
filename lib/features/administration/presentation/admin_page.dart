import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/ui.dart';
import '../../../shared/widgets/record_form.dart';
import '../domain/admin_sections.dart';
import 'users_panel.dart';
import 'import_panel.dart';
import '../../auth/presentation/auth_controller.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key, this.section});
  final String? section;
  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}
class _AdminPageState extends ConsumerState<AdminPage> {
  int _selected = 0;
  String _search = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _selected = switch (widget.section) {
      'users' => adminSections.length,
      'import' => adminSections.length + 1,
      'audit' => adminSections.length + 2,
      _ => 0,
    };
  }
  @override
  Widget build(BuildContext context) {
    final section = _selected < adminSections.length ? adminSections[_selected] : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(ref.watch(sessionProvider).asData?.value?.role.name == 'coordinator' ? 'Gestión académica' : 'Administración', 'Configura la oferta académica y gestiona la matrícula.', action: section == null ? null : FilledButton.icon(onPressed: _busy ? null : () => editRecord(context, section.table, 'Crear ${section.label.toLowerCase()}', section.fields), icon: const Icon(Icons.add), label: const Text('Crear registro'))),
      Wrap(spacing: 8, runSpacing: 10, children: [for (var i = 0; i < adminSections.length + 3; i++) ChoiceChip(label: Text(i < adminSections.length ? adminSections[i].label : ['Usuarios', 'Importación CSV', 'Auditoría'][i - adminSections.length]), selected: _selected == i, onSelected: (_) => setState(() { _selected = i; _search = ''; }))]), const SizedBox(height: 22),
      if (_selected == adminSections.length) const UsersPanel()
      else if (_selected == adminSections.length + 1) const ImportPanel()
      else if (_selected == adminSections.length + 2) RecordsView('audit_logs', builder: (rows) => rows.isEmpty ? const EmptyState('No hay eventos de auditoría.') : Column(children: [for (final r in rows.reversed.take(100)) ListTile(leading: const Icon(Icons.history), title: Text('${presentationLabel(r['action'])} · ${presentationLabel(r['table_name'])}'), subtitle: Text('${r['created_at']}\nResponsable: ${r['actor_id']}'), isThreeLine: true)]))
      else if (section != null) ...[
        TextField(key: ValueKey(section.table), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar registros'), onChanged: (v) => setState(() => _search = v.toLowerCase())), const SizedBox(height: 18),
        RecordsView(section.table, builder: (rows) {
          final visible = rows.where((r) => r.values.join(' ').toLowerCase().contains(_search)).toList();
          if (visible.isEmpty) return const EmptyState('No hay registros que mostrar.');
          return Column(children: [for (final r in visible) Padding(padding: const EdgeInsets.only(bottom: 10), child: Panel(padding: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r[section.titleKey] ?? r['id']}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 6, children: [for (final f in section.fields.take(6)) Text('${f.label}: ${_display(ref, f, r[f.key])}', style: const TextStyle(fontSize: 12))]),
            const SizedBox(height: 12), Wrap(spacing: 12, children: [
              OutlinedButton.icon(onPressed: _busy ? null : () => editRecord(context, section.table, 'Editar registro', section.fields, initial: r), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')),
              TextButton.icon(onPressed: _busy ? null : () async {
                if (!await confirm(context, 'Eliminar registro', '¿Eliminar este registro? Los registros vinculados o con matrículas pueden impedir esta operación.')) return;
                setState(() => _busy = true);
                try { await ref.read(labRepositoryProvider).remove(section.table, r['id']); ref.read(revisionProvider.notifier).refresh(); }
                catch (e) { if (context.mounted) notify(context, errorLabel(e)); }
                finally { if (mounted) setState(() => _busy = false); }
              }, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Eliminar')),
            ]),
          ])))]);
        }),
      ],
    ]);
  }
  String _display(WidgetRef ref, FormFieldSpec field, dynamic value) {
    if (field.table == null) return value == null ? '—' : presentationLabel(value);
    final rows = ref.watch(recordsProvider(field.table!)).asData?.value ?? [];
    return rows.where((r) => r['id'] == value).firstOrNull?[field.optionLabel]?.toString() ?? '—';
  }
}
