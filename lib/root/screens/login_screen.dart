import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    setState(() => _submitting = true);
    await auth.signIn(_emailController.text, _passwordController.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.neutral950,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.shield_outlined, color: AppColors.neutral950, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Fleet Accountability Sign In', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text(
                    'Drivers and fleet managers sign in with the same form — where you land depends on your account.',
                    style: TextStyle(color: AppColors.neutral400, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submitting ? null : _submit(auth),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (auth.authError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.red500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(auth.authError!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(auth),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neutral950),
                          )
                        : const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
