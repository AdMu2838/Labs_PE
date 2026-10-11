import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/record_form.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/auth_controller.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});
  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}
class _RequestsPageState extends ConsumerState<RequestsPage> {
  bool _busy = false;
  Future<void> _resolve(String id, String status) async {
    final controller = TextEditingController();
    final response = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Responder solicitud'), content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(labelText: 'Respuesta y motivo de la decisión')), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Enviar')),
    ]));
    controller.dispose();
    if (response == null) return;
    setState(() => _busy = true);
    try { await ref.read(labRepositoryProvider).resolveRequest(id, status, response); ref.read(revisionProvider.notifier).refresh(); }
    catch (e) { if (mounted) notify(context, '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final manages = ref.watch(sessionProvider).asData?.value?.manages == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading('Solicitudes', 'Comunícate con coordinación y sigue el estado de tu atención.', action: manages ? null : FilledButton.icon(onPressed: () => editRecord(context, 'requests', 'Nueva solicitud', const [
        FormFieldSpec('type', 'Tipo', options: ['schedule', 'capacity', 'exception', 'other']), FormFieldSpec('subject', 'Asunto'), FormFieldSpec('body', 'Describe tu solicitud', kind: 'long'),
      ]), icon: const Icon(Icons.add), label: const Text('Nueva solicitud'))),
      RecordsView('requests', builder: (rows) => rows.isEmpty ? const EmptyState('No hay solicitudes registradas.') : Column(children: [
        for (final r in rows.reversed) Padding(padding: const EdgeInsets.only(bottom: 14), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, runSpacing: 8, children: [Text(r['subject'], style: Theme.of(context).textTheme.titleMedium), StatusChip(switch (r['status']) {'pending' => 'Pendiente', 'approved' => 'Aprobada', 'rejected' => 'Rechazada', _ => 'Atendida'}, good: r['status'] != 'pending')]),
          const SizedBox(height: 12), Text(r['body']), if (manages) Text('Estudiante: ${r['student_id']}'),
          if (r['response'] != null) ...[const Divider(height: 28), Text('Respuesta: ${r['response']}')],
          if (manages && r['status'] == 'pending') ...[const SizedBox(height: 18), Wrap(spacing: 12, children: [
            FilledButton(onPressed: _busy ? null : () => _resolve(r['id'], 'approved'), child: const Text('Aprobar')),
            OutlinedButton(onPressed: _busy ? null : () => _resolve(r['id'], 'rejected'), child: const Text('Rechazar')),
            TextButton(onPressed: _busy ? null : () => _resolve(r['id'], 'resolved'), child: const Text('Responder')),
          ])],
        ]))),
      ])), const SizedBox(height: 16), const Text('La respuesta a una solicitud no modifica automáticamente tu matrícula. Cualquier habilitación académica debe registrarse por coordinación.'),
    ]);
  }
}
