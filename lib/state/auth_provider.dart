import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's role + linked driver record, read from `profiles`.
class AppProfile {
  final String id;
  final String role; // 'manager' | 'driver'
  final String? driverId;
  final String? fullName;
  final String? email;

  const AppProfile({required this.id, required this.role, this.driverId, this.fullName, this.email});

  bool get isManager => role == 'manager';

  factory AppProfile.fromRow(Map<String, dynamic> r) => AppProfile(
        id: r['id'],
        role: r['role'],
        driverId: r['driver_id'],
        fullName: r['full_name'],
        email: r['email'],
      );
}

/// Wraps Supabase Auth: tracks the current session, loads the matching
/// `profiles` row (role + linked driver) once signed in, and exposes
/// sign-in/sign-out. All API data access is gated behind this -- the
/// backend's Row Level Security policies require an authenticated session.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;

  Session? session;
  AppProfile? profile;
  bool isLoadingProfile = false;
  String? authError;

  AuthProvider() {
    session = _client.auth.currentSession;
    _authSub = _client.auth.onAuthStateChange.listen((state) {
      session = state.session;
      if (session == null) {
        profile = null;
        notifyListeners();
      } else {
        _loadProfile();
      }
    });
    if (session != null) _loadProfile();
  }

  Future<void> _loadProfile() async {
    isLoadingProfile = true;
    notifyListeners();
    try {
      final row = await _client.from('profiles').select().eq('id', session!.user.id).single();
      profile = AppProfile.fromRow(row);
    } catch (error) {
      debugPrint('Failed to load profile: $error');
      profile = null;
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    authError = null;
    notifyListeners();
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
      return true;
    } on AuthException catch (error) {
      authError = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      authError = 'Could not sign in: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    profile = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
