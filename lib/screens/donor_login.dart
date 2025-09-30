import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/validators.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import 'package:cpf_portal/widgets/custom_text_field.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'donor_registration.dart';

class DonorLoginPage extends StatefulWidget {
  const DonorLoginPage({super.key});

  @override
  State<DonorLoginPage> createState() => _DonorLoginPageState();
}

class _DonorLoginPageState extends State<DonorLoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        // Check if user is a donor in either collection
        final donorProfilesDoc = await FirebaseFirestore.instance
            .collection('donor_profiles')
            .doc(credential.user!.uid)
            .get();

        final donorsDoc = await FirebaseFirestore.instance
            .collection('donors')
            .doc(credential.user!.uid)
            .get();

        if (donorProfilesDoc.exists || donorsDoc.exists) {
          if (mounted) {
            AppHelpers.showSuccessSnackBar(context, 'Login successful!');
            Navigator.pushReplacementNamed(context, '/donor-dashboard');
          }
        } else {
          // User exists but is not a donor
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            AppHelpers.showErrorSnackBar(
                context, 'This account is not registered as a donor');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No donor found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = e.message ?? 'Login failed';
      }

      if (mounted) {
        AppHelpers.showErrorSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: AppHelpers.getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: AppHelpers.getResponsiveConstraints(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            size: AppHelpers.getResponsiveIconSize(context, 64),
                            color: AppTheme.surfaceWhite,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Donor Portal',
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
                            'Sign in to access donor features',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.surfaceWhite.withOpacity(0.9),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Form
                    CustomCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign In',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your email address',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  Validators.validateEmail(value),
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) =>
                                  Validators.validatePassword(value),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'Sign In',
                              onPressed: _isLoading ? null : _login,
                              icon: Icons.login,
                              isLoading: _isLoading,
                              width: double.infinity,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DonorRegistrationPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppHelpers.getResponsiveSpacing(
                                        context, 16),
                                    vertical: AppHelpers.getResponsiveSpacing(
                                        context, 8),
                                  ),
                                  minimumSize: Size(
                                    AppHelpers.getResponsiveSpacing(
                                        context, 120),
                                    AppHelpers.getResponsiveButtonHeight(
                                            context) *
                                        0.7,
                                  ),
                                ),
                                child: Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppHelpers.getResponsiveFontSize(
                                        context, 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
