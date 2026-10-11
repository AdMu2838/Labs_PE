import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) => Environment.configured
    ? SupabaseAuthRepository(Supabase.instance.client, url: Environment.url, publishableKey: Environment.key) : null);

final sessionProvider = StreamProvider<AppSession?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  if (repository == null) { yield ref.watch(demoSessionProvider); return; }
  yield await repository.current();
  yield* repository.sessions;
});

final demoSessionProvider = NotifierProvider<DemoSessionController, AppSession?>(DemoSessionController.new);
class DemoSessionController extends Notifier<AppSession?> {
  @override
  AppSession? build() => null;
  void enter(AppRole role) => state = AppSession(id: 'demo', name: 'Alex Agustino', email: 'demo@unsa.edu.pe', cui: '20250001', role: role);
  void leave() => state = null;
}

Future<void> logout(WidgetRef ref) async {
  final repository = ref.read(authRepositoryProvider);
  if (repository == null) { ref.read(demoSessionProvider.notifier).leave(); }
  else { await repository.signOut(); }
}
