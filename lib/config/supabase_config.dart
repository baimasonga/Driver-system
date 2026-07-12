/// Supabase project connection details.
///
/// The publishable key is safe to ship in client code by design. Supabase
/// enforces access through Row Level Security policies on the server.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://ceohpwcxnnbmafujyoga.supabase.co';
  static const String publishableKey =
      'sb_publishable_8D7vTPGfY4pnGPh9uDqVtg_DOHme2kx';
}
