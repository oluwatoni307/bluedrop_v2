// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../auth_widgets.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    // Call provider to send reset email
    final success = await ref
        .read(authProvider.notifier)
        .resetPassword(_emailController.text);

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });

      // Navigate back to login after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.pop();
        }
      });
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
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: authAsync.when(
        data: (authState) => LoadingOverlay(
          isLoading: authState.isLoading,
          message: 'Sending reset link...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 56,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Success or instruction message
                  if (_emailSent)
                    _buildSuccessMessage()
                  else
                    _buildInstructionForm(authState),
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

  Widget _buildInstructionForm(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        const Text(
          'Forgot Your Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Description
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Email field
        CustomTextField(
          label: 'Email',
          hint: 'john@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),

        const SizedBox(height: 24),

        // Send reset link button
        AuthButton(
          text: 'Send Reset Link',
          onPressed: _handleResetPassword,
          isLoading: authState.isLoading,
        ),

        const SizedBox(height: 16),

        // Back to login
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Back to Login',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        ),

        const SizedBox(height: 24),

        // Success title
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Success message
        Text(
          'If an account exists with ${_emailController.text.trim()}, you\'ll receive a password reset link shortly.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Check your spam folder if you don\'t see the email in a few minutes.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Auto-redirect message
        Text(
          'Redirecting to login in 3 seconds...',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
