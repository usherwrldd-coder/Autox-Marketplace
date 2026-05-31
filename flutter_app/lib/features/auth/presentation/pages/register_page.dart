import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text('Create your account', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 48),

                // Info message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.goldPrimary, size: 32),
                      SizedBox(height: 12),
                      Text(
                        'Sign up is available via Google only.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use your Google account to create an account quickly and securely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Go to Login
                GradientButton(
                  label: 'Continue with Google',
                  onPressed: () => context.go('/login'),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Back to home
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Browse as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}