import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/validators.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import 'package:cpf_portal/widgets/custom_text_field.dart';
import 'package:cpf_portal/widgets/custome_card.dart';

class DonorRegistrationPage extends StatefulWidget {
  const DonorRegistrationPage({super.key});

  @override
  State<DonorRegistrationPage> createState() => _DonorRegistrationPageState();
}

class _DonorRegistrationPageState extends State<DonorRegistrationPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedDonorType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _donorTypes = [
    'Individual',
    'Corporate',
    'Foundation',
    'Trust',
    'Government Agency',
    'International Organization',
  ];

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppHelpers.showErrorSnackBar(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        // Create donor profile in Firestore
        await FirebaseFirestore.instance
            .collection('donor_profiles')
            .doc(credential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'organization': _organizationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'donorType': _selectedDonorType,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send email verification
        await credential.user!.sendEmailVerification();

        if (mounted) {
          AppHelpers.showSuccessSnackBar(
            context, 
            'Registration successful! Please check your email to verify your account.'
          );
          Navigator.pushReplacementNamed(context, '/donor-login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }
      
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Registration failed: $e');
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
      appBar: AppBar(
        title: const Text('Donor Registration'),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header
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
                          Icons.people,
                          size: AppHelpers.getResponsiveIconSize(context, 64),
                          color: AppTheme.surfaceWhite,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Join as a Donor',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.surfaceWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help make a difference by supporting NGOs',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.surfaceWhite.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Registration Form
                  CustomCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Donor Account',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Personal Information
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name *',
                            hint: 'Enter your full name',
                            icon: Icons.person,
                            validator: (value) => Validators.validateRequired(value, 'Full Name'),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address *',
                            hint: 'Enter your email address',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => Validators.validateEmail(value),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) => Validators.validatePhone(value),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Donor Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedDonorType,
                            decoration: InputDecoration(
                              labelText: 'Donor Type *',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.borderGray),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.primaryRed),
                              ),
                            ),
                            items: _donorTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDonorType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a donor type';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _organizationController,
                            label: 'Organization/Company',
                            hint: 'Enter organization name (if applicable)',
                            icon: Icons.business,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'Enter your address',
                            icon: Icons.location_on,
                            maxLines: 3,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Security Information
                          Text(
                            'Security Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password *',
                            hint: 'Enter your password',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) => Validators.validatePassword(value),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password *',
                            hint: 'Confirm your password',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Terms and Conditions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppTheme.primaryRed, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Important Information',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Your account will be reviewed by our admin team before approval\n'
                                  '• You will receive an email notification once your account is approved\n'
                                  '• You can start supporting NGOs once your account is active',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          CustomButton(
                            text: 'Create Account',
                            onPressed: _isLoading ? null : _register,
                            icon: Icons.person_add,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/donor-login');
                              },
                              child: Text(
                                'Already have an account? Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w600,
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
