import 'package:cpf_portal/util/validators.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class NGOLoginPage extends StatefulWidget {
  const NGOLoginPage({super.key});

  @override
  State<NGOLoginPage> createState() => _NGOLoginPageState();
}

class _NGOLoginPageState extends State<NGOLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleFirebaseLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Welcome back!');
        Navigator.pushReplacementNamed(context, '/ngo-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage =
              'No account found with this email. Please register first.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }

      if (mounted) {
        AppHelpers.showErrorSnackBar(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('NGO Login'),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
        child: Center(
          child: Container(
            constraints: AppHelpers.getResponsiveConstraints(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: AppHelpers.getResponsiveSpacing(context, 40)),

                  // Header with Firebase branding
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business_center,
                          size: AppHelpers.getResponsiveIconSize(context, 48),
                          color: AppTheme.surfaceWhite,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.surfaceWhite,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your NGO account',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTheme.surfaceWhite.withOpacity(0.9),
                              ),
                        ),
                        const SizedBox(height: 12),
                        // Firebase indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.security,
                                  color: AppTheme.surfaceWhite, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Secured by Firebase',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.surfaceWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: AppHelpers.getResponsiveSpacing(context, 40)),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGray),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your registered email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        CustomPasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          validator: Validators.validatePassword,
                        ),

                        const SizedBox(height: 24),

                        // Login Button with Firebase
                        CustomButton(
                          text: 'Sign In with Firebase',
                          onPressed: _isLoading ? null : _handleFirebaseLogin,
                          isLoading: _isLoading,
                          icon: Icons.login,
                          width: double.infinity,
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Don\'t have an account?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Register Button
                        CustomButton(
                          text: 'Register Your NGO',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/ngo-register'),
                          icon: Icons.app_registration,
                          isOutlined: true,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: AppHelpers.getResponsiveSpacing(context, 40)),

                  // Support Information (from wireframe)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.support_agent,
                              color: AppTheme.primaryRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Need Help?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Support details from wireframe
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.phone,
                                    color: AppTheme.primaryRed, size: 16),
                                const SizedBox(height: 4),
                                Text(
                                  '+91 9871216099',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppTheme.borderGray,
                            ),
                            Column(
                              children: [
                                const Icon(Icons.email,
                                    color: AppTheme.primaryRed, size: 16),
                                const SizedBox(height: 4),
                                Text(
                                  'support@cpf.org.in',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: AppHelpers.getResponsiveSpacing(context, 20)),

                  // Back to Home Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              AppHelpers.getResponsiveSpacing(context, 16),
                          vertical: AppHelpers.getResponsiveSpacing(context, 8),
                        ),
                        minimumSize: Size(
                          AppHelpers.getResponsiveSpacing(context, 120),
                          AppHelpers.getResponsiveButtonHeight(context) * 0.7,
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize:
                              AppHelpers.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
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
