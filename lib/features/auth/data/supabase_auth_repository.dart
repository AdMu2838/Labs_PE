import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client, {required this.url, required this.publishableKey});
  final SupabaseClient client;
  final String url, publishableKey;
  @override
  Future<AppSession?> current() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client.from('profiles').select().eq('id', user.id).single();
    if (row['active'] != true) throw const AuthException('Tu cuenta está inactiva. Contacta con coordinación.');
    return AppSession.fromJson(row);
  }
  @override
  Stream<AppSession?> get sessions => client.auth.onAuthStateChange.asyncMap((event) => current());
  @override
  Future<void> signIn(String email, String password) async { await client.auth.signInWithPassword(email: email, password: password); }
  @override
  Future<void> signInWithGoogle() async {
    final settings = await http.get(Uri.parse('$url/auth/v1/settings'),
      headers: {'apikey': publishableKey}).timeout(const Duration(seconds: 10));
    if (settings.statusCode != 200) throw const AuthException('No se pudo comprobar el acceso con Google. Inténtalo nuevamente.');
    final data = jsonDecode(settings.body) as Map<String, dynamic>;
    if (data['external']?['google'] != true) {
      throw const AuthException('El acceso con Google todavía no está habilitado en Supabase.');
    }
    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: '${Uri.base.origin}/',
      queryParams: {'prompt': 'select_account'},
    );
    if (!launched) throw const AuthException('No se pudo abrir Google. Inténtalo nuevamente.');
  }
  @override
  Future<void> signUp(String email, String password, String name, String cui) async {
    await client.auth.signUp(email: email, password: password, data: {'full_name': name, 'cui': cui},
      emailRedirectTo: Uri.base.origin);
  }
  @override
  Future<void> resetPassword(String email) => client.auth.resetPasswordForEmail(email, redirectTo: '${Uri.base.origin}/password');
  @override
  Future<void> updatePassword(String password) async { await client.auth.updateUser(UserAttributes(password: password)); }
  @override
  Future<void> signOut() => client.auth.signOut();
}
