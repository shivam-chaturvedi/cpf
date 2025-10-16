// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/constants.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'package:cpf_portal/widgets/certificates_section.dart';
import 'package:cpf_portal/providers/firestore_file_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

import 'package:cpf_portal/providers/auth_provider.dart' as local_auth;
import 'package:cpf_portal/screens/ngo_registration.dart';

// Wrapper that checks profile completion status
class NGODashboardWrapper extends StatelessWidget {
  const NGODashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth.AuthProvider>(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ngo_proposals')
          .doc(authProvider.user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LoadingWidget()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child:
                  Text('NGO profile not found. Please complete registration.'),
            ),
          );
        }

        final ngoData = snapshot.data!.data() as Map<String, dynamic>;

        // Always return dashboard regardless of profile completion status
        return const NGODashboard();
      },
    );
  }
}

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For financial year data submission - Generic F.Y. labels
  String? _selectedFinancialYear;

  List<String> get _financialYears {
    return ['F.Y. 1', 'F.Y. 2', 'F.Y. 3'];
  }

  // UPDATED: Store multiple files per document type (metadata after Supabase upload)
  final Map<String, List<Map<String, dynamic>>> _yearlyDocuments = {};

  // UPDATED: For proposal submission - now stores metadata after upload
  final _proposalTitleController = TextEditingController();
  final _proposalDescriptionController = TextEditingController();
  final _proposalAmountController = TextEditingController();
  Map<String, dynamic>? _proposalDocumentMetadata;

  // Logo upload state
  Map<String, dynamic>? _logoMetadata;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _proposalTitleController.dispose();
    _proposalDescriptionController.dispose();
    _proposalAmountController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Error logging out: $e');
      }
    }
  }

  // UPDATED: Enhanced file picking and upload to Supabase - supports multiple files
  Future<void> _pickFile(String documentType,
      {bool allowMultiple = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
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
          List<Map<String, dynamic>> uploadedFiles = [];

          for (final file in result.files) {
            // Validate file
            if (!FirestoreFileService.validateFile(file)) {
              continue; // Skip invalid file
            }

            // Check file size limit based on document type
            int maxSize = documentType.contains('audit')
                ? AppConstants.maxAuditFileSize
                : AppConstants.maxFileSize;
            if (file.size > maxSize) {
              continue; // Skip file that's too large
            }

            // Upload to Supabase
            final uploadResult = await FirestoreFileService.uploadFile(
              ngoId: _auth.currentUser!.uid,
              documentType: documentType,
              file: file,
            );

            if (uploadResult != null) {
              uploadedFiles.add({
                'filename': uploadResult['filename'],
                'download_url': uploadResult['download_url'],
                'file_path': uploadResult['file_path'],
                'file_size': uploadResult['file_size'],
                'original_name': file.name,
                'uploaded_at': DateTime.now().toIso8601String(),
              });
            }
          }

          // Close progress dialog
          Navigator.pop(context);

          if (uploadedFiles.isNotEmpty) {
            if (documentType == 'proposal') {
              setState(() {
                _proposalDocumentMetadata = uploadedFiles.first;
              });
            } else {
              // For yearly documents - append to existing list
              setState(() {
                if (!_yearlyDocuments.containsKey(documentType)) {
                  _yearlyDocuments[documentType] = [];
                }
                _yearlyDocuments[documentType]!.addAll(uploadedFiles);
              });
            }
          }
        } catch (e) {
          // Close progress dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          // Upload failed - continue silently
        }
      }
    } catch (e) {
      // Error selecting file - continue silently
    }
  }

  // Remove a specific file from uploads
  void _removeFile(String documentType, int index) {
    setState(() {
      if (_yearlyDocuments.containsKey(documentType)) {
        _yearlyDocuments[documentType]!.removeAt(index);
        if (_yearlyDocuments[documentType]!.isEmpty) {
          _yearlyDocuments.remove(documentType);
        }
      }
    });
  }

  // Upload NGO Logo
  Future<void> _pickAndUploadLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file
        if (!FirestoreFileService.validateFile(file)) {
          AppHelpers.showErrorSnackBar(
              context, 'Invalid file format. Please upload JPG or PNG.');
          return;
        }

        // Check file size (max 5MB for logos)
        if (file.size > 5 * 1024 * 1024) {
          AppHelpers.showErrorSnackBar(
              context, 'Logo file size must be less than 5MB.');
          return;
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
                Text('Uploading logo...'),
              ],
            ),
          ),
        );

        try {
          // Upload to Supabase
          final uploadResult = await FirestoreFileService.uploadFile(
            ngoId: _auth.currentUser!.uid,
            documentType: 'logo',
            file: file,
          );

          if (uploadResult != null) {
            final logoMetadata = {
              'filename': uploadResult['filename'],
              'download_url': uploadResult['download_url'],
              'file_path': uploadResult['file_path'],
              'file_size': uploadResult['file_size'],
              'original_name': file.name,
              'uploaded_at': DateTime.now().toIso8601String(),
            };

            // Update Firestore with logo metadata
            await _firestore
                .collection('ngo_proposals')
                .doc(_auth.currentUser!.uid)
                .update({
              'logo': logoMetadata,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            setState(() {
              _logoMetadata = logoMetadata;
            });

            // Close progress dialog
            Navigator.pop(context);

            if (mounted) {
              AppHelpers.showSuccessSnackBar(
                  context, 'Logo uploaded successfully!');
            }
          } else {
            // Close progress dialog
            Navigator.pop(context);
            AppHelpers.showErrorSnackBar(
                context, 'Failed to upload logo. Please try again.');
          }
        } catch (e) {
          // Close progress dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          AppHelpers.showErrorSnackBar(context, 'Error uploading logo: $e');
        }
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error selecting file: $e');
    }
  }

  // UPDATED: Enhanced yearly data submission with Supabase upload
  Future<void> _submitYearlyData() async {
    if (_selectedFinancialYear == null) {
      AppHelpers.showErrorSnackBar(context, 'Please select a financial year');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if any documents are uploaded
      if (_yearlyDocuments.isEmpty ||
          !_yearlyDocuments.values.any((files) => files.isNotEmpty)) {
        AppHelpers.showErrorSnackBar(
            context, 'Please upload at least one document');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Submitting yearly data...'),
            ],
          ),
        ),
      );

      // Calculate total file count
      int totalFileCount = 0;
      _yearlyDocuments.forEach((key, files) {
        totalFileCount += files.length;
      });

      // Save yearly data reference in Firestore with metadata
      await _firestore
          .collection('ngo_proposals')
          .doc(user.uid)
          .collection('yearly_data')
          .doc(_selectedFinancialYear!)
          .set({
        'financialYear': _selectedFinancialYear,
        'documents': _yearlyDocuments,
        'documentCategoryCount': _yearlyDocuments.length,
        'totalFileCount': totalFileCount,
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': user.email,
        'status': 'submitted',
        'storageType':
            'supabase', // Flag to indicate this uses Supabase storage
      });

      // Close loading dialog
      Navigator.pop(context);

      if (mounted) {
        AppHelpers.showSuccessSnackBar(
            context, 'Yearly data submitted successfully');
        setState(() {
          _yearlyDocuments.clear();
          _selectedFinancialYear = null;
        });
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AppHelpers.showErrorSnackBar(context, 'Error submitting yearly data: $e');
    }
  }

  // UPDATED: Enhanced proposal submission with Supabase upload
  Future<void> _submitProposal() async {
    if (_proposalTitleController.text.trim().isEmpty ||
        _proposalDescriptionController.text.trim().isEmpty ||
        _proposalAmountController.text.trim().isEmpty) {
      AppHelpers.showErrorSnackBar(context, 'Please fill all proposal fields');
      return;
    }

    final amount = double.tryParse(_proposalAmountController.text);
    if (amount == null || amount <= 0) {
      AppHelpers.showErrorSnackBar(context, 'Please enter a valid amount');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppHelpers.showErrorSnackBar(
            context, 'User not authenticated. Please log in again.');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Submitting proposal...'),
            ],
          ),
        ),
      );

      // Check if proposal document is uploaded
      if (_proposalDocumentMetadata == null) {
        Navigator.pop(context); // Close loading dialog
        AppHelpers.showErrorSnackBar(
            context, 'Please upload a proposal document');
        return;
      }

      // Get NGO name from current data
      final ngoDoc =
          await _firestore.collection('ngo_proposals').doc(user.uid).get();
      if (!ngoDoc.exists) {
        Navigator.pop(context);
        AppHelpers.showErrorSnackBar(context,
            'NGO profile not found. Please complete your profile first.');
        return;
      }

      final ngoName = ngoDoc.data()?['ngoName'] ?? 'Unknown NGO';

      // UPDATED: Save proposal with Supabase document metadata
      await _firestore
          .collection('ngo_proposals')
          .doc(user.uid)
          .collection('proposals')
          .add({
        'title': _proposalTitleController.text.trim(),
        'description': _proposalDescriptionController.text.trim(),
        'requestedAmount': amount,
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': user.email,
        'ngoName': ngoName,
        'ngoId': user.uid,
        'sentToCPF': false,
        'storageType':
            'supabase', // Flag to indicate this uses Supabase storage
        'document': _proposalDocumentMetadata, // Store document metadata
        'hasDocument': true,
      });

      // Close loading dialog
      Navigator.pop(context);

      if (mounted) {
        AppHelpers.showSuccessSnackBar(
            context, 'Proposal submitted successfully');

        // Clear form
        _proposalTitleController.clear();
        _proposalDescriptionController.clear();
        _proposalAmountController.clear();
        setState(() {
          _proposalDocumentMetadata = null;
        });
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AppHelpers.showErrorSnackBar(
          context, 'Error submitting proposal: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.upload_file), text: 'Submit Data'),
            Tab(icon: Icon(Icons.description), text: 'Proposals'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildProfileTab(),
          _buildSubmitDataTab(),
          _buildProposalsTab(),
          _buildCertificatesTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('ngo_proposals')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const EmptyStateWidget(
            icon: Icons.person_off,
            title: 'Profile Not Found',
            message: 'Please complete your NGO registration first.',
          );
        }

        final ngoData = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: AppHelpers.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(ngoData),
              const SizedBox(height: 24),

              // Verification Status Banner
              _buildVerificationStatusBanner(ngoData),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> ngoData) {
    // Extract logo URL with debug logging
    final logoData = ngoData['logo'];
    print('🖼️ Logo Data Type: ${logoData.runtimeType}');
    print('🖼️ Logo Data: $logoData');

    String? logoUrl;
    if (logoData is Map<String, dynamic>) {
      logoUrl = logoData['download_url'] ??
          logoData['downloadUrl'] ??
          logoData['url'];
      print('🖼️ Logo URL from Map: $logoUrl');
    } else if (logoData is String) {
      logoUrl = logoData;
      print('🖼️ Logo URL from String: $logoUrl');
    } else {
      print('🖼️ Logo data is null or unexpected type');
      print('🖼️ All NGO Data keys: ${ngoData.keys.toList()}');

      // Check if logo is in documents field
      if (ngoData['documents'] != null && ngoData['documents'] is Map) {
        final docs = ngoData['documents'] as Map<String, dynamic>;
        if (docs['logo'] != null) {
          print('🖼️ Found logo in documents field');
          final docLogo = docs['logo'];
          if (docLogo is Map<String, dynamic>) {
            logoUrl = docLogo['download_url'] ??
                docLogo['downloadUrl'] ?? 
                docLogo['url'];
            print('🖼️ Logo URL from documents: $logoUrl');
          }
        }
      }
    }

    return CustomCard(
      child: Row(
        children: [
          // Logo Section
          if (logoUrl != null && logoUrl.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.backgroundGray,
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: AppTheme.primaryRed,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppTheme.backgroundGray,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray, width: 2),
              ),
              child: Icon(
                Icons.business,
                size: 40,
                color: AppTheme.primaryRed,
              ),
            ),

          // Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${ngoData['ngoName'] ?? 'NGO'}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your NGO profile, submit data, and track your progress.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                // Debug indicator (temporary)
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    logoUrl != null ? '' : '',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusBanner(Map<String, dynamic> ngoData) {
    final verificationStatus =
        ngoData['status'] ?? ngoData['verificationStatus'] ?? 'pending';
    final isProfileComplete = ngoData['profileComplete'] ?? false;

    Color bannerColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerMessage;

    switch (verificationStatus) {
      case 'approved':
      case 'verified':
        bannerColor = Colors.green;
        bannerIcon = Icons.check_circle;
        bannerTitle = 'Verified';
        bannerMessage = 'Your NGO has been verified and approved.';
        break;
      case 'rejected':
        bannerColor = Colors.red;
        bannerIcon = Icons.cancel;
        bannerTitle = 'Rejected';
        bannerMessage =
            'Your NGO verification was rejected. Please contact support.';
        break;
      case 'under_review':
        bannerColor = Colors.blue;
        bannerIcon = Icons.visibility;
        bannerTitle = 'Under Review';
        bannerMessage = 'Your NGO is currently under review by our team.';
        break;
      default:
        bannerColor = Colors.orange;
        bannerIcon = Icons.pending;
        bannerTitle = 'Pending Verification';
        bannerMessage =
            'Your NGO is under review. Admin will contact you soon.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: bannerColor,
                      ),
                ),
                Text(
                  bannerMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (!isProfileComplete)
            CustomButton(
              text: 'Complete Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NGOCompleteProfilePage(
                    uid: _auth.currentUser!.uid,
                  ),
                ),
              ),
              icon: Icons.person_add,
              isOutlined: true,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: AppHelpers.isDesktop(context) ? 4 : 2,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionCard(
                'Complete Profile',
                Icons.person_add,
                () => _tabController.animateTo(1),
              ),
              _buildQuickActionCard(
                'Submit Data',
                Icons.upload_file,
                () => _tabController.animateTo(2),
              ),
              _buildQuickActionCard(
                'View Proposals',
                Icons.description,
                () => _tabController.animateTo(3),
              ),
              _buildQuickActionCard(
                'View Certificates',
                Icons.workspace_premium,
                () => _tabController.animateTo(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryRed),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('ngo_proposals')
                .doc(_auth.currentUser?.uid)
                .collection('yearly_data')
                .orderBy('submittedAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No recent activity found.');
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.upload_file,
                        color: AppTheme.primaryRed),
                    title: Text('Submitted ${data['financialYear']} data'),
                    subtitle:
                        Text('${data['documentCount']} documents uploaded'),
                    trailing: Text(
                      data['submittedAt']?.toDate().toString().split(' ')[0] ??
                          '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('ngo_proposals')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const EmptyStateWidget(
            icon: Icons.person_off,
            title: 'Profile Not Found',
            message: 'Please complete your NGO registration first.',
          );
        }

        final ngoData = snapshot.data!.data() as Map<String, dynamic>;

        // Extract logo URL with debug logging
        final logoData = ngoData['logo'];
        print('📋 Profile Tab - Logo Data Type: ${logoData.runtimeType}');
        print('📋 Profile Tab - Logo Data: $logoData');

        String? logoUrl;
        if (logoData is Map<String, dynamic>) {
          logoUrl = logoData['download_url'] ??
              logoData['downloadUrl'] ??
              logoData['url'];
          print('📋 Profile Tab - Logo URL from Map: $logoUrl');
        } else if (logoData is String) {
          logoUrl = logoData;
          print('📋 Profile Tab - Logo URL from String: $logoUrl');
        } else {
          print('📋 Profile Tab - Logo is null or unexpected type');

          // Check if logo is in documents field
          if (ngoData['documents'] != null && ngoData['documents'] is Map) {
            final docs = ngoData['documents'] as Map<String, dynamic>;
            if (docs['logo'] != null) {
              print('📋 Profile Tab - Found logo in documents field');
              final docLogo = docs['logo'];
              if (docLogo is Map<String, dynamic>) {
                logoUrl = docLogo['download_url'] ??
                    docLogo['downloadUrl'] ??
                    docLogo['url'];
                print('📋 Profile Tab - Logo URL from documents: $logoUrl');
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: AppHelpers.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NGO Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Logo Upload/Display Section
              CustomCard(
                child: Column(
                  children: [
                    Text(
                      'NGO Logo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Logo Display
                    if (logoUrl != null && logoUrl.isNotEmpty)
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.primaryRed, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRed.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.backgroundGray,
                                  child: Icon(
                                    Icons.business,
                                    size: 60,
                                    color: AppTheme.primaryRed,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppTheme.backgroundGray,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.borderGray, width: 2),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 60,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),

                    // Upload/Change Logo Button
                    CustomButton(
                      text: logoUrl != null && logoUrl.isNotEmpty
                          ? 'Change Logo'
                          : 'Upload Logo',
                      onPressed: _pickAndUploadLogo,
                      icon: logoUrl != null && logoUrl.isNotEmpty
                          ? Icons.edit
                          : Icons.upload_file,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your NGO logo (JPG/PNG, Max 5MB)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildProfileSection('Basic Information', [
                _buildProfileItem('NGO Name', ngoData['ngoName']),
                _buildProfileItem('Email', ngoData['email']),
                _buildProfileItem('Phone', ngoData['phone']),
                _buildProfileItem(
                    'Registration Date', ngoData['dateOfRegistration']),
                _buildProfileItem('Country', ngoData['country']),
                _buildProfileItem('State', ngoData['state']),
                _buildProfileItem('District', ngoData['district']),
              ]),

              // Chief Functionary
              _buildProfileSection('Chief Functionary', [
                _buildProfileItem('Name', ngoData['chiefFunctionaryName']),
                _buildProfileItem('Email', ngoData['chiefFunctionaryEmail']),
                _buildProfileItem('Phone', ngoData['chiefFunctionaryPhone']),
              ]),

              // Financial Information
              _buildProfileSection('Financial Information', [
                _buildProfileItem('Financial Year', ngoData['financialYear']),
                _buildProfileItem('Gross Amount Raised',
                    ngoData['grossAmountRaised']?.toString()),
                _buildProfileItem('PAN', ngoData['pan']),
                _buildProfileItem('TAN', ngoData['tan']),
                _buildProfileItem(
                    'FCRA Registration', ngoData['fcraRegistration']),
                _buildProfileItem(
                    'CSR Registration', ngoData['csrRegistration']),
                _buildProfileItem('DARPAN ID', ngoData['darpanId']),
                _buildProfileItem(
                    'GST Registration', ngoData['gstRegistration']),
              ]),

              // Work Areas
              _buildProfileSection('Work Areas', [
                _buildProfileItem(
                    'Sectors', (ngoData['sectorOfWork'] as List?)?.join(', ')),
                _buildProfileItem('Other Sectors', ngoData['otherSectors']),
                _buildProfileItem('Networks', ngoData['networks']),
              ]),

              // Addresses
              _buildProfileSection('Addresses', [
                _buildProfileItem(
                    'Registered Address', ngoData['registeredAddress']),
                _buildProfileItem(
                    'Corresponding Address', ngoData['correspondingAddress']),
              ]),

              const SizedBox(height: 24),

              CustomButton(
                text: 'Edit Profile',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NGOCompleteProfilePage(
                      uid: _auth.currentUser!.uid,
                    ),
                  ),
                ),
                icon: Icons.edit,
                width: double.infinity,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not provided',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitDataTab() {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Financial Data',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your financial documents for the selected year.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Data for Financial Year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFinancialYear,
                  decoration: const InputDecoration(
                    labelText: 'Select Financial Year',
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
                ),
                const SizedBox(height: 20),

                // Audit Statements Section (3 years)
                Text(
                  'Audit Statements (Upload for 3 Years)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'audit_report', 'Audit Statements'),
                const SizedBox(height: 20),

                // Activity Reports
                Text(
                  'Activity Reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'activity_report', 'Activity Reports'),
                const SizedBox(height: 20),

                // ITR Acknowledgments
                Text(
                  'ITR Acknowledgments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'itr_acknowledgment', 'ITR Acknowledgments'),
                const SizedBox(height: 20),

                // Utilization Certificates
                Text(
                  'Utilization Certificates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'utilization_certificate', 'Utilization Certificates'),
                const SizedBox(height: 20),

                // Annual Return
                Text(
                  'Proof of Filing Annual Return',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'annual_return', 'Annual Return Proof'),
                const SizedBox(height: 20),

                // TAN Receipts Section
                Text(
                  'TAN Receipts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection('tan_form_24q', 'Form 24Q'),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection('tan_form_26q', 'Form 26Q'),
                const SizedBox(height: 12),
                _buildMultiFileUploadSection(
                    'tan_tds_related', 'TDS-Related Documents'),
                const SizedBox(height: 20),

                CustomButton(
                  text: 'Submit Yearly Data',
                  onPressed: _submitYearlyData,
                  icon: Icons.cloud_upload,
                  width: double.infinity,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Previously submitted data
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previously Submitted Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('ngo_proposals')
                      .doc(_auth.currentUser?.uid)
                      .collection('yearly_data')
                      .orderBy('submittedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingWidget();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No data submitted yet.');
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildYearlyDataCard(data);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for multi-file upload section with file list
  Widget _buildMultiFileUploadSection(String documentType, String label) {
    final files = _yearlyDocuments[documentType] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGray),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
              CustomButton(
                text: 'Add Files',
                onPressed: () => _pickFile(documentType, allowMultiple: true),
                icon: Icons.add,
                isOutlined: true,
              ),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...files.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file,
                        size: 20, color: AppTheme.accentGold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['original_name'] ?? 'Unknown file',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Size: ${_formatFileSize(file['file_size'] ?? 0)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFile(documentType, index),
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
            Text(
              '${files.length} file(s) uploaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No files uploaded yet. Click "Add Files" to upload.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlyDataCard(Map<String, dynamic> data) {
    final totalFiles = data['totalFileCount'] ?? data['documentCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.folder, color: AppTheme.primaryRed),
        title: Text('Financial Year: ${data['financialYear']}'),
        subtitle: Text('$totalFiles file(s) uploaded • ${data['status']}'),
        trailing: Text(
          data['submittedAt']?.toDate().toString().split(' ')[0] ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildProposalsTab() {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Proposal',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit a new proposal for funding consideration.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposal Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _proposalTitleController,
                  label: 'Proposal Title',
                  hint: 'Enter a descriptive title for your proposal',
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _proposalDescriptionController,
                  label: 'Description',
                  hint: 'Describe your project and its impact',
                  icon: Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _proposalAmountController,
                  label: 'Requested Amount (₹)',
                  hint: 'Enter the amount you are requesting',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildFileUploadTile('Proposal Document', 'proposal'),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Submit Proposal',
                  onPressed: _submitProposal,
                  icon: Icons.send,
                  width: double.infinity,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Previously submitted proposals
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previously Submitted Proposals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _auth.currentUser?.uid != null
                      ? _firestore
                          .collection('ngo_proposals')
                          .doc(_auth.currentUser!.uid)
                          .collection('proposals')
                          .orderBy('submittedAt', descending: true)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingWidget();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No proposals submitted yet.');
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildProposalCard(data);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.description, color: AppTheme.primaryRed),
        title: Text(data['title'] ?? 'Untitled Proposal'),
        subtitle: Text('₹${data['requestedAmount']} • ${data['status']}'),
        trailing: Text(
          data['submittedAt']?.toDate().toString().split(' ')[0] ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  // UPDATED: Enhanced file upload tile for single file uploads (used for proposals)
  Widget _buildFileUploadTile(String label, String documentType,
      {bool enabled = true}) {
    dynamic file;

    if (documentType == 'proposal') {
      file = _proposalDocumentMetadata;
    } else {
      // For yearly documents, get the first file if available
      final files = _yearlyDocuments[documentType];
      file = (files != null && files.isNotEmpty) ? files.first : null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled
              ? AppTheme.borderGray
              : AppTheme.borderGray.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
            color: file != null
                ? AppTheme.accentGold
                : enabled
                    ? AppTheme.primaryRed
                    : AppTheme.textSecondary,
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
                        color: enabled
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                ),
                if (file != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Uploaded',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        file is Map<String, dynamic>
                            ? file['original_name'] ?? 'Unknown file'
                            : 'Unknown file',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentGold,
                            ),
                      ),
                      Text(
                        'Size: ${_formatFileSize(file is Map<String, dynamic> ? file['file_size'] ?? 0 : 0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  )
                else
                  Text(
                    'PDF, JPG, PNG (Max 50MB)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          CustomButton(
            text: file != null ? 'Change' : 'Upload',
            onPressed: enabled
                ? () => _pickFile(documentType, allowMultiple: false)
                : null,
            icon: file != null ? Icons.edit : Icons.upload_file,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  String _getDocumentLabel(String docType) {
    switch (docType) {
      case 'audit_report':
        return 'Audit Report';
      case 'activity_report':
        return 'Activity Report';
      case 'itr_acknowledgment':
        return 'ITR Acknowledgment';
      case 'utilization_certificate':
        return 'Utilization Certificate';
      case 'annual_return':
        return 'Annual Return Proof';
      case 'tan_form_24q':
        return 'TAN Form 24Q';
      case 'tan_form_26q':
        return 'TAN Form 26Q';
      case 'tan_tds_related':
        return 'TAN TDS-Related Documents';
      default:
        return docType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildCertificatesTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('ngo_proposals')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const EmptyStateWidget(
            icon: Icons.workspace_premium,
            title: 'No Certificates Available',
            message: 'Please complete your NGO registration first.',
          );
        }

        final ngoData = snapshot.data!.data() as Map<String, dynamic>;
        final status = ngoData['status'] ?? 'pending';

        // Extract NGO information for certificates
        final ngoName = ngoData['ngoName'] ?? 'NGO Name';
        final ngoAddress = ngoData['registeredAddress'] ??
            ngoData['correspondingAddress'] ??
            'Address not provided';
        final cfoName = ngoData['chiefFunctionaryName'] ?? 'CFO Name';

        // Extract logo URL with comprehensive fallback logic
        String? logoPath;
        final logoData = ngoData['logo'];
        if (logoData is Map<String, dynamic>) {
          logoPath = logoData['download_url'] ??
              logoData['downloadUrl'] ??
              logoData['url'];
        } else if (logoData is String) {
          logoPath = logoData;
        }

        // If not found at top level, check documents field
        if ((logoPath == null || logoPath.isEmpty) &&
            ngoData['documents'] != null &&
            ngoData['documents'] is Map) {
          final docs = ngoData['documents'] as Map<String, dynamic>;
          if (docs['logo'] != null && docs['logo'] is Map<String, dynamic>) {
            final docLogo = docs['logo'] as Map<String, dynamic>;
            logoPath = docLogo['download_url'] ??
                docLogo['downloadUrl'] ??
                docLogo['url'];
          }
        }

        // Validate logo URL is a proper HTTP/HTTPS URL (not a local asset path)
        if (logoPath != null &&
            !logoPath.startsWith('http://') &&
            !logoPath.startsWith('https://')) {
          print(
              '⚠️ Invalid logo URL (not HTTP/HTTPS): $logoPath - setting to null');
          logoPath = null;
        }

        // Fallback to default CPF logo if no valid logo found
        logoPath ??= 'images/CPF_Logo.jpg';

        print('🎫 Certificate Generation - Using Logo URL: $logoPath');

        return SingleChildScrollView(
          child: Column(
            children: [
              // Status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status == 'approved' || status == 'verified'
                      ? Colors.green.withOpacity(0.1)
                      : status == 'under_review'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: status == 'approved' || status == 'verified'
                        ? Colors.green
                        : status == 'under_review'
                            ? Colors.blue
                            : Colors.orange,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'approved' || status == 'verified'
                          ? Icons.check_circle
                          : status == 'under_review'
                              ? Icons.visibility
                              : Icons.schedule,
                      color: status == 'approved' || status == 'verified'
                          ? Colors.green
                          : status == 'under_review'
                              ? Colors.blue
                              : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'approved' || status == 'verified'
                                ? 'NGO Approved - Certificates Available'
                                : status == 'under_review'
                                    ? 'Under Review - Certificates Pending'
                                    : 'Registration Pending - Certificates Not Available',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'approved' ||
                                          status == 'verified'
                                      ? Colors.green
                                      : status == 'under_review'
                                          ? Colors.blue
                                          : Colors.orange,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status == 'approved' || status == 'verified'
                                ? 'You can now download your official certificates'
                                : status == 'under_review'
                                    ? 'Your application is being reviewed. Certificates will be available once approved.'
                                    : 'Complete your registration to access certificates',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Certificates section (only show if approved/verified)
              if (status == 'approved' || status == 'verified')
                CertificatesSection(
                  ngoName: ngoName,
                  ngoAddress: ngoAddress,
                  cfoName: cfoName,
                  logoPath: logoPath,
                  certificateStatuses: {
                    'dueDiligenceCertificateEnabled':
                        ngoData['dueDiligenceCertificateEnabled'] ?? false,
                    'dueDiligenceCertificateEnabledData':
                        ngoData['dueDiligenceCertificateEnabledData'],
                    'complianceCertificateEnabled':
                        ngoData['complianceCertificateEnabled'] ?? false,
                    'complianceCertificateEnabledData':
                        ngoData['complianceCertificateEnabledData'],
                    'letterheadCertificateEnabled':
                        ngoData['letterheadCertificateEnabled'] ?? false,
                    'letterheadCertificateEnabledData':
                        ngoData['letterheadCertificateEnabledData'],
                  },
                )
              else ...[
                // Pending verification message
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pending, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Certificates Pending',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your NGO verification is pending. Certificates will be available once your NGO is approved.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
