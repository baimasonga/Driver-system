/// Supabase project connection details.
///
/// The publishable ("anon") key is safe to ship in client code by design —
/// Supabase enforces access through Row Level Security policies on the
/// server, not by keeping this key secret. See README.md for the current
/// RLS status of this project.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://pdzellpeglmjqxmnzgyx.supabase.co';
  static const String publishableKey = 'sb_publishable_sWYdIpmT6VSezvNVR6jpDQ_vAEgp5rw';
}
