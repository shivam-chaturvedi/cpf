// ignore_for_file: unused_field

import 'package:cpf_portal/util/validators.dart';
import 'package:cpf_portal/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/constants.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'package:cpf_portal/providers/firestore_file_service.dart';
import '../widgets/custom_button.dart';

// Phase 1: Initial Account Creation
class NGORegistrationPage extends StatefulWidget {
  const NGORegistrationPage({super.key});

  @override
  State<NGORegistrationPage> createState() => _NGORegistrationPageState();
}

class _NGORegistrationPageState extends State<NGORegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Initial registration fields
  final _ngoNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _ngoNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccountAndProceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get form values
      final ngoName = _ngoNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      // Validate all fields are filled
      if (ngoName.isEmpty ||
          email.isEmpty ||
          phone.isEmpty ||
          password.isEmpty) {
        AppHelpers.showErrorSnackBar(
            context, 'Please fill in all required fields');
        setState(() => _isLoading = false);
        return;
      }
      // Step 1: Create Firebase Auth user
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Step 2: Update display name
      await userCredential.user!.updateDisplayName(ngoName);

      // Step 3: Create initial Firestore document with basic info
      await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .doc(uid)
          .set({
        'ngoName': ngoName,
        'email': email,
        'phone': phone,
        'uid': uid,
        'registrationStatus': 'pending_verification',
        'profileComplete': false,
        'verificationStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending_verification',
      });

      // Step 4: Navigate to NGO dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/ngo-dashboard');
        AppHelpers.showSuccessSnackBar(context,
            'Registration submitted for verification. Admin will contact you soon.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email address.';
            break;
          case 'weak-password':
            errorMessage =
                'The password is too weak. Please use at least 6 characters.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'operation-not-allowed':
            errorMessage =
                'Email/password accounts are not enabled. Please contact support.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
        AppHelpers.showErrorSnackBar(context, errorMessage);
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
        title: const Text('NGO Registration'),
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: CustomCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 48,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Create Your Account',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your registration process',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    CustomTextField(
                      controller: _ngoNameController,
                      label: 'NGO Name *',
                      hint: 'Enter your organization name',
                      icon: Icons.business,
                      validator: Validators.validateNGOName,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address *',
                      hint: 'Enter email for login',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      hint: 'Enter your contact number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 20),

                    CustomPasswordField(
                      controller: _passwordController,
                      label: 'Password *',
                      hint: 'Create strong password (min 6 chars)',
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 20),

                    CustomPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password *',
                      hint: 'Re-enter password',
                      validator: (value) => Validators.validateConfirmPassword(
                          value, _passwordController.text),
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Submit for Verification',
                      onPressed: _createAccountAndProceed,
                      isLoading: _isLoading,
                      icon: Icons.check_circle,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'After submission, admin will contact you for verification. You can then complete your profile in the dashboard.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryRed,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/ngo-login'),
                          child: const Text('Login here'),
                        ),
                      ],
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

// Phase 2: Complete Profile Page
class NGOCompleteProfilePage extends StatefulWidget {
  final String uid;

  const NGOCompleteProfilePage({super.key, required this.uid});

  @override
  State<NGOCompleteProfilePage> createState() => _NGOCompleteProfilePageState();
}

class _NGOCompleteProfilePageState extends State<NGOCompleteProfilePage> {
  final _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(7, (index) => GlobalKey<FormState>());
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _ngoName;
  String? _email;

  // Section A: Basic Details (remaining fields)
  final _dateOfRegistrationController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;
  final _districtController = TextEditingController();

  // Section B: Chief Functionary
  final _chiefNameController = TextEditingController();
  final _chiefEmailController = TextEditingController();
  final _chiefPhoneController = TextEditingController();

  // Section C: Contacts (1-3)
  final List<TextEditingController> _contactNameControllers =
      List.generate(3, (index) => TextEditingController());
  final List<TextEditingController> _contactEmailControllers =
      List.generate(3, (index) => TextEditingController());
  final List<TextEditingController> _contactPhoneControllers =
      List.generate(3, (index) => TextEditingController());

  // Section E: Financial + Legal Documents
  String? _selectedFinancialYear;
  final _grossAmountController = TextEditingController();
  final _panController = TextEditingController();
  final _tanController = TextEditingController();
  final _fcraController = TextEditingController();
  final _csrController = TextEditingController();
  final _darpanController = TextEditingController();
  final _gstController = TextEditingController();
  final _professionalTaxController = TextEditingController();
  final _cert12AController = TextEditingController();
  final _cert80GController = TextEditingController();
  final _registrationCertController = TextEditingController();
  String? _selectedLegalStatus;
  List<String> _selectedSectors = [];
  final _otherSectorsController = TextEditingController();
  final _networksController = TextEditingController();

  // UPDATED: Document metadata storage instead of PlatformFile
  Map<String, Map<String, dynamic>?> _documentMetadata = {
    'itr': null,
    'audit_reports': null,
    'pf_registration': null,
    'pan_doc': null,
    'tan_doc': null,
    'fcra_doc': null,
    'fcra_bank_change': null,
    'csr_doc': null,
    'darpan_doc': null,
    'gst_doc': null,
    'professional_tax_doc': null,
    'legal_status_doc': null,
    '12a_doc': null,
    '80g_doc': null,
    'registration_cert_doc': null,
    // Enhanced legal documents
    'annual_reports': null,
    'form_10b': null,
    'pf_receipts': null,
    'tan_receipts': null,
    'annual_return_proof': null,
  };

  // Enhanced audit reports storage (multiple files per year)
  Map<String, List<Map<String, dynamic>>> _auditReportsByYear = {
    '2023-24': [],
    '2022-23': [],
    '2021-22': [],
  };

  // Section F: Social Media
  final Map<String, bool> _socialMediaPresence = {
    'facebook': false,
    'twitter': false,
    'linkedin': false,
    'instagram': false,
    'other': false,
  };
  final Map<String, TextEditingController> _socialMediaControllers = {
    'facebook': TextEditingController(),
    'twitter': TextEditingController(),
    'linkedin': TextEditingController(),
    'instagram': TextEditingController(),
    'other': TextEditingController(),
  };

  // Section G: Address Details
  final _registeredAddressController = TextEditingController();
  final _correspondingAddressController = TextEditingController();

  // Section H: Policies & Compliance
  final Map<String, bool> _policyCompliance = {
    'hr_policy': false,
    'finance_policy': false,
    'child_protection_policy': false,
    'anti_corruption_policy': false,
    'data_protection_policy': false,
    'whistleblower_policy': false,
  };

  final Map<String, String> _policyReasons = {
    'hr_policy': '',
    'finance_policy': '',
    'child_protection_policy': '',
    'anti_corruption_policy': '',
    'data_protection_policy': '',
    'whistleblower_policy': '',
  };

  final Map<String, PlatformFile?> _policyDocuments = {
    'hr_policy': null,
    'finance_policy': null,
    'child_protection_policy': null,
    'anti_corruption_policy': null,
    'data_protection_policy': null,
    'whistleblower_policy': null,
  };

  final List<String> _stepTitles = [
    'Basic Details',
    'Chief Functionary',
    'Contacts (1-3)',
    'Financial + Legal Docs',
    'Policies & Compliance',
    'Social Media Links',
    'Address Details',
  ];

  final List<String> _countries = ['India', 'Other'];

  // Complete list of Indian states and union territories
  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // Financial years from 5 years back to current year
  List<String> get _financialYears {
    final currentYear = DateTime.now().year;
    final List<String> years = [];

    // Add 5 years back to current year
    for (int i = 5; i >= 0; i--) {
      final year = currentYear - i;
      years.add('${year}-${(year + 1).toString().substring(2)}');
    }

    return years;
  }

  final List<String> _legalStatuses = [
    'Society',
    'Trust',
    'Section 8',
    'Other'
  ];
  final List<String> _sectors = [
    'Education',
    'Health',
    'Environment',
    'Women Empowerment',
    'Child Development',
    'Rural Development',
    'Disaster Relief',
    'Animal Welfare',
    'Arts & Culture',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = 0; // Always start from step 1 (index 0)
    _loadExistingData();
  }

  @override
  void dispose() {
    _dateOfRegistrationController.dispose();
    _districtController.dispose();
    _chiefNameController.dispose();
    _chiefEmailController.dispose();
    _chiefPhoneController.dispose();

    for (var controller in _contactNameControllers) controller.dispose();
    for (var controller in _contactEmailControllers) controller.dispose();
    for (var controller in _contactPhoneControllers) controller.dispose();

    _grossAmountController.dispose();
    _panController.dispose();
    _tanController.dispose();
    _fcraController.dispose();
    _csrController.dispose();
    _darpanController.dispose();
    _gstController.dispose();
    _professionalTaxController.dispose();
    _cert12AController.dispose();
    _cert80GController.dispose();
    _registrationCertController.dispose();
    _networksController.dispose();
    _otherSectorsController.dispose();

    for (var controller in _socialMediaControllers.values) controller.dispose();

    _registeredAddressController.dispose();
    _correspondingAddressController.dispose();
    _pageController.dispose();

    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .doc(widget.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Load basic info
        _ngoName = data['ngoName'];
        _email = data['email'];
        _currentStep = 0; // Always start from step 1 (index 0)

        // Load form data if exists
        if (data['dateOfRegistration'] != null) {
          _dateOfRegistrationController.text = data['dateOfRegistration'];
        }
        _selectedCountry = data['country'];
        _selectedState = data['state'];
        _districtController.text = data['district'] ?? '';

        // Chief Functionary
        if (data['chiefFunctionaryName'] != null) {
          _chiefNameController.text = data['chiefFunctionaryName'];
          _chiefEmailController.text = data['chiefFunctionaryEmail'] ?? '';
          _chiefPhoneController.text = data['chiefFunctionaryPhone'] ?? '';
        }

        // Contact Persons
        if (data['contactPersons'] != null) {
          final contacts = data['contactPersons'] as List;
          for (int i = 0; i < contacts.length && i < 3; i++) {
            _contactNameControllers[i].text = contacts[i]['name'] ?? '';
            _contactEmailControllers[i].text = contacts[i]['email'] ?? '';
            _contactPhoneControllers[i].text = contacts[i]['phone'] ?? '';
          }
        }

        // Financial
        _selectedFinancialYear = data['financialYear'];
        if (data['grossAmountRaised'] != null) {
          _grossAmountController.text = data['grossAmountRaised'].toString();
        }
        _panController.text = data['pan'] ?? '';
        _tanController.text = data['tan'] ?? '';
        _fcraController.text = data['fcraRegistration'] ?? '';
        _csrController.text = data['csrRegistration'] ?? '';
        _darpanController.text = data['darpanId'] ?? '';
        _gstController.text = data['gstRegistration'] ?? '';
        _professionalTaxController.text =
            data['professionalTaxRegistration'] ?? '';
        _cert12AController.text = data['cert12A'] ?? '';
        _cert80GController.text = data['cert80G'] ?? '';
        _registrationCertController.text = data['registrationCertNumber'] ?? '';
        _selectedLegalStatus = data['legalStatus'];

        if (data['sectorOfWork'] != null) {
          _selectedSectors = List<String>.from(data['sectorOfWork']);
        }
        _otherSectorsController.text = data['otherSectors'] ?? '';
        _networksController.text = data['networks'] ?? '';

        // UPDATED: Load document metadata instead of URLs
        if (data['documents'] != null) {
          final documents = data['documents'] as Map<String, dynamic>;
          documents.forEach((key, value) {
            if (_documentMetadata.containsKey(key) && value != null) {
              _documentMetadata[key] = Map<String, dynamic>.from(value);
            }
          });
        }

        // Load audit reports by year
        if (data['auditReportsByYear'] != null) {
          final auditReports =
              data['auditReportsByYear'] as Map<String, dynamic>;
          auditReports.forEach((year, files) {
            if (_auditReportsByYear.containsKey(year) && files != null) {
              _auditReportsByYear[year] =
                  List<Map<String, dynamic>>.from(files);
            }
          });
        }

        // Social Media
        if (data['socialMediaPresence'] != null) {
          final socialMedia = data['socialMediaPresence'] as Map;
          socialMedia.forEach((key, value) {
            if (_socialMediaPresence.containsKey(key)) {
              _socialMediaPresence[key] = value;
            }
          });
        }

        if (data['socialMediaUrls'] != null) {
          final urls = data['socialMediaUrls'] as Map;
          urls.forEach((key, value) {
            if (_socialMediaControllers.containsKey(key)) {
              _socialMediaControllers[key]!.text = value;
            }
          });
        }

        // Addresses
        _registeredAddressController.text = data['registeredAddress'] ?? '';
        _correspondingAddressController.text =
            data['correspondingAddress'] ?? '';

        // Load uploaded documents
        await _loadUploadedDocuments();
      }
    } catch (e) {
      print('Error loading data: $e');
      // Remove error toast - continue silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load uploaded documents from Firebase
  Future<void> _loadUploadedDocuments() async {
    try {
      final documents = await FirestoreFileService.getUploadedDocuments(
        ngoId: widget.uid,
      );

      setState(() {
        for (final doc in documents) {
          final documentType = doc['documentType'] as String;
          if (_documentMetadata.containsKey(documentType)) {
            _documentMetadata[documentType] = {
              'filename': doc['fileName'],
              'download_url': doc['downloadUrl'],
              'file_path': doc['filePath'],
              'file_size': doc['fileSize'],
              'original_name': doc['originalName'],
              'uploaded_at': doc['uploadedAt'],
            };
          }
        }
      });
    } catch (e) {
      // Error loading documents - continue silently
    }
  }

  // UPDATED: New method for Plesk file upload
  Future<void> _pickAndUploadFile(String documentType) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file
        if (!FirestoreFileService.validateFile(file)) {
          return; // Invalid file - continue silently
        }

        // Check file size limit based on document type
        int maxSize = documentType.contains('audit')
            ? AppConstants.maxAuditFileSize
            : AppConstants.maxFileSize;
        if (file.size > maxSize) {
          return; // File too large - continue silently
        }

        // Show upload progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading document...'),
              ],
            ),
          ),
        );

        try {
          // Upload to Plesk server
          final uploadResult = await FirestoreFileService.uploadFile(
            ngoId: widget.uid,
            documentType: documentType,
            file: file,
          );

          // Close progress dialog
          Navigator.pop(context);

          if (uploadResult != null) {
            setState(() {
              _documentMetadata[documentType] = {
                'filename': uploadResult['filename'],
                'download_url': uploadResult['download_url'],
                'file_path': uploadResult['file_path'],
                'file_size': uploadResult['file_size'],
                'original_name': file.name,
                'uploaded_at': DateTime.now().toIso8601String(),
              };
            });

            // File uploaded successfully - no toast message
          }
        } catch (e) {
          // Close progress dialog
          Navigator.pop(context);
          // Upload failed - continue silently
        }
      }
    } catch (e) {
      // Error selecting file - continue silently
    }
  }

  Future<void> _saveProgress({bool showMessage = true}) async {
    // Validate current step before saving
    if (_currentStep == 3) {
      // Financial + Legal Docs section
      if (!_validateFinancialSection()) {
        print('🚫 Save Progress cancelled due to validation failure');
        return;
      }
    } else if (_currentStep == 4) {
      // Policies & Compliance section
      if (!_validatePoliciesSection()) {
        print('🚫 Save Progress cancelled due to validation failure');
        return;
      }
    }

    print('💾 Starting save progress...');
    setState(() => _isSaving = true);

    try {
      // Prepare data based on current step
      Map<String, dynamic> updateData = {
        'currentStep': _currentStep,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add data based on which sections have been filled
      // Section A
      if (_dateOfRegistrationController.text.isNotEmpty) {
        updateData['dateOfRegistration'] = _dateOfRegistrationController.text;
      }
      if (_selectedCountry != null) updateData['country'] = _selectedCountry;
      if (_selectedState != null) updateData['state'] = _selectedState;
      if (_districtController.text.isNotEmpty)
        updateData['district'] = _districtController.text;

      // Section B
      if (_chiefNameController.text.isNotEmpty) {
        updateData['chiefFunctionaryName'] = _chiefNameController.text;
        updateData['chiefFunctionaryEmail'] = _chiefEmailController.text;
        updateData['chiefFunctionaryPhone'] = _chiefPhoneController.text;
      }

      // Section C
      List<Map<String, String>> contactPersons = [];
      for (int i = 0; i < 3; i++) {
        if (_contactNameControllers[i].text.isNotEmpty) {
          contactPersons.add({
            'name': _contactNameControllers[i].text,
            'email': _contactEmailControllers[i].text,
            'phone': _contactPhoneControllers[i].text,
          });
        }
      }
      if (contactPersons.isNotEmpty) {
        updateData['contactPersons'] = contactPersons;
      }

      // Section E (D removed)
      if (_selectedFinancialYear != null) {
        updateData['financialYear'] = _selectedFinancialYear;
      }
      if (_grossAmountController.text.isNotEmpty) {
        updateData['grossAmountRaised'] =
            double.tryParse(_grossAmountController.text) ?? 0.0;
      }
      if (_panController.text.isNotEmpty)
        updateData['pan'] = _panController.text;
      if (_tanController.text.isNotEmpty)
        updateData['tan'] = _tanController.text;
      if (_fcraController.text.isNotEmpty)
        updateData['fcraRegistration'] = _fcraController.text;
      if (_csrController.text.isNotEmpty)
        updateData['csrRegistration'] = _csrController.text;
      if (_darpanController.text.isNotEmpty)
        updateData['darpanId'] = _darpanController.text;
      if (_gstController.text.isNotEmpty)
        updateData['gstRegistration'] = _gstController.text;
      if (_professionalTaxController.text.isNotEmpty) {
        updateData['professionalTaxRegistration'] =
            _professionalTaxController.text;
      }
      if (_cert12AController.text.isNotEmpty)
        updateData['cert12A'] = _cert12AController.text;
      if (_cert80GController.text.isNotEmpty)
        updateData['cert80G'] = _cert80GController.text;
      if (_registrationCertController.text.isNotEmpty) {
        updateData['registrationCertNumber'] = _registrationCertController.text;
      }
      if (_selectedLegalStatus != null)
        updateData['legalStatus'] = _selectedLegalStatus;
      if (_selectedSectors.isNotEmpty)
        updateData['sectorOfWork'] = _selectedSectors;
      if (_otherSectorsController.text.isNotEmpty)
        updateData['otherSectors'] = _otherSectorsController.text;
      if (_networksController.text.isNotEmpty)
        updateData['networks'] = _networksController.text;

      // UPDATED: Save document metadata
      Map<String, dynamic> documentsToSave = {};
      _documentMetadata.forEach((key, value) {
        if (value != null) {
          documentsToSave[key] = value;
        }
      });
      if (documentsToSave.isNotEmpty) {
        updateData['documents'] = documentsToSave;
      }

      // Save audit reports by year
      Map<String, dynamic> auditReportsToSave = {};
      _auditReportsByYear.forEach((year, files) {
        if (files.isNotEmpty) {
          auditReportsToSave[year] = files;
        }
      });
      if (auditReportsToSave.isNotEmpty) {
        updateData['auditReportsByYear'] = auditReportsToSave;
      }

      // Section H: Policies & Compliance
      updateData['policyCompliance'] = _policyCompliance;
      updateData['policyReasons'] = _policyReasons;

      // Save policy documents metadata (without file bytes)
      Map<String, dynamic> policyDocumentsToSave = {};
      _policyDocuments.forEach((key, file) {
        if (file != null) {
          policyDocumentsToSave[key] = {
            'name': file.name,
            'size': file.size,
            'extension': file.extension,
            'path': file.path,
            // Removed 'bytes' to prevent Firestore size limit issues
          };
        }
      });
      if (policyDocumentsToSave.isNotEmpty) {
        updateData['policyDocuments'] = policyDocumentsToSave;
      }

      // Section F
      updateData['socialMediaPresence'] = _socialMediaPresence;
      Map<String, String> socialMediaUrls = {};
      _socialMediaPresence.forEach((platform, isActive) {
        if (isActive && _socialMediaControllers[platform]!.text.isNotEmpty) {
          socialMediaUrls[platform] = _socialMediaControllers[platform]!.text;
        }
      });
      if (socialMediaUrls.isNotEmpty) {
        updateData['socialMediaUrls'] = socialMediaUrls;
      }

      // Section G
      if (_registeredAddressController.text.isNotEmpty) {
        updateData['registeredAddress'] = _registeredAddressController.text;
      }
      if (_correspondingAddressController.text.isNotEmpty) {
        updateData['correspondingAddress'] =
            _correspondingAddressController.text;
      }

      await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .doc(widget.uid)
          .update(updateData);

      if (mounted && showMessage) {
        print('✅ Save progress completed successfully');
        AppHelpers.showSuccessSnackBar(context, 'Progress saved successfully');
      }
    } catch (e) {
      print('Error saving progress: $e');
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to save progress');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _nextStep() async {
    // Additional validation for specific sections
    if (_currentStep == 3) {
      // Financial + Legal Docs section
      if (!_validateFinancialSection()) {
        return;
      }
    } else if (_currentStep == 4) {
      // Policies & Compliance section
      if (!_validatePoliciesSection()) {
        return;
      }
    }

    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      // Save progress before moving to next step
      await _saveProgress(showMessage: false);

      if (_currentStep < _stepTitles.length - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // UPDATED: Final submission with document metadata
  Future<void> _submitFinalRegistration() async {
    // Validate all sections before final submission
    if (!_validateFinancialSection()) {
      return;
    }
    if (!_validatePoliciesSection()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare contact persons data
      List<Map<String, String>> contactPersons = [];
      for (int i = 0; i < 3; i++) {
        if (_contactNameControllers[i].text.isNotEmpty) {
          contactPersons.add({
            'name': _contactNameControllers[i].text.trim(),
            'email': _contactEmailControllers[i].text.trim(),
            'phone': _contactPhoneControllers[i].text.trim(),
          });
        }
      }

      // Prepare social media data
      Map<String, String> socialMediaUrls = {};
      _socialMediaPresence.forEach((platform, isSelected) {
        if (isSelected && _socialMediaControllers[platform]!.text.isNotEmpty) {
          socialMediaUrls[platform] =
              _socialMediaControllers[platform]!.text.trim();
        }
      });

      // Filter uploaded documents
      Map<String, dynamic> uploadedDocuments = {};
      _documentMetadata.forEach((key, value) {
        if (value != null) {
          uploadedDocuments[key] = value;
        }
      });

      // Update Firestore with complete data
      final completeData = {
        // Basic Details
        'dateOfRegistration': _dateOfRegistrationController.text.trim(),
        'country': _selectedCountry ?? '',
        'state': _selectedState ?? '',
        'district': _districtController.text.trim(),

        // Chief Functionary
        'chiefFunctionaryName': _chiefNameController.text.trim(),
        'chiefFunctionaryEmail': _chiefEmailController.text.trim(),
        'chiefFunctionaryPhone': _chiefPhoneController.text.trim(),

        // Contact Persons
        'contactPersons': contactPersons,

        // Financial + Legal
        'financialYear': _selectedFinancialYear ?? '',
        'grossAmountRaised':
            double.tryParse(_grossAmountController.text) ?? 0.0,
        'pan': _panController.text.trim(),
        'tan': _tanController.text.trim(),
        'fcraRegistration': _fcraController.text.trim(),
        'csrRegistration': _csrController.text.trim(),
        'darpanId': _darpanController.text.trim(),
        'gstRegistration': _gstController.text.trim(),
        'professionalTaxRegistration': _professionalTaxController.text.trim(),
        'legalStatus': _selectedLegalStatus ?? '',
        'cert12A': _cert12AController.text.trim(),
        'cert80G': _cert80GController.text.trim(),
        'registrationCertNumber': _registrationCertController.text.trim(),
        'sectorOfWork': _selectedSectors,
        'otherSectors': _otherSectorsController.text.trim(),
        'networks': _networksController.text.trim(),

        // Social Media
        'socialMediaPresence': _socialMediaPresence,
        'socialMediaUrls': socialMediaUrls,

        // Address
        'registeredAddress': _registeredAddressController.text.trim(),
        'correspondingAddress': _correspondingAddressController.text.trim(),

        // UPDATED: Document metadata instead of URLs
        'documents': uploadedDocuments,

        // Enhanced audit reports by year
        'auditReportsByYear': _auditReportsByYear,

        // Policies & Compliance
        'policyCompliance': _policyCompliance,
        'policyReasons': _policyReasons,
        'policyDocuments': _policyDocuments.map((key, file) => MapEntry(
            key,
            file != null
                ? {
                    'name': file.name,
                    'size': file.size,
                    'extension': file.extension,
                    'path': file.path,
                    // Removed 'bytes' to prevent Firestore size limit issues
                  }
                : null)),

        // Update status
        'status': 'pending',
        'profileComplete': true,
        'registrationStatus': 'complete',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .doc(widget.uid)
          .update(completeData);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('Error submitting registration: $e');
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Submission failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: AppTheme.surfaceWhite, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your NGO profile is now complete and pending admin approval.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.primaryRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processing time: 5-10 working days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryRed,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Go to Dashboard',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/ngo-dashboard',
                  (route) => false,
                );
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Progress?'),
        content: const Text(
            'Would you like to save your progress before logging out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Logout without saving'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProgress();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Save and Logout'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Back?'),
        content: const Text(
            'Would you like to save your progress before going back to dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Go back without saving'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveProgress();
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Save and Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        appBar: AppBar(
          title: Text('Complete Profile - $_ngoName'),
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
            tooltip: 'Go Back',
          ),
          actions: [
            TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isSaving ? null : _saveProgress,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Progress'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSectionA(), // Basic Details
                        _buildSectionB(), // Chief Functionary
                        _buildSectionC(), // Contacts
                        _buildSectionE(), // Financial
                        _buildSectionH(), // Policies & Compliance
                        _buildSectionF(), // Social Media
                        _buildSectionG(), // Address
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _stepTitles[_currentStep],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of ${_stepTitles.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _stepTitles.length,
            backgroundColor: AppTheme.borderGray,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomCard(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  // Section A: Basic Details
  Widget _buildSectionA() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Basic Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _dateOfRegistrationController,
              label: 'Date of Registration *',
              hint: 'Select registration date',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dateOfRegistrationController.text =
                      '${date.day}/${date.month}/${date.year}';
                }
              },
              validator: (value) =>
                  Validators.validateRequired(value, 'Date of Registration'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: const InputDecoration(
                labelText: 'Country *',
                prefixIcon: Icon(Icons.public),
              ),
              items: _countries
                  .map((country) => DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCountry = value),
              validator: (value) =>
                  value == null ? 'Please select country' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State *',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _states
                  .map((state) => DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedState = value),
              validator: (value) =>
                  value == null ? 'Please select state' : null,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _districtController,
              label: 'District *',
              hint: 'Enter district name',
              icon: Icons.location_on,
              validator: (value) =>
                  Validators.validateRequired(value, 'District'),
            ),
          ],
        ),
      ),
    );
  }

  // Section B: Chief Functionary
  Widget _buildSectionB() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chief Functionary Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _chiefNameController,
              label: 'Chief Functionary Name *',
              hint: 'Enter full name',
              icon: Icons.person,
              validator: (value) =>
                  Validators.validateRequired(value, 'Chief Functionary Name'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _chiefEmailController,
              label: 'Chief Functionary Email *',
              hint: 'Enter email address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _chiefPhoneController,
              label: 'Chief Functionary Phone *',
              hint: 'Enter mobile number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhoneNumber,
            ),
          ],
        ),
      ),
    );
  }

  // Section C: Contacts (1-3)
  Widget _buildSectionC() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[2],
        child: Column(
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.surfaceWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Contact Person ${index + 1}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (index > 0) ...[
                        const Spacer(),
                        Text(
                          'Optional',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _contactNameControllers[index],
                    label: 'Name ${index == 0 ? '*' : ''}',
                    hint: 'Enter contact name',
                    icon: Icons.person_outline,
                    validator: index == 0
                        ? (value) =>
                            Validators.validateRequired(value, 'Contact Name')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _contactEmailControllers[index],
                    label: 'Email ${index == 0 ? '*' : ''}',
                    hint: 'Enter email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: index == 0 ? Validators.validateEmail : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _contactPhoneControllers[index],
                    label: 'Phone ${index == 0 ? '*' : ''}',
                    hint: 'Enter phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator:
                        index == 0 ? Validators.validatePhoneNumber : null,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // Section E: Financial + Legal Documents
  Widget _buildSectionE() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial & Legal Documents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFinancialYear,
                    decoration: const InputDecoration(
                      labelText: 'Financial Year *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: _financialYears
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedFinancialYear = value),
                    validator: (value) =>
                        value == null ? 'Please select financial year' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _grossAmountController,
                    label: 'Gross Inflow *',
                    hint: 'Enter amount in INR',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.validateRequired(value, 'Gross Inflow'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Document uploads with text fields
            _buildDocumentWithTextField(
                'Copy of Latest ITR Acknowledgment', 'itr', null),
            // Enhanced Audit Reports Section
            _buildAuditReportsSection(),
            _buildDocumentWithTextField(
                'Provident Fund Registration', 'pf_registration', null),
            _buildDocumentWithTextField(
                'PAN Card (Mandatory)', 'pan_doc', _panController,
                isMandatory: true),
            _buildDocumentWithTextField('TAN', 'tan_doc', _tanController),
            _buildDocumentWithTextField(
                'FCRA Registration Number', 'fcra_doc', _fcraController),
            _buildDocumentWithTextField(
                'FCRA Bank Account Change Letter from MHA',
                'fcra_bank_change',
                null),
            _buildDocumentWithTextField(
                'CSR Registration', 'csr_doc', _csrController),
            _buildDocumentWithTextField(
                'DARPAN ID', 'darpan_doc', _darpanController),
            _buildDocumentWithTextField(
                'GST Registration (If applicable)', 'gst_doc', _gstController),
            _buildDocumentWithTextField(
                'Professional Tax Registration (If applicable)',
                'professional_tax_doc',
                _professionalTaxController),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLegalStatus,
              decoration: const InputDecoration(
                labelText: 'Legal Status *',
                prefixIcon: Icon(Icons.gavel),
              ),
              items: _legalStatuses
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedLegalStatus = value),
              validator: (value) =>
                  value == null ? 'Please select legal status' : null,
            ),
            const SizedBox(height: 20),

            _buildDocumentWithTextField(
                'Legal Status Document', 'legal_status_doc', null),
            _buildDocumentWithTextField(
                '12A Certification', '12a_doc', _cert12AController),
            _buildDocumentWithTextField(
                '80G Certificate', '80g_doc', _cert80GController),
            _buildDocumentWithTextField('Registration Certificate',
                'registration_cert_doc', _registrationCertController),

            const SizedBox(height: 20),

            // Additional Legal Documents Section
            _buildAdditionalLegalDocumentsSection(),

            const SizedBox(height: 20),

            // Sector of Work (Multi-select)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sector of Work *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sectors.map((sector) {
                      final isSelected = _selectedSectors.contains(sector);
                      return FilterChip(
                        label: Text(sector),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSectors.add(sector);
                            } else {
                              _selectedSectors.remove(sector);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryRed,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _otherSectorsController,
                    label: 'Other Thematic Areas',
                    hint: 'Enter additional thematic areas not listed above',
                    icon: Icons.add_circle_outline,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            CustomTextField(
              controller: _networksController,
              label: 'List of Networks',
              hint: 'Enter network affiliations',
              icon: Icons.group,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Section F: Social Media Links
  Widget _buildSectionF() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Media Presence',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 24),
            ..._socialMediaPresence.keys.map((platform) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text(platform.toUpperCase()),
                      value: _socialMediaPresence[platform],
                      onChanged: (value) {
                        setState(() {
                          _socialMediaPresence[platform] = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_socialMediaPresence[platform]!) ...[
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _socialMediaControllers[platform]!,
                        label: '$platform URL',
                        hint: 'https://$platform.com/your-ngo',
                        icon: Icons.link,
                        keyboardType: TextInputType.url,
                        validator: Validators.validateUrl,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Section G: Address Details
  Widget _buildSectionG() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[6],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _registeredAddressController,
              label: 'Registered Address *',
              hint: 'Enter complete registered address',
              icon: Icons.location_on,
              maxLines: 4,
              validator: (value) =>
                  Validators.validateRequired(value, 'Registered Address'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _correspondingAddressController,
              label: 'Corresponding Address',
              hint: 'Enter correspondence address (if different)',
              icon: Icons.mail,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If correspondence address is same as registered address, you can leave it blank.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryRed,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionH() {
    return _buildStepContainer(
      child: Form(
        key: _formKeys[4], // Policies & Compliance
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Policies & Compliance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please indicate whether your organization has the following policies in place. If not, please provide a reason and upload any relevant documentation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // HR Policy
            _buildPolicyComplianceItem(
              'HR Policy',
              'hr_policy',
              'Human Resources policies including recruitment, performance management, and employee welfare',
            ),

            const SizedBox(height: 20),

            // Finance Policy
            _buildPolicyComplianceItem(
              'Finance Policy',
              'finance_policy',
              'Financial management policies including budgeting, accounting, and financial controls',
            ),

            const SizedBox(height: 20),

            // Child Protection Policy
            _buildPolicyComplianceItem(
              'Child Protection Policy',
              'child_protection_policy',
              'Policies to protect children and vulnerable populations from harm',
            ),

            const SizedBox(height: 20),

            // Anti-Corruption Policy
            _buildPolicyComplianceItem(
              'Anti-Corruption Policy',
              'anti_corruption_policy',
              'Policies to prevent and address corruption, bribery, and unethical practices',
            ),

            const SizedBox(height: 20),

            // Data Protection Policy
            _buildPolicyComplianceItem(
              'Data Protection Policy',
              'data_protection_policy',
              'Policies for handling personal data and ensuring privacy protection',
            ),

            const SizedBox(height: 20),

            // Whistleblower Policy
            _buildPolicyComplianceItem(
              'Whistleblower Policy',
              'whistleblower_policy',
              'Policies for reporting misconduct and protecting whistleblowers',
            ),

            const SizedBox(height: 24),

            // Admin Validation Workflow Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Validation Workflow',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your submitted policies will undergo the following validation process:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildWorkflowStep('1. Compliance Check',
                      'Review of policy completeness and format'),
                  _buildWorkflowStep('2. Due Diligence',
                      'Verification of policy implementation and effectiveness'),
                  _buildWorkflowStep('3. Desk Review',
                      'Final assessment and approval by admin team'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyComplianceItem(
      String title, String policyKey, String description) {
    final hasPolicy = _policyCompliance[policyKey] ?? false;
    final reason = _policyReasons[policyKey] ?? '';
    final document = _policyDocuments[policyKey];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Yes/No Toggle
          Row(
            children: [
              Text(
                'Does your organization have this policy?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _policyCompliance[policyKey] = true;
                        _policyReasons[policyKey] = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasPolicy
                            ? AppTheme.primaryGreen
                            : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasPolicy
                              ? AppTheme.primaryGreen
                              : AppTheme.borderGray,
                        ),
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: hasPolicy
                              ? AppTheme.surfaceWhite
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _policyCompliance[policyKey] = false;
                        _policyReasons[policyKey] = '';
                        _policyDocuments[policyKey] = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !hasPolicy
                            ? AppTheme.errorRed
                            : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !hasPolicy
                              ? AppTheme.errorRed
                              : AppTheme.borderGray,
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: !hasPolicy
                              ? AppTheme.surfaceWhite
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // If No, show reason field
          if (!hasPolicy) ...[
            CustomTextField(
              controller: TextEditingController(text: reason),
              label: 'Reason for not having this policy *',
              hint:
                  'Please explain why this policy is not applicable or available',
              icon: Icons.info_outline,
              maxLines: 3,
              onChanged: (value) {
                _policyReasons[policyKey] = value;
              },
              validator: (value) {
                if (!hasPolicy && (value == null || value.trim().isEmpty)) {
                  return 'Please provide a reason for not having this policy';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],

          // Document upload section
          if (hasPolicy) ...[
            Row(
              children: [
                Icon(Icons.upload_file, color: AppTheme.primaryRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Upload Policy Document',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const Spacer(),
                CustomButton(
                  text: document != null ? 'Change File' : 'Upload',
                  onPressed: () => _pickPolicyDocument(policyKey),
                  icon: Icons.upload,
                ),
              ],
            ),
            if (document != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _policyDocuments[policyKey] = null;
                        });
                      },
                      child: const Icon(Icons.close,
                          color: AppTheme.errorRed, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppTheme.primaryOrange,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '✓',
                style: TextStyle(
                  color: AppTheme.surfaceWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Audit Reports Section
  Widget _buildAuditReportsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGray),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.backgroundGray.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: AppTheme.primaryRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Audit Reports for Last 3 Years with Form 10B *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryRed,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload audit reports for the last 3 financial years. Each file can be up to 25MB. Multiple files allowed per year.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // Audit reports by year
          ..._auditReportsByYear.keys.map((year) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Financial Year: $year',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      CustomButton(
                        text: 'Add Files',
                        onPressed: () => _pickMultipleAuditFiles(year),
                        icon: Icons.add,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_auditReportsByYear[year]!.isNotEmpty) ...[
                    ..._auditReportsByYear[year]!.map((file) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: AppTheme.accentGold,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file['original_name'] ?? 'Unknown file',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              _formatFileSize(file['file_size'] ?? 0),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => _removeAuditFile(year, file),
                              color: AppTheme.errorRed,
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    Text(
                      'No files uploaded for $year',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Additional Legal Documents Section
  Widget _buildAdditionalLegalDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGray),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.backgroundGray.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_copy,
                color: AppTheme.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Additional Legal Documents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload additional supporting documents for comprehensive verification.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // Additional documents
          _buildFileUploadTile('Annual Reports', 'annual_reports'),
          _buildFileUploadTile('Form 10B', 'form_10b'),
          _buildFileUploadTile('PF Receipts', 'pf_receipts'),
          _buildFileUploadTile('TAN Receipts', 'tan_receipts'),
          _buildFileUploadTile('Annual Return Proof', 'annual_return_proof'),
        ],
      ),
    );
  }

  // UPDATED: New file upload tile with document metadata
  Widget _buildFileUploadTile(String label, String documentType,
      {bool isMandatory = false}) {
    final metadata = _documentMetadata[documentType];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isMandatory && metadata == null
              ? AppTheme.errorRed
              : AppTheme.borderGray,
          style: BorderStyle.solid,
          width: isMandatory && metadata == null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                metadata != null
                    ? Icons.check_circle
                    : Icons.cloud_upload_outlined,
                color: metadata != null
                    ? AppTheme.accentGold
                    : AppTheme.primaryRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isMandatory && metadata == null
                                ? AppTheme.errorRed
                                : AppTheme.textPrimary,
                          ),
                    ),
                    if (metadata != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ Uploaded',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          Text(
                            metadata['original_name'] ?? 'Unknown file',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentGold,
                                    ),
                          ),
                          Text(
                            'Size: ${_formatFileSize(metadata['file_size'] ?? 0)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'PDF, JPG, PNG (Max ${documentType.contains('audit') ? '25MB' : '50MB'})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              CustomButton(
                text: metadata != null ? 'Change' : 'Upload',
                onPressed: () => _pickAndUploadFile(documentType),
                icon: metadata != null ? Icons.edit : Icons.upload_file,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentWithTextField(
      String label, String documentType, TextEditingController? textController,
      {bool isMandatory = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textController != null) ...[
            CustomTextField(
              controller: textController,
              label: '$label Number${isMandatory ? ' *' : ''}',
              hint: 'Enter ${label.toLowerCase()} number',
              icon: Icons.numbers,
              validator: documentType == 'pan_doc'
                  ? Validators.validatePAN
                  : documentType == 'tan_doc'
                      ? Validators.validateTAN
                      : null,
              textCapitalization:
                  documentType == 'pan_doc' || documentType == 'tan_doc'
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
            ),
            const SizedBox(height: 8),
          ],
          _buildFileUploadTile(
              '$label Document${isMandatory ? ' *' : ''}', documentType,
              isMandatory: isMandatory),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _stepTitles.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(top: BorderSide(color: AppTheme.borderGray)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: CustomButton(
                text: 'Previous',
                onPressed: _isLoading ? null : _previousStep,
                icon: Icons.arrow_back,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: CustomButton(
              text: isLastStep ? 'Submit Registration' : 'Next',
              onPressed: isLastStep ? _submitFinalRegistration : _nextStep,
              icon: isLastStep ? Icons.cloud_upload : Icons.arrow_forward,
              isLoading: _isLoading,
              backgroundColor:
                  isLastStep ? AppTheme.accentGold : AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Helper method to get document display name for success messages
  String _getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case 'itr':
        return 'ITR Acknowledgment';
      case 'pf_registration':
        return 'Provident Fund Registration';
      case 'pan_doc':
        return 'PAN Card';
      case 'tan_doc':
        return 'TAN Document';
      case 'fcra_doc':
        return 'FCRA Registration';
      case 'fcra_bank_change':
        return 'FCRA Bank Change Letter';
      case 'csr_doc':
        return 'CSR Registration';
      case 'darpan_doc':
        return 'DARPAN ID';
      case 'gst_doc':
        return 'GST Registration';
      case 'professional_tax_doc':
        return 'Professional Tax Registration';
      case 'legal_status_doc':
        return 'Legal Status Document';
      case '12a_doc':
        return '12A Certification';
      case '80g_doc':
        return '80G Certificate';
      case 'registration_cert_doc':
        return 'Registration Certificate';
      case 'annual_reports':
        return 'Annual Reports';
      case 'form_10b':
        return 'Form 10B';
      case 'pf_receipts':
        return 'PF Receipts';
      case 'tan_receipts':
        return 'TAN Receipts';
      case 'annual_return_proof':
        return 'Annual Return Proof';
      default:
        return 'Document';
    }
  }

  // Validate Financial & Legal Documents section
  bool _validateFinancialSection() {
    List<String> errors = [];

    // Check PAN validation
    if (_panController.text.trim().isEmpty) {
      errors.add('PAN Card number is mandatory');
    } else {
      final panError = Validators.validatePAN(_panController.text);
      if (panError != null) {
        errors.add(panError);
      }
    }

    // Check TAN validation if provided
    if (_tanController.text.trim().isNotEmpty) {
      final tanError = Validators.validateTAN(_tanController.text);
      if (tanError != null) {
        errors.add(tanError);
      }
    }

    // Check mandatory PAN document upload
    if (_documentMetadata['pan_doc'] == null) {
      errors.add('PAN Card document upload is mandatory');
    }

    // Check audit reports for at least one year
    bool hasAuditReports = false;
    for (var year in _auditReportsByYear.keys) {
      if (_auditReportsByYear[year]!.isNotEmpty) {
        hasAuditReports = true;
        break;
      }
    }
    if (!hasAuditReports) {
      errors.add('At least one audit report is required for the last 3 years');
    }

    // Show errors if any
    if (errors.isNotEmpty) {
      // Reset saving state if validation fails
      setState(() => _isSaving = false);

      _showValidationErrorDialog(errors);
      return false;
    }

    return true;
  }

  // Show validation errors in a proper dialog
  void _showValidationErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Validation Errors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please fix the following issues before proceeding:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              ...errors.asMap().entries.map((entry) {
                final index = entry.key;
                final error = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryRed,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _validatePoliciesSection() {
    List<String> errors = [];

    // Check each policy
    for (var policyKey in _policyCompliance.keys) {
      final hasPolicy = _policyCompliance[policyKey] ?? false;
      final reason = _policyReasons[policyKey] ?? '';
      final document = _policyDocuments[policyKey];
      final policyName = _getPolicyDisplayName(policyKey);

      if (hasPolicy) {
        // If they have the policy, they must upload a document
        if (document == null) {
          errors.add(
              '$policyName document upload is mandatory when policy exists');
        }
      } else {
        // If they don't have the policy, they must provide a reason
        if (reason.trim().isEmpty) {
          errors.add('Reason is mandatory for not having $policyName');
        }
      }
    }

    // Show errors if any
    if (errors.isNotEmpty) {
      setState(() => _isSaving = false);
      _showValidationErrorDialog(errors);
      return false;
    }

    return true;
  }

  String _getPolicyDisplayName(String policyKey) {
    switch (policyKey) {
      case 'hr_policy':
        return 'HR Policy';
      case 'finance_policy':
        return 'Finance Policy';
      case 'child_protection_policy':
        return 'Child Protection Policy';
      case 'anti_corruption_policy':
        return 'Anti-Corruption Policy';
      case 'data_protection_policy':
        return 'Data Protection Policy';
      case 'whistleblower_policy':
        return 'Whistleblower Policy';
      default:
        return policyKey;
    }
  }

  // Pick multiple audit files for a specific year
  Future<void> _pickMultipleAuditFiles(String year) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Validate files
        for (var file in result.files) {
          if (!FirestoreFileService.validateFile(file)) {
            AppHelpers.showErrorSnackBar(context,
                'Invalid file: ${file.name}. Must be PDF, JPG, or PNG under 25MB');
            return;
          }

          // Check 25MB limit for audit reports
          if (file.size > AppConstants.maxAuditFileSize) {
            AppHelpers.showErrorSnackBar(
                context, 'File ${file.name} exceeds 25MB limit');
            return;
          }
        }

        // Check total files limit
        final currentFiles = _auditReportsByYear[year]!.length;
        if (currentFiles + result.files.length > AppConstants.maxAuditFiles) {
          AppHelpers.showErrorSnackBar(context,
              'Maximum ${AppConstants.maxAuditFiles} files allowed per year');
          return;
        }

        // Show upload progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('Uploading ${result.files.length} file(s)...'),
              ],
            ),
          ),
        );

        try {
          // Upload files
          for (var file in result.files) {
            final uploadResult = await FirestoreFileService.uploadFile(
              ngoId: widget.uid,
              documentType: 'audit_${year}_${file.name}',
              file: file,
            );

            if (uploadResult != null) {
              setState(() {
                _auditReportsByYear[year]!.add({
                  'filename': uploadResult['filename'],
                  'download_url': uploadResult['download_url'],
                  'file_path': uploadResult['file_path'],
                  'file_size': uploadResult['file_size'],
                  'original_name': file.name,
                  'uploaded_at': DateTime.now().toIso8601String(),
                  'year': year,
                });
              });
            }
          }

          // Close progress dialog
          Navigator.pop(context);
          AppHelpers.showSuccessSnackBar(
              context, '${result.files.length} file(s) uploaded successfully');
        } catch (e) {
          // Close progress dialog
          Navigator.pop(context);
          AppHelpers.showErrorSnackBar(context, 'Upload failed: $e');
        }
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error selecting files: $e');
    }
  }

  // Remove audit file
  void _removeAuditFile(String year, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove File'),
        content:
            Text('Are you sure you want to remove "${file['original_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _auditReportsByYear[year]!.remove(file);
              });
              Navigator.pop(context);
              AppHelpers.showSuccessSnackBar(
                  context, 'File removed successfully');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Pick policy document
  Future<void> _pickPolicyDocument(String policyKey) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file
        if (!FirestoreFileService.validateFile(file)) {
          AppHelpers.showErrorSnackBar(context,
              'Invalid file: ${file.name}. Must be PDF or DOC under 10MB');
          return;
        }

        // Check file size (10MB limit for policy documents)
        if (file.size > 10 * 1024 * 1024) {
          AppHelpers.showErrorSnackBar(
              context, 'File ${file.name} exceeds 10MB limit');
          return;
        }

        setState(() {
          _policyDocuments[policyKey] = file;
        });

        AppHelpers.showSuccessSnackBar(
            context, 'Policy document selected: ${file.name}');
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error selecting file: $e');
    }
  }
}
