import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import '../domain/lab_repository.dart';
import 'demo_lab_repository.dart';
import 'supabase_lab_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/enrollment/domain/lab_group.dart';

final labRepositoryProvider = Provider<LabRepository>((ref) => Environment.configured
  ? SupabaseLabRepository(Supabase.instance.client) : DemoLabRepository());
final revisionProvider = NotifierProvider<Revision, int>(Revision.new);
class Revision extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}
final recordsProvider = FutureProvider.family<List<Record>, String>((ref, table) {
  ref.watch(sessionProvider);
  ref.watch(revisionProvider);
  return ref.watch(labRepositoryProvider).list(table);
});
final groupsProvider = FutureProvider<List<LabGroup>>((ref) async =>
  (await ref.watch(recordsProvider('groups_catalog').future)).map(LabGroup.fromJson).toList());

final realtimeProvider = Provider<void>((ref) {
  final sub = ref.watch(labRepositoryProvider).changes.listen((_) => ref.read(revisionProvider.notifier).refresh());
  ref.onDispose(sub.cancel);
});
