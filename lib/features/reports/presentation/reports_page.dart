import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/ui.dart';
import '../data/document_service.dart';
import '../../auth/presentation/auth_controller.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final user = ref.watch(sessionProvider).asData?.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading('Reportes de matrícula', 'Ocupación de grupos y listas de estudiantes.', action: OutlinedButton.icon(onPressed: () async {
        try {
          final rawEnrollments = await ref.read(recordsProvider('enrollments').future);
          final profiles = await ref.read(recordsProvider('profiles').future);
          final allGroups = await ref.read(groupsProvider.future);
          final assignedIds = allGroups.where((g) => g.teacherId == user?.id).map((g) => g.id).toSet();
          final enrollments = rawEnrollments.where((r) => user?.role.name != 'teacher' || assignedIds.contains(r['group_id']));
          await DocumentService.csv('matriculas.csv', [['CUI', 'Estudiante', 'Periodo', 'Curso', 'Grupo', 'Estado'],
            for (final r in enrollments) [profiles.where((p) => p['id'] == r['student_id']).firstOrNull?['cui'] ?? '', profiles.where((p) => p['id'] == r['student_id']).firstOrNull?['full_name'] ?? r['student_id'],
              allGroups.where((g) => g.id == r['group_id']).firstOrNull?.period ?? '', allGroups.where((g) => g.id == r['group_id']).firstOrNull?.course ?? '', allGroups.where((g) => g.id == r['group_id']).firstOrNull?.name ?? '', presentationLabel(r['status'])]]);
        } catch (e) { if (context.mounted) notify(context, errorLabel(e)); }
      }, icon: const Icon(Icons.download_outlined), label: const Text('Exportar CSV'))),
      groups.when(loading: () => const CircularProgressIndicator(), error: (e, _) => EmptyState(errorLabel(e)), data: (rows) => rows.isEmpty ? const EmptyState('No hay grupos publicados.') : Column(children: [
        for (final g in rows.where((g) => user?.role.name != 'teacher' || g.teacherId == user?.id)) Padding(padding: const EdgeInsets.only(bottom: 14), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${g.course} · ${g.name}', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('${g.period} · ${g.room}'), const SizedBox(height: 16),
          LinearProgressIndicator(value: (g.occupied / g.capacity).clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(5)), const SizedBox(height: 8), Text('${g.occupied}/${g.capacity} matriculados · ${g.available} vacantes'),
        ]))),
      ])),
    ]);
  }
}
