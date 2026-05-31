import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Text('⚙️', textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('AUTOX', textAlign: TextAlign.center, style: TextStyle(
                  fontFamily: 'Orbitron', fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.goldPrimary,
                )),
                const SizedBox(height: 4),
                const Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 48),

                // Google Sign In Button
                GradientButton(
                  label: 'Continue with Google',
                  onPressed: () async {
                    try {
                      final response = await Supabase.instance.client.auth.signInWithOAuth(
                        OAuthProvider.google,
                        redirectTo: Uri.base.origin + '/auth/v1/callback',
                      );
                      if (!response) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to sign in with Google'),
                              backgroundColor: AppTheme.colorRed,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppTheme.colorRed,
                          ),
                        );
                      }
                    }
                  },
                  isLoading: isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Alternative: Continue as Guest
                OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Browse as Guest'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),

                // Info text
                const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}