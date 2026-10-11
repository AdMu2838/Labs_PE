import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lab_repository.dart';

class SupabaseLabRepository implements LabRepository {
  SupabaseLabRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<Record>> list(String table) async {
    if (table == 'groups_catalog') {
      return List<Record>.from(await client.rpc('list_groups'));
    }
    final result = <Record>[];
    for (var offset = 0; ; offset += 500) {
      final page = List<Record>.from(await client.from(table).select().order('id').range(offset, offset + 499));
      result.addAll(page);
      if (page.length < 500) return result;
    }
  }
  @override
  Future<void> save(String table, Record row) async {
    if (row['id'] != null) {
      final values = {...row}..remove('id');
      await client.from(table).update(values).eq('id', row['id']);
    } else {
      await client.from(table).insert(row);
    }
  }
  @override
  Future<void> remove(String table, String id) async { await client.from(table).delete().eq('id', id); }
  @override
  Future<String> enroll(String groupId, {bool waitlist = false, String? replacing}) async =>
    await client.rpc('enroll_lab', params: {'p_group': groupId, 'p_waitlist': waitlist, 'p_replacing': replacing}) as String;
  @override
  Future<void> withdraw(String enrollmentId) async { await client.rpc('withdraw_lab', params: {'p_enrollment': enrollmentId}); }
  @override
  Future<void> leaveWaitlist(String id) async { await client.rpc('leave_waitlist', params: {'p_id': id}); }
  @override
  Future<void> resolveRequest(String id, String status, String response) async {
    await client.rpc('resolve_request', params: {'p_id': id, 'p_status': status, 'p_response': response});
  }
  @override
  Future<void> setRole(String id, String role) async { await client.rpc('set_user_role', params: {'p_user': id, 'p_role': role}); }
  @override
  Future<void> markRead(String id) async { await client.from('notifications').update({'is_read': true}).eq('id', id); }
  @override
  Future<void> importAcademic(List<Record> rows, String kind) async { await client.rpc('import_academic', params: {'p_rows': rows, 'p_kind': kind}); }
  @override
  Stream<void> get changes {
    late RealtimeChannel channel;
    late final StreamController<void> controller;
    controller = StreamController<void>(onListen: () {
      channel = client.channel('lab-events-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'groups', callback: (_) => controller.add(null))
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'notifications', callback: (_) => controller.add(null))
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'enrollments', callback: (_) => controller.add(null))
        .subscribe();
    }, onCancel: () async { await client.removeChannel(channel); });
    return controller.stream;
  }
}
