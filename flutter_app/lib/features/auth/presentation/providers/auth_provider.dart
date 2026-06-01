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

/// User profile data with null-safe defaults
class UserProfile {
  final String id;
  final String email;
  final String role;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? bio;
  final bool isActive;
  final String? kycStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.role = 'buyer',
    this.username = '',
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.isActive = true,
    this.kycStatus,
    this.createdAt,
    this.updatedAt,
  });

  /// Display name - falls back to username or email
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (username.isNotEmpty) return username;
    return email.split('@').first;
  }

  /// Avatar URL with placeholder fallback
  String get avatarUrlOrPlaceholder => avatarUrl ?? 'https://ui-avatars.com/api/?name=${displayName.replaceAll(' ', '+')}&background=0D8ABC&color=fff';

  /// Create from database map with null-safe defaults
  factory UserProfile.fromMap(Map<String, dynamic> data, {required String fallbackEmail}) {
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String? ?? fallbackEmail,
      role: (data['role'] as String?) ?? 'buyer',
      username: (data['username'] as String?) ?? '',
      fullName: data['full_name'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      phone: data['phone'] as String?,
      bio: data['bio'] as String?,
      isActive: (data['is_active'] as bool?) ?? true,
      kycStatus: data['kyc_status'] as String?,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at'] as String) : null,
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at'] as String) : null,
    );
  }

  /// Create empty profile with defaults (for new users)
  factory UserProfile.empty({required String userId, required String email}) {
    return UserProfile(
      id: userId,
      email: email,
      role: 'buyer',
      username: email.split('@').first,
      fullName: null,
      avatarUrl: null,
      phone: null,
      bio: null,
      isActive: true,
      kycStatus: 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'bio': bio,
      'is_active': isActive,
      'kyc_status': kycStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? bio,
    bool? isActive,
    String? kycStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      kycStatus: kycStatus ?? this.kycStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Wallet data with null-safe defaults
class UserWallet {
  final String userId;
  final double balance;
  final double escrowBalance;
  final String currency;

  UserWallet({
    required this.userId,
    this.balance = 0.0,
    this.escrowBalance = 0.0,
    this.currency = 'AXC',
  });

  factory UserWallet.fromMap(Map<String, dynamic> data) {
    return UserWallet(
      userId: data['user_id'] as String,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      escrowBalance: (data['escrow_balance'] as num?)?.toDouble() ?? 0.0,
      currency: (data['currency'] as String?) ?? 'AXC',
    );
  }

  factory UserWallet.empty({required String userId}) {
    return UserWallet(
      userId: userId,
      balance: 0.0,
      escrowBalance: 0.0,
      currency: 'AXC',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'balance': balance,
      'escrow_balance': escrowBalance,
      'currency': currency,
    };
  }
}

/// Provider that fetches user profile with null-safety
/// Returns a profile with sensible defaults even if database row doesn't exist
final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final client = ref.watch(supabaseProvider);
  
  try {
    // Try to fetch the profile
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle(); // Use maybeSingle instead of single - returns null if not found
    
    if (response == null) {
      // Profile doesn't exist - create one automatically
      ref.read(authNotifierProvider.notifier).log('Profile not found for $userId, creating default profile');
      
      // Get user's email from auth
      final user = client.auth.currentUser;
      final email = user?.email ?? '';
      
      // Create default profile
      final defaultProfile = UserProfile.empty(userId: userId, email: email);
      
      // Try to insert it
      try {
        await client.from('profiles').upsert(defaultProfile.toMap()).select().single();
        ref.read(authNotifierProvider.notifier).log('Created default profile for $userId');
        return defaultProfile;
      } catch (e) {
        // If insert fails, return the default profile anyway
        ref.read(authNotifierProvider.notifier).log('Failed to create profile: $e');
        return defaultProfile;
      }
    }
    
    // Profile exists - parse it
    final user = client.auth.currentUser;
    final email = user?.email ?? '';
    return UserProfile.fromMap(response, fallbackEmail: email);
  } catch (e) {
    // On any error, return a default profile
    ref.read(authNotifierProvider.notifier).log('Error fetching profile: $e');
    final user = client.auth.currentUser;
    final email = user?.email ?? '';
    return UserProfile.empty(userId: userId, email: email);
  }
});

/// Provider that fetches user wallet with null-safety
final userWalletProvider = FutureProvider.family<UserWallet, String>((ref, userId) async {
  final client = ref.watch(supabaseProvider);
  
  try {
    final response = await client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) {
      // Wallet doesn't exist - create one
      ref.read(authNotifierProvider.notifier).log('Wallet not found for $userId, creating default wallet');
      
      final defaultWallet = UserWallet.empty(userId: userId);
      
      try {
        await client.from('wallets').insert(defaultWallet.toMap()).select().single();
        ref.read(authNotifierProvider.notifier).log('Created default wallet for $userId');
        return defaultWallet;
      } catch (e) {
        ref.read(authNotifierProvider.notifier).log('Failed to create wallet: $e');
        return defaultWallet;
      }
    }
    
    return UserWallet.fromMap(response);
  } catch (e) {
    ref.read(authNotifierProvider.notifier).log('Error fetching wallet: $e');
    return UserWallet.empty(userId: userId);
  }
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final SupabaseClient _client;
  final List<String> _logs = [];

  AuthNotifier(this._client) : super(const AsyncValue.loading()) {
    _client.auth.onAuthStateChange.listen((event) {
      log('Auth state changed: ${event.session?.user?.email ?? "null"}');
      state = AsyncValue.data(event.session?.user);
    });
  }

  void log(String message) {
    _logs.add('[${DateTime.now().toIso8601String()}] $message');
    // Keep only last 100 logs
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    print('AuthNotifier: $message');
  }

  List<String> get logs => List.unmodifiable(_logs);

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      log('Starting Google sign-in...');
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin + '/auth/v1/callback',
      );
      if (!response) {
        log('Google sign-in failed: OAuth request returned false');
        state = const AsyncValue.error('Google sign-in failed', StackTrace.empty);
      } else {
        log('Google sign-in initiated successfully');
      }
    } catch (e, st) {
      log('Google sign-in error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    log('Logging out...');
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
    log('Logged out successfully');
  }

  /// Ensure user profile exists - call this after login
  /// Returns a profile with sensible defaults even if database row doesn't exist
  /// Note: This method directly fetches/creates the profile without using the provider
  Future<UserProfile> ensureProfile(String userId) async {
    log('Ensuring profile for user $userId');
    
    final user = _client.auth.currentUser;
    final email = user?.email ?? '';
    
    try {
      // Try to fetch existing profile
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        log('Found existing profile for $userId');
        return UserProfile.fromMap(response, fallbackEmail: email);
      }
      
      // Profile doesn't exist - create one
      log('Profile not found, creating default for $userId');
      final defaultProfile = UserProfile.empty(userId: userId, email: email);
      
      try {
        await _client.from('profiles').upsert(defaultProfile.toMap()).select().single();
        log('Created default profile for $userId');
        return defaultProfile;
      } catch (e) {
        log('Failed to create profile: $e');
        return defaultProfile;
      }
    } catch (e) {
      log('Error ensuring profile: $e');
      return UserProfile.empty(userId: userId, email: email);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});

/// Combined provider that returns both user and profile
/// Useful for auth guards that need to wait for profile data
class AuthWithProfile {
  final User? user;
  final UserProfile? profile;
  final UserWallet? wallet;
  final bool isLoading;
  final String? error;

  AuthWithProfile({
    this.user,
    this.profile,
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;
  bool get hasProfile => profile != null;
  bool get hasWallet => wallet != null;
  
  String get displayName => profile?.displayName ?? user?.email?.split('@').first ?? 'User';
  String get avatarUrl => profile?.avatarUrlOrPlaceholder ?? '';
  String get role => profile?.role ?? 'buyer';
}

final authWithProfileProvider = FutureProvider<AuthWithProfile>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return AuthWithProfile();
  }
  
  try {
    ref.read(authNotifierProvider.notifier).log('Loading profile for ${user.id}');
    
    // Load profile and wallet in parallel
    final results = await Future.wait([
      ref.watch(userProfileProvider(user.id).future),
      ref.watch(userWalletProvider(user.id).future),
    ]);
    
    ref.read(authNotifierProvider.notifier).log('Profile and wallet loaded for ${user.id}');
    
    return AuthWithProfile(
      user: user,
      profile: results[0] as UserProfile,
      wallet: results[1] as UserWallet,
    );
  } catch (e) {
    ref.read(authNotifierProvider.notifier).log('Error loading profile/wallet: $e');
    return AuthWithProfile(
      user: user,
      error: e.toString(),
    );
  }
});