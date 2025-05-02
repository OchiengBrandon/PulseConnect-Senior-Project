import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_dialog.dart';
import '../providers/auth_provider.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedUserType = 'student';
  String? _selectedInstitutionId;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<Map<String, dynamic>> _institutions = [];
  bool _isLoadingInstitutions = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstitutions();
    });
  }

  Future<void> _loadInstitutions() async {
    if (!mounted) return;

    setState(() {
      _isLoadingInstitutions = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final institutions = await authProvider.getInstitutions();
      if (!mounted) return;

      setState(() {
        _institutions = institutions;
      });
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInstitutions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User type selection
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I am a:', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),

                  // User type radio buttons
                  _buildUserTypeOption(
                    title: 'Student',
                    value: 'student',
                    icon: Icons.school_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),

                  _buildUserTypeOption(
                    title: 'Institution',
                    value: 'institution',
                    icon: Icons.account_balance_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),

                  _buildUserTypeOption(
                    title: 'Researcher',
                    value: 'researcher',
                    icon: Icons.science_outlined,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Name field
          AppTextField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: Validators.name,
          ),
          const SizedBox(height: 16),

          // Email field
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),

          // Institution dropdown (only for students)
          if (_selectedUserType == 'student') ...[
            _isLoadingInstitutions
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Institution',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  value: _selectedInstitutionId,
                  hint: const Text('Select your institution'),
                  items:
                      _institutions.map((institution) {
                        return DropdownMenuItem<String>(
                          value: institution['id'] as String,
                          child: Text(institution['name'] as String),
                        );
                      }).toList(),
                  validator:
                      _selectedUserType == 'student'
                          ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your institution';
                            }
                            return null;
                          }
                          : null,
                  onChanged: (value) {
                    setState(() {
                      _selectedInstitutionId = value;
                    });
                  },
                ),
            const SizedBox(height: 16),
          ],

          // Password field
          AppTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          AppTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // Terms and conditions
          Row(
            children: [
              Checkbox(value: true, onChanged: (value) {}),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Register button
          AppButton(
            text: 'Create Account',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final result = await authProvider.register(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                  name: _nameController.text.trim(),
                  userType: _selectedUserType,
                  institutionId:
                      _selectedUserType == 'student'
                          ? _selectedInstitutionId
                          : null,
                );

                if (result && mounted) {
                  if (_selectedUserType == 'student' &&
                      !authProvider.isVerified) {
                    // Show verification pending message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Registration successful! Institution verification is pending.',
                        ),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                  Navigator.pushReplacementNamed(context, AppRoutes.polls);
                }
              }
            },
            isLoading: authProvider.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption({
    required String title,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = value;
          // Reset institution selection if not student
          if (value != 'student') {
            _selectedInstitutionId = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedUserType,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedUserType = newValue;
                    // Reset institution selection if not student
                    if (newValue != 'student') {
                      _selectedInstitutionId = null;
                    }
                  });
                }
              },
              activeColor: theme.colorScheme.primary,
            ),
            Icon(
              icon,
              color:
                  _selectedUserType == value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color:
                    _selectedUserType == value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
