// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_widgets.dart';
// import 'onboarding_screen.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    // Call provider to handle signup
    final success = await ref
        .read(authProvider.notifier)
        .signup(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success && mounted) {
      context.go('/onboarding');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: authAsync.when(
        data: (authState) => LoadingOverlay(
          isLoading: authState.isLoading,
          message: 'Creating your account...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join BlueDrop and start your hydration journey',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  CustomTextField(
                    label: 'Name',
                    hint: 'John Doe',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),

                  const SizedBox(height: 20),

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
                    hint: 'At least 6 characters',
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 20),

                  // Confirm password field
                  PasswordField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmPasswordController,
                  ),

                  const SizedBox(height: 32),

                  // Sign up button
                  AuthButton(
                    text: 'Sign Up',
                    onPressed: _handleSignup,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      AuthTextButton(
                        text: 'Login',
                        onPressed: () => context.pop(),
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
