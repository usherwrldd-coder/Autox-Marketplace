import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user)
      ?? Supabase.instance.client.auth.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final client = ref.watch(supabaseProvider);
  final data = await client.from('profiles').select().eq('id', userId).single();
  return data;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(const AsyncValue.loading()) {
    _client.auth.onAuthStateChange.listen((event) {
      state = AsyncValue.data(event.session?.user);
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password, String role) async {
    state = const AsyncValue.loading();
    try {
      // Sign up with email/password - the database trigger will auto-create the profile
      final res = await _client.auth.signUp(
        email: email, 
        password: password,
        // Pass role in metadata for the trigger to use
        data: {'role': role},
      );
      // Profile is auto-created by the database trigger
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});
