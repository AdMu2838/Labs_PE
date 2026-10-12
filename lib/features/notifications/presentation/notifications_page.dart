import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/async_records.dart';
import '../../../shared/widgets/ui.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const PageHeading('Notificaciones', 'Mantente al día con tu matrícula y tus solicitudes.'),
    RecordsView('notifications', builder: (rows) => rows.isEmpty ? const EmptyState('No tienes notificaciones.') : Column(children: [
      for (final r in rows.reversed) Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, children: [Text(r['title'], style: Theme.of(context).textTheme.titleMedium), if (r['is_read'] != true) const StatusChip('Nueva')]),
        const SizedBox(height: 10), Text(r['body']),
        if (r['is_read'] != true) TextButton(onPressed: () async {
          try { await ref.read(labRepositoryProvider).markRead(r['id']); ref.read(revisionProvider.notifier).refresh(); }
          catch (e) { if (context.mounted) notify(context, errorLabel(e)); }
        }, child: const Text('Marcar como leída')),
      ]))),
    ])),
  ]);
}
