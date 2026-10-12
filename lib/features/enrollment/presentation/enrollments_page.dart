import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reports/data/document_service.dart';
import '../domain/lab_group.dart';

class EnrollmentsPage extends ConsumerStatefulWidget {
  const EnrollmentsPage({super.key});
  @override
  ConsumerState<EnrollmentsPage> createState() => _EnrollmentsPageState();
}
class _EnrollmentsPageState extends ConsumerState<EnrollmentsPage> {
  bool _busy = false;
  Future<void> _action(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try { await operation(); ref.read(revisionProvider.notifier).refresh(); if (mounted) notify(context, 'Operación completada.'); }
    catch (e) { if (mounted) notify(context, errorLabel(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _change(String id, LabGroup group, List<LabGroup> groups) async {
    final choices = groups.where((g) => g.id != group.id && g.courseId == group.courseId && g.periodId == group.periodId).toList();
    if (choices.isEmpty) { notify(context, 'No hay otros grupos publicados para este curso.'); return; }
    final selected = await showDialog<LabGroup>(context: context, builder: (context) => SimpleDialog(title: const Text('Cambiar de grupo'), children: [
      for (final g in choices) SimpleDialogOption(onPressed: g.available <= 0 ? null : () => Navigator.pop(context, g), child: Text('${g.name} · ${g.available} vacantes\n${g.sessions.map((s) => s.label).join('\n')}')),
    ]));
    if (selected != null) await _action(() async { await ref.read(labRepositoryProvider).enroll(selected.id, replacing: id); });
  }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).asData?.value;
    final groups = ref.watch(groupsProvider).asData?.value ?? [];
    final student = user?.role.name == 'student';
    final teacher = user?.role.name == 'teacher';
    final assignedIds = groups.where((g) => g.teacherId == user?.id).map((g) => g.id).toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(student ? 'Mis matrículas' : teacher ? 'Mis grupos' : 'Matrículas y grupos', teacher ? 'Consulta tus grupos asignados y sus estudiantes.' : 'Consulta los registros y sus estados.', action: student ? OutlinedButton.icon(onPressed: _busy ? null : () async {
        try {
          final rows = await ref.read(recordsProvider('enrollments').future);
          final active = rows.where((r) => r['status'] == 'active' && r['student_id'] == user!.id);
          final output = <List<String>>[];
          for (final r in active) { final g = groups.where((g) => g.id == r['group_id']).firstOrNull; if (g != null) output.add([g.period, g.course, g.name, g.sessions.map((s) => s.label).join('\n')]); }
          if (output.isEmpty) { if (context.mounted) notify(context, 'No tienes matrículas activas para exportar.'); return; }
          await DocumentService.certificate(user!.name, user.cui, output);
        } catch (e) { if (context.mounted) notify(context, errorLabel(e)); }
      }, icon: const Icon(Icons.download_outlined), label: const Text('Constancia PDF')) : null),
      if (user?.role.name == 'teacher') ...[
        Text('Mis grupos asignados', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        for (final g in groups.where((g) => g.teacherId == user?.id)) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${g.course} · ${g.name}', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('${g.room} · ${g.period}'),
          for (final s in g.sessions) Text(s.label), const SizedBox(height: 8), StatusChip('${g.occupied} matriculados'),
        ]))), const SizedBox(height: 18),
      ],
      RecordsView('enrollments', builder: (rows) {
        final visible = rows.where((r) => student ? r['student_id'] == user!.id : !teacher || assignedIds.contains(r['group_id'])).toList();
        if (visible.isEmpty) return EmptyState(student ? 'Aún no tienes matrículas. Explora los laboratorios para comenzar.' : 'No hay matrículas en tus grupos.');
        return Column(children: [for (final row in visible.reversed) Padding(padding: const EdgeInsets.only(bottom: 14), child: Builder(builder: (context) {
          final g = groups.where((g) => g.id == row['group_id']).firstOrNull;
          return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 14, runSpacing: 8, children: [Text(g?.course ?? 'Grupo archivado', style: Theme.of(context).textTheme.titleMedium), StatusChip(row['status'] == 'active' ? 'Matriculado' : 'Retirado', good: row['status'] == 'active')]),
            const SizedBox(height: 10), Text('${g?.name ?? ''} · ${g?.period ?? ''} · ${g?.room ?? ''}'),
            if (!student) Text('Estudiante: ${row['student_id']}'),
            if (g != null) ...[const SizedBox(height: 8), for (final s in g.sessions) Text(s.label)],
            if (student && row['status'] == 'active' && g != null) ...[const SizedBox(height: 16), Wrap(spacing: 12, children: [
              OutlinedButton.icon(onPressed: _busy ? null : () => _change(row['id'], g, groups), icon: const Icon(Icons.swap_horiz), label: const Text('Cambiar de grupo')),
              TextButton.icon(onPressed: _busy ? null : () async { if (await confirm(context, 'Retirar matrícula', '¿Deseas retirarte de ${g.course}? Se liberará tu vacante.')) { await _action(() => ref.read(labRepositoryProvider).withdraw(row['id'])); } }, icon: const Icon(Icons.remove_circle_outline), label: const Text('Retirarme')),
            ])],
          ]));
        }))]);
      }), const SizedBox(height: 24), Text('Lista de espera', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      RecordsView('waitlist', builder: (rows) {
        final visible = rows.where((r) => r['status'] == 'waiting' && (student ? r['student_id'] == user!.id : !teacher || assignedIds.contains(r['group_id']))).toList()..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
        if (visible.isEmpty) return const EmptyState('No hay registros pendientes en lista de espera.');
        return Column(children: [for (final r in visible) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(groups.where((g) => g.id == r['group_id']).firstOrNull?.course ?? 'Grupo'), Text('Registrado: ${r['created_at'].toString().substring(0, 10)}'),
          const Text('La asignación se realiza por orden de llegada cuando se libera una vacante y se cumplen los requisitos.'),
          if (student) TextButton(onPressed: _busy ? null : () => _action(() => ref.read(labRepositoryProvider).leaveWaitlist(r['id'])), child: const Text('Salir de la lista')),
        ])))]);
      }), const SizedBox(height: 16), TextButton.icon(onPressed: () => context.go('/catalog'), icon: const Icon(Icons.add), label: const Text('Explorar más laboratorios')),
    ]);
  }
}
