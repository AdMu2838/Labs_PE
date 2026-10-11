abstract final class Environment {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get configured => url.isNotEmpty && key.isNotEmpty;
}
