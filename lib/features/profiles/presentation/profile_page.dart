import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/record_form.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).asData?.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Mi perfil', 'Tu información personal y académica.'),
      if (user?.role.name == 'student' && user!.cui.isEmpty) ...[
        const Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Completa tu CUI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          SizedBox(height: 8), Text('Tu cuenta ya está autenticada. Antes de matricularte, registra tu CUI de 8 dígitos con el botón de editar datos. Solo podrás asignarlo una vez; los cambios posteriores los realiza coordinación.'),
        ])), const SizedBox(height: 20),
      ],
      RecordsView('profiles', builder: (rows) {
        final row = rows.where((r) => r['id'] == user?.id).firstOrNull;
        if (row == null) return const EmptyState('No se encontró tu perfil.');
        return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row['full_name'], style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
          Text('Correo: ${row['email']}'), Text('CUI: ${row['cui'] ?? 'No aplica'}'), Text('Rol: ${user?.roleLabel}'),
          Text('Créditos aprobados verificados: ${row['approved_credits'] ?? 0}'), const SizedBox(height: 12), StatusChip(row['active'] == true ? 'Cuenta activa' : 'Cuenta inactiva', good: row['active'] == true),
          const SizedBox(height: 18), OutlinedButton.icon(onPressed: () async {
            if (await editRecord(context, 'profiles', 'Editar perfil', [
              const FormFieldSpec('full_name', 'Nombres y apellidos'),
              if (row['role'] == 'student' && row['cui'] == null) const FormFieldSpec('cui', 'CUI (8 dígitos)', kind: 'cui'),
              const FormFieldSpec('phone', 'Teléfono', required: false),
            ], initial: row)) { ref.invalidate(sessionProvider); }
          }, icon: const Icon(Icons.edit_outlined), label: const Text('Editar datos personales')),
          const SizedBox(height: 16), const Text('El CUI, el plan de estudios, los créditos y el rol son verificados por administración.'),
        ]));
      }), const SizedBox(height: 24), Text('Historial académico verificado', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      RecordsView('academic_records', builder: (rows) {
        final own = rows.where((r) => r['student_id'] == user?.id).toList();
        final courses = ref.watch(recordsProvider('courses')).asData?.value ?? [];
        return own.isEmpty ? const EmptyState('Aún no se ha importado tu historial académico.') : Column(children: [for (final r in own) ListTile(title: Text(courses.where((c) => c['id'] == r['course_id']).firstOrNull?['name'] ?? r['course_id']), subtitle: Text('Nota: ${r['grade']} · ${r['passed'] == true ? 'Aprobado' : 'No aprobado'}'))]);
      }),
    ]);
  }
}
