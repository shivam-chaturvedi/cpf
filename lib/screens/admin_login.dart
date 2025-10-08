import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/validators.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showCredentials = false;

  // Hardcoded admin credentials (as per requirements - no Firebase)
  static const String adminEmail = 'support@cpfindia.org';
  static const String adminPassword = 'CPFAdmin2024!';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate login delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Check hardcoded credentials
    if (email == adminEmail && password == adminPassword) {
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Welcome, Admin!');
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } else {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context,
            'Invalid admin credentials. Please check email and password.');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = adminEmail;
      _passwordController.text = adminPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Admin Login'),
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
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Admin Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.errorRed,
                          AppTheme.warningOrange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: AppTheme.surfaceWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CPF Admin Panel',
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
                          'Secure administrative access',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTheme.surfaceWhite.withOpacity(0.9),
                              ),
                        ),
                        const SizedBox(height: 12),
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
                                'Hardcoded Authentication',
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

                  const SizedBox(height: 40),

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
                        // Credentials Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Admin Credentials',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showCredentials = !_showCredentials;
                                });
                              },
                              icon: Icon(_showCredentials
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              label: Text(_showCredentials ? 'Hide' : 'Show'),
                            ),
                          ],
                        ),

                        if (_showCredentials) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.warningOrange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: AppTheme.warningOrange,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Demo Credentials',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppTheme.warningOrange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Email: $adminEmail',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Password: $adminPassword',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                CustomButton(
                                  text: 'Auto-fill Credentials',
                                  onPressed: _fillDemoCredentials,
                                  icon: Icons.auto_fix_high,
                                  isOutlined: true,
                                  backgroundColor: AppTheme.warningOrange,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Admin Email',
                          hint: 'Enter admin email address',
                          icon: Icons.admin_panel_settings,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        CustomPasswordField(
                          controller: _passwordController,
                          label: 'Admin Password',
                          hint: 'Enter admin password',
                          validator: Validators.validatePassword,
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        CustomButton(
                          text: 'Login as Admin',
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          isLoading: _isLoading,
                          icon: Icons.admin_panel_settings,
                          width: double.infinity,
                          backgroundColor: AppTheme.errorRed,
                        ),

                        const SizedBox(height: 24),

                        // Security Notice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.errorRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: AppTheme.errorRed, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This is a secure admin area. Unauthorized access is prohibited.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.errorRed,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Navigation back to NGO portal
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
                              Icons.business_center,
                              color: AppTheme.primaryRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NGO Portal Access',
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
                        Text(
                          'Are you an NGO looking to register or login?',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'NGO Login',
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/ngo-login'),
                                icon: Icons.login,
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'NGO Register',
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/ngo-register'),
                                icon: Icons.app_registration,
                                isOutlined: true,
                              ),
                            ),
                          ],
                        ),
                      ],
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
