import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  String _role        = 'buyer';
  bool   _obscure     = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
      _emailCtrl.text.trim(), _passwordCtrl.text, _role,
    );

    final state = ref.read(authNotifierProvider);
    state.when(
      data: (user) {
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please verify your email.')),
          );
          context.go('/login');
        }
      },
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorRed),
      ),
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('⚙️', textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('Create Account', textAlign: TextAlign.center, style: TextStyle(
                    fontFamily: 'Orbitron', fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary,
                  )),
                  const SizedBox(height: 32),

                  // Role selector
                  Row(children: [
                    Expanded(child: _roleButton('buyer',  '🛒 Buyer',  'Shop & bid on parts')),
                    const SizedBox(width: 12),
                    Expanded(child: _roleButton('vendor', '🏪 Vendor', 'Sell your parts')),
                  ]),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller:  _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller:  _confirmCtrl,
                    obscureText: _obscure,
                    decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  GradientButton(label: 'Create Account', onPressed: _register, isLoading: isLoading, width: double.infinity),
                  const SizedBox(height: 16),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ', style: TextStyle(color: AppTheme.textMuted)),
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role, String label, String sub) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        selected ? AppTheme.goldPrimary.withOpacity(0.08) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: selected ? AppTheme.goldPrimary : AppTheme.borderColor),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppTheme.goldPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
