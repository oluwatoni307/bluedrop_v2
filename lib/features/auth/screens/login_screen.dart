// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_widgets.dart';

import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    // Call provider to handle login
    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (success && mounted) {
      final profile = ref.read(authProvider).value?.profile;
      if (profile?.isSetupComplete ?? false) {
        context.go('/'); // Home
      } else {
        context.go('/setup'); // Profile setup
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    // Show error in SnackBar when error changes
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenData((state) {
        if (state.error != null && state.error!.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: authAsync.when(
        data: (authState) => LoadingOverlay(
          isLoading: authState.isLoading,
          message: 'Logging in...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            size: 48,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'BlueDrop',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stay Hydrated, Stay Healthy',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email field
                  CustomTextField(
                    label: 'Email',
                    hint: 'john@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),

                  const SizedBox(height: 20),

                  // Password field
                  PasswordField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 12),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: AuthTextButton(
                      text: 'Forgot Password?',
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login button
                  AuthButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      AuthTextButton(
                        text: 'Sign Up',
                        onPressed: () {
                          context.push('/signup');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
