import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/ui.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../enrollment/domain/lab_group.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).asData?.value ?? [];
    final user = ref.watch(sessionProvider).asData?.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Mi horario', 'Todos tus laboratorios, organizados por día.'),
      RecordsView('enrollments', builder: (rows) {
        final ids = rows.where((r) => r['status'] == 'active' && (user?.role.name != 'student' || r['student_id'] == user!.id)).map((r) => r['group_id']).toSet();
        final enrolled = groups.where((g) => user?.role.name == 'teacher' ? g.teacherId == user?.id : ids.contains(g.id)).toList();
        if (enrolled.isEmpty) return const EmptyState('Tu horario está vacío. Se actualizará al confirmar tus matrículas.', icon: Icons.calendar_month_outlined);
        return LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth > 1050 ? 5 : c.maxWidth > 650 ? 3 : c.maxWidth > 450 ? 2 : 1;
          return Wrap(spacing: 12, runSpacing: 12, children: [for (var day = 1; day <= 7; day++) if (day <= 5 || enrolled.any((g) => g.sessions.any((s) => s.day == day))) SizedBox(width: (c.maxWidth - 12 * (columns - 1)) / columns,
            child: Panel(padding: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(LabSession.days[day - 1], style: const TextStyle(fontWeight: FontWeight.w700)), const Divider(height: 28),
              if (!enrolled.any((g) => g.sessions.any((s) => s.day == day))) const Text('Sin laboratorios', style: TextStyle(color: UnsaColors.muted, fontSize: 12)),
              for (final g in enrolled) for (final s in g.sessions.where((s) => s.day == day)) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF6EDEF), borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: UnsaColors.garnet, width: 3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${s.start.substring(0, 5)} – ${s.end.substring(0, 5)}', style: const TextStyle(fontSize: 11, color: UnsaColors.garnet, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(g.course, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text('${g.name}\n${g.room}', style: const TextStyle(fontSize: 11, color: UnsaColors.muted))])),
            ]))),
          ]);
        });
      }),
    ]);
  }
}
