import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasource(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email, password: password,
      );
      if (response.user == null) throw const AuthFailure('Login failed');
      final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
      return {'user': response.user, 'profile': profile};
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      if (response.user == null) throw const AuthFailure('Registration failed');
      await _client.from('profiles').insert({
        'id':   response.user!.id,
        'role': role,
      });
      return {'user': response.user};
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> logout() => _client.auth.signOut();

  Future<void> forgotPassword(String email) =>
    _client.auth.resetPasswordForEmail(email);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;
}
