import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/ui.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lab_group.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}
class _CatalogPageState extends ConsumerState<CatalogPage> {
  String _query = '';
  int? _semester;
  String? _period;
  bool _onlyAvailable = false;
  String? _busy;
  Future<void> _enroll(LabGroup group) async {
    final waiting = group.available <= 0;
    if (!await confirm(context, waiting ? 'Lista de espera' : 'Confirmar matrícula', '${group.course}\n${group.name} · ${group.room}\n${group.sessions.map((s) => s.label).join('\n')}\n\n${waiting ? 'Te registraremos en la cola para este grupo.' : 'Se validarán tus requisitos y cruces de horario.'}')) return;
    setState(() => _busy = group.id);
    try {
      final result = await ref.read(labRepositoryProvider).enroll(group.id, waitlist: waiting);
      ref.read(revisionProvider.notifier).refresh();
      if (mounted) notify(context, result == 'waiting' ? 'Te registraste en la lista de espera.' : '¡Matrícula confirmada! Consulta tu horario.');
    } catch (e) { if (mounted) notify(context, errorLabel(e)); }
    finally { if (mounted) setState(() => _busy = null); }
  }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).asData?.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Laboratorios disponibles', 'Encuentra el grupo que mejor se adapta a tu semestre.'),
      Panel(child: LayoutBuilder(builder: (context, c) => Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: c.maxWidth > 700 ? 300 : c.maxWidth, child: TextField(decoration: const InputDecoration(hintText: 'Buscar curso, código o docente', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _query = v.toLowerCase()))),
        SizedBox(width: c.maxWidth < 400 ? c.maxWidth : 170, child: DropdownButtonFormField<int>(isExpanded: true, initialValue: _semester, decoration: const InputDecoration(labelText: 'Semestre'), items: [const DropdownMenuItem(value: null, child: Text('Todos')), for (int i = 1; i <= 10; i++) DropdownMenuItem(value: i, child: Text('Semestre $i'))], onChanged: (v) => setState(() => _semester = v))),
        SizedBox(width: c.maxWidth < 400 ? c.maxWidth : 220, child: DropdownButtonFormField<String>(isExpanded: true, initialValue: _period, decoration: const InputDecoration(labelText: 'Periodo'), items: [const DropdownMenuItem(value: null, child: Text('Todos')), for (final p in ref.watch(recordsProvider('periods')).asData?.value ?? []) DropdownMenuItem(value: p['id'] as String, child: Text(p['name'], overflow: TextOverflow.ellipsis))], onChanged: (v) => setState(() => _period = v))),
        FilterChip(label: const Text('Solo con vacantes'), selected: _onlyAvailable, onSelected: (v) => setState(() => _onlyAvailable = v)),
      ]))), const SizedBox(height: 24),
      ref.watch(groupsProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => EmptyState('No se pudo cargar el catálogo: ${errorLabel(e)}'), data: (groups) {
        final filtered = groups.where((g) => '${g.course} ${g.code} ${g.teacher}'.toLowerCase().contains(_query) && (_semester == null || g.semester == _semester) && (_period == null || g.periodId == _period) && (!_onlyAvailable || g.available > 0)).toList();
        if (filtered.isEmpty) return const EmptyState('No hay grupos que coincidan con tu búsqueda.', icon: Icons.search_off);
        return LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 1100 ? 3 : c.maxWidth >= 680 ? 2 : 1;
          return Wrap(spacing: 18, runSpacing: 18, children: [for (final g in filtered) SizedBox(width: (c.maxWidth - 18 * (cols - 1)) / cols, child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [StatusChip('Semestre ${g.semester}'), StatusChip(g.available > 0 ? '${g.available} vacantes' : 'Grupo lleno', good: g.available > 0)]),
            const SizedBox(height: 18), Text(g.course, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6),
            Text('${g.code} · ${g.name}', style: const TextStyle(color: UnsaColors.muted, fontSize: 12)), const SizedBox(height: 18),
            _detail(Icons.person_outline, g.teacher), _detail(Icons.computer_outlined, g.room), _detail(Icons.school_outlined, g.period),
            for (final s in g.sessions) _detail(Icons.schedule, s.label),
            if (g.sessions.isEmpty) const Text('Horario por publicar'),
            const SizedBox(height: 18), LinearProgressIndicator(value: g.capacity == 0 ? 0 : (g.occupied / g.capacity).clamp(0, 1), minHeight: 5, borderRadius: BorderRadius.circular(4), color: g.available > 0 ? UnsaColors.garnet : UnsaColors.gold, backgroundColor: const Color(0xFFF0ECE8)),
            const SizedBox(height: 8), Text('${g.occupied} de ${g.capacity} plazas ocupadas', style: const TextStyle(fontSize: 11, color: UnsaColors.muted)), const SizedBox(height: 18),
            if (user?.role.name == 'student') SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy != null || g.sessions.isEmpty ? null : () => _enroll(g),
              icon: Icon(g.available > 0 ? Icons.add : Icons.hourglass_bottom, size: 18), label: Text(_busy == g.id ? 'Procesando…' : g.available > 0 ? 'Matricularme' : 'Unirme a lista de espera'))),
          ])))]);
        });
      }),
    ]);
  }
  Widget _detail(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: UnsaColors.muted), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12)))]));
}
