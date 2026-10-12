import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/ui.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/record_form.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/session.dart';
import '../../../app/shell/role_workspace.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).asData?.value;
    if (user == null) return const SizedBox.shrink();
    final role = user.role;
    final workspace = RoleWorkspace.forRole(role);
    final groupState = ref.watch(groupsProvider);
    final enrollmentState = ref.watch(recordsProvider('enrollments'));
    final waitingState = ref.watch(recordsProvider('waitlist'));
    final requestState = user.manages ? ref.watch(recordsProvider('requests')) : null;
    final groups = (groupState.asData?.value ?? []).where((g) => role != AppRole.teacher || g.teacherId == user.id).toList();
    final ids = groups.map((g) => g.id).toSet();
    final enrollments = (enrollmentState.asData?.value ?? []).where((e) => role == AppRole.student ? e['student_id'] == user.id : role != AppRole.teacher || ids.contains(e['group_id'])).toList();
    final waiting = (waitingState.asData?.value ?? []).where((e) => role == AppRole.student ? e['student_id'] == user.id : role != AppRole.teacher || ids.contains(e['group_id'])).toList();
    final loading = groupState.isLoading || enrollmentState.isLoading || waitingState.isLoading || requestState?.isLoading == true;
    final failed = groupState.hasError || enrollmentState.hasError || waitingState.hasError || requestState?.hasError == true;
    final active = enrollments.where((e) => e['status'] == 'active').length;
    final hero = switch (role) {
      AppRole.student => ('Elige tu grupo.\nDale forma a tu horario.', 'Consulta vacantes y evita cruces antes de matricularte.', '/catalog', 'Explorar laboratorios', Icons.science_outlined),
      AppRole.teacher => ('Todo listo para\ntu próxima sesión.', 'Revisa tus grupos y mantén informados a tus estudiantes.', '/enrollments', 'Consultar mis grupos', Icons.groups_outlined),
      AppRole.coordinator => ('Una oferta organizada.\nUna matrícula fluida.', 'Atiende solicitudes y supervisa la disponibilidad de los grupos.', '/requests', 'Atender solicitudes', Icons.support_agent_outlined),
      AppRole.admin => ('Tu centro de control\ninstitucional.', 'Administra cuentas y consulta la actividad del sistema.', '/admin?section=users', 'Gestionar usuarios', Icons.admin_panel_settings_outlined),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading('Hola, ${user.name.split(' ').first} 👋', workspace.description),
      Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [workspace.color, UnsaColors.darkGarnet])),
        child: LayoutBuilder(builder: (context, c) => Wrap(spacing: 32, runSpacing: 24, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: c.maxWidth > 650 ? 450 : c.maxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(workspace.title.toUpperCase(), style: const TextStyle(color: UnsaColors.gold, fontSize: 11, letterSpacing: 2)), const SizedBox(height: 14),
            Text(hero.$1, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
            const SizedBox(height: 12), Text(hero.$2, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 22), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: UnsaColors.gold, foregroundColor: UnsaColors.darkGarnet),
              onPressed: () => context.go(hero.$3), icon: const Icon(Icons.arrow_forward, size: 18), label: Text(hero.$4)),
          ])),
          if (c.maxWidth > 650) Icon(hero.$5, size: 112, color: UnsaColors.gold),
        ]))), const SizedBox(height: 24),
      if (loading) const LinearProgressIndicator(),
      if (failed) Panel(child: Column(children: [const Text('No se pudo cargar el resumen.'), TextButton(onPressed: () => ref.read(revisionProvider.notifier).refresh(), child: const Text('Reintentar'))])),
      if (!loading && !failed) LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 850 ? 4 : c.maxWidth > 480 ? 2 : 1;
        final stats = [(role == AppRole.teacher ? 'Grupos asignados' : 'Grupos disponibles', '${groups.length}', Icons.science_outlined),
          (role == AppRole.student ? 'Mis matrículas' : role == AppRole.teacher ? 'Matrículas en mis grupos' : 'Matrículas activas', '$active', Icons.assignment_turned_in_outlined),
          (role == AppRole.teacher ? 'Sesiones semanales' : 'Vacantes libres', '${role == AppRole.teacher ? groups.fold<int>(0, (n, g) => n + g.sessions.length) : groups.fold<int>(0, (n, g) => n + g.available)}', Icons.event_seat_outlined),
          (user.manages ? 'Solicitudes pendientes' : 'En lista de espera', '${user.manages ? (requestState?.asData?.value ?? []).where((r) => r['status'] == 'pending').length : waiting.where((w) => w['status'] == 'waiting').length}', Icons.hourglass_bottom)];
        return Wrap(spacing: 16, runSpacing: 16, children: [for (final s in stats) SizedBox(width: (c.maxWidth - 16 * (cols - 1)) / cols, child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(s.$3, color: UnsaColors.garnet, size: 23), const SizedBox(height: 18), Text(s.$2, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 5), Text(s.$1, style: const TextStyle(color: UnsaColors.muted, fontSize: 12)),
        ])))]);
      }), const SizedBox(height: 28),
      if (role == AppRole.student) ...[
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mi semana de laboratorios', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
          if (!loading && active == 0) const Text('Tu horario se actualizará cuando confirmes una matrícula.'),
          for (final g in groups.where((g) => enrollments.any((e) => e['status'] == 'active' && e['group_id'] == g.id))) ...[
            Text('${g.course} · ${g.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final s in g.sessions) Text('${s.label} · ${g.room}'), const SizedBox(height: 12),
          ],
          TextButton.icon(onPressed: () => context.go('/schedule'), icon: const Icon(Icons.calendar_month_outlined), label: const Text('Ver mi horario')),
        ])), const SizedBox(height: 24),
      ],
      if (role == AppRole.coordinator) ...[
        Text('Solicitudes por atender', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        RecordsView('requests', builder: (rows) {
          final pending = rows.where((r) => r['status'] == 'pending').toList();
          return pending.isEmpty ? const EmptyState('No hay solicitudes pendientes.') : Panel(child: Column(children: [
            for (final row in pending.take(4)) ListTile(leading: const Icon(Icons.support_agent_outlined), title: Text('${row['subject']}'), subtitle: Text(presentationLabel(row['type'])), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/requests')),
          ]));
        }), const SizedBox(height: 24),
      ],
      if (role != AppRole.student) ...[
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(role == AppRole.teacher ? 'Herramientas docentes' : 'Gestión rápida', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final link in workspace.links.take(3)) OutlinedButton.icon(onPressed: () => context.go(link.$1), icon: Icon(link.$3), label: Text(link.$2)),
            if (user.manages) OutlinedButton.icon(onPressed: () => context.go('/admin?section=import'), icon: const Icon(Icons.upload_file), label: const Text('Importar datos académicos')),
          ]),
        ])), const SizedBox(height: 24),
      ],
      if (role == AppRole.teacher) ...[
        Text('Mis grupos asignados', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        if (!loading && groups.isEmpty) const EmptyState('Aún no tienes grupos asignados.'),
        for (final g in groups) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${g.course} · ${g.name}', style: Theme.of(context).textTheme.titleMedium),
          Text('${g.room} · ${g.occupied} matriculados'),
          for (final s in g.sessions) Text(s.label),
        ]))), const SizedBox(height: 24),
      ],
      if (role == AppRole.admin) ...[
        Text('Actividad reciente', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        RecordsView('audit_logs', builder: (rows) => rows.isEmpty ? const EmptyState('No hay actividad reciente.') : Panel(child: Column(children: [
          for (final row in rows.reversed.take(4)) ListTile(leading: const Icon(Icons.history), title: Text('${presentationLabel(row['action'])} · ${presentationLabel(row['table_name'])}'), subtitle: Text('${row['created_at']}')),
        ]))), const SizedBox(height: 24),
      ],
      RecordsView('periods', builder: (rows) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Calendario de matrícula', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
        if (rows.isEmpty) const Text('Coordinación aún no ha publicado un periodo.'),
        for (final p in rows) Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)), StatusChip(presentationLabel(p['status']), good: p['status'] == 'open'),
          Text('Matrícula: ${_date(p['enrollment_start'])} — ${_date(p['enrollment_end'])}', style: const TextStyle(fontSize: 12, color: UnsaColors.muted)),
        ])),
      ]))), const SizedBox(height: 24),
      Row(children: [Expanded(child: Text('Avisos de la escuela', style: Theme.of(context).textTheme.titleLarge)), const Icon(Icons.campaign_outlined, color: UnsaColors.gold)]),
      if (role == AppRole.teacher) TextButton.icon(onPressed: () => editRecord(context, 'announcements', 'Aviso a un grupo', const [
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
