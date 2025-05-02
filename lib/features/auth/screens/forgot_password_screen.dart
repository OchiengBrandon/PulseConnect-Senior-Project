import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_dialog.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // Show error dialog if there's an error
    if (authProvider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder:
              (context) => ErrorDialog(
                message: authProvider.error!,
                onClose: () {
                  authProvider.clearError();
                },
              ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _resetEmailSent ? 'Reset Email Sent' : 'Forgot Password?',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  _resetEmailSent
                      ? 'Please check your email for instructions to reset your password.'
                      : 'Enter your email address and we\'ll send you instructions to reset your password.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!_resetEmailSent) ...[
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        AppTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        AppButton(
                          text: 'Reset Password',
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final result = await authProvider.resetPassword(
                                email: _emailController.text.trim(),
                              );

                              if (result && mounted) {
                                setState(() {
                                  _resetEmailSent = true;
                                });
                              }
                            }
                          },
                          isLoading: authProvider.isLoading,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Back to login button
                  AppButton(
                    text: 'Back to Login',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Link to login/resend
                if (!_resetEmailSent)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back to Login'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _resetEmailSent = false;
                      });
                    },
                    child: const Text('Resend Email'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
