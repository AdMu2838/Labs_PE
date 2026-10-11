import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/lab_repository.dart';
import '../../core/data/providers.dart';
import 'ui.dart';

class RecordsView extends ConsumerWidget {
  const RecordsView(this.table, {super.key, required this.builder});
  final String table;
  final Widget Function(List<Record>) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(recordsProvider(table)).when(
    data: builder,
    loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
    error: (e, _) => Panel(child: Column(children: [Text('No se pudo cargar la información: $e'),
      TextButton(onPressed: () => ref.invalidate(recordsProvider(table)), child: const Text('Reintentar'))])),
  );
}
