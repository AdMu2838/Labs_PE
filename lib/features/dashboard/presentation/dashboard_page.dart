import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/ui.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/record_form.dart';
import '../../auth/presentation/auth_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).asData?.value;
    final groups = ref.watch(groupsProvider).asData?.value ?? [];
    final enrollments = ref.watch(recordsProvider('enrollments')).asData?.value ?? [];
    final waiting = ref.watch(recordsProvider('waitlist')).asData?.value ?? [];
    final active = enrollments.where((e) => e['status'] == 'active').length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading('Hola, ${user?.name.split(' ').first ?? 'agustino'} 👋', user?.manages == true ? 'Una visión completa de la matrícula de laboratorios.' : 'Tu próximo semestre comienza con una buena organización.'),
      Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [UnsaColors.garnet, UnsaColors.darkGarnet])),
        child: LayoutBuilder(builder: (context, c) => Wrap(spacing: 32, runSpacing: 24, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: c.maxWidth > 650 ? 450 : c.maxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TU ESPACIO ACADÉMICO', style: TextStyle(color: UnsaColors.gold, fontSize: 11, letterSpacing: 2)), const SizedBox(height: 14),
            const Text('Elige tu grupo.\nDale forma a tu horario.', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
            const SizedBox(height: 12), const Text('Consulta vacantes y evita cruces antes de matricularte.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 22), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: UnsaColors.gold, foregroundColor: UnsaColors.darkGarnet),
              onPressed: () => context.go('/catalog'), icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Explorar laboratorios')),
          ])),
          if (c.maxWidth > 650) const Icon(Icons.hub_outlined, size: 112, color: UnsaColors.gold),
        ]))), const SizedBox(height: 24),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 850 ? 4 : c.maxWidth > 480 ? 2 : 1;
        final stats = [('Grupos disponibles', '${groups.length}', Icons.science_outlined),
          (user?.manages == true ? 'Matrículas activas' : 'Mis matrículas', '$active', Icons.assignment_turned_in_outlined),
          ('Vacantes libres', '${groups.fold<int>(0, (n, g) => n + g.available)}', Icons.event_seat_outlined),
          ('En lista de espera', '${waiting.where((w) => w['status'] == 'waiting').length}', Icons.hourglass_bottom)];
        return Wrap(spacing: 16, runSpacing: 16, children: [for (final s in stats) SizedBox(width: (c.maxWidth - 16 * (cols - 1)) / cols, child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(s.$3, color: UnsaColors.garnet, size: 23), const SizedBox(height: 18), Text(s.$2, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 5), Text(s.$1, style: const TextStyle(color: UnsaColors.muted, fontSize: 12)),
        ])))]);
      }), const SizedBox(height: 28),
      RecordsView('periods', builder: (rows) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Calendario de matrícula', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        if (rows.isEmpty) const Text('Coordinación aún no ha publicado un periodo.'),
        for (final p in rows) Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)), StatusChip(p['status'] == 'open' ? 'Abierto' : 'Cerrado', good: p['status'] == 'open'),
          Text('Matrícula: ${_date(p['enrollment_start'])} — ${_date(p['enrollment_end'])}', style: const TextStyle(fontSize: 12, color: UnsaColors.muted)),
        ])),
      ]))), const SizedBox(height: 24),
      Row(children: [Expanded(child: Text('Avisos de la escuela', style: Theme.of(context).textTheme.titleLarge)), const Icon(Icons.campaign_outlined, color: UnsaColors.gold)]),
      if (user?.role.name == 'teacher') TextButton.icon(onPressed: () => editRecord(context, 'announcements', 'Aviso a un grupo', const [
        FormFieldSpec('group_id', 'Grupo asignado', table: 'groups'), FormFieldSpec('title', 'Título'), FormFieldSpec('body', 'Contenido', kind: 'long'),
      ]), icon: const Icon(Icons.add), label: const Text('Publicar aviso a mi grupo')),
      const SizedBox(height: 16), RecordsView('announcements', builder: (rows) => rows.isEmpty ? const EmptyState('No hay avisos publicados.') : Column(children: [
        for (final row in rows.reversed.take(5)) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row['title'], style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(row['body']),
        ]))),
      ])),
    ]);
  }
  String _date(dynamic value) { final d = DateTime.tryParse('$value')?.toLocal(); return d == null ? 'Por definir' : '${d.day}/${d.month}/${d.year}'; }
}
