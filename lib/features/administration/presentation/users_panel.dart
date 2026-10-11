import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/record_form.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/auth_controller.dart';

class UsersPanel extends ConsumerWidget {
  const UsersPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(sessionProvider).asData?.value?.role.name == 'admin';
    return RecordsView('profiles', builder: (rows) => Column(children: [for (final r in rows) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(r['full_name'], style: const TextStyle(fontWeight: FontWeight.w700)), Text('${r['email']} · CUI ${r['cui'] ?? '—'}'), const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [StatusChip('${r['role']}'),
        OutlinedButton(onPressed: () => editRecord(context, 'profiles', 'Datos académicos del usuario', const [
          FormFieldSpec('full_name', 'Nombres y apellidos'), FormFieldSpec('cui', 'CUI', required: false), FormFieldSpec('plan_id', 'Plan', table: 'plans', required: false),
          FormFieldSpec('active', 'Cuenta activa', kind: 'bool'),
        ], initial: r), child: const Text('Editar datos')),
        if (isAdmin) PopupMenuButton<String>(tooltip: 'Cambiar rol', onSelected: (role) async {
          if (!await confirm(context, 'Cambiar permisos', '¿Asignar el rol $role a ${r['full_name']}?')) return;
          try { await ref.read(labRepositoryProvider).setRole(r['id'], role); ref.read(revisionProvider.notifier).refresh(); }
          catch (e) { if (context.mounted) notify(context, '$e'); }
        }, itemBuilder: (_) => [for (final role in ['student', 'teacher', 'coordinator', 'admin']) PopupMenuItem(value: role, child: Text(role))], child: const Padding(padding: EdgeInsets.all(12), child: Text('Cambiar rol ▾'))),
      ]),
    ])))]));
  }
}
