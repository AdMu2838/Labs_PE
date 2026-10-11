typedef Record = Map<String, dynamic>;

abstract interface class LabRepository {
  Future<List<Record>> list(String table);
  Future<void> save(String table, Record row);
  Future<void> remove(String table, String id);
  Future<String> enroll(String groupId, {bool waitlist = false, String? replacing});
  Future<void> withdraw(String enrollmentId);
  Future<void> leaveWaitlist(String id);
  Future<void> resolveRequest(String id, String status, String response);
  Future<void> setRole(String id, String role);
  Future<void> markRead(String id);
  Future<void> importAcademic(List<Record> rows, String kind);
  Stream<void> get changes;
}
