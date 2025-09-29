  // ignore_for_file: unused_local_variable

  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:file_picker/file_picker.dart';
  import 'dart:html' as html;

  import 'package:cpf_portal/util/helpers.dart';
  import 'package:cpf_portal/util/theme.dart';
  import 'package:cpf_portal/widgets/custom_button.dart';
  import 'package:cpf_portal/widgets/custome_card.dart';
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
      
      if (authProvider.user == null) {
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/ngo-login');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ngo_proposals')
            .doc(authProvider.user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return NGOCompleteProfilePage(uid: authProvider.user!.uid);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isProfileComplete = data['profileComplete'] ?? false;

          if (!isProfileComplete) {
            return NGOCompleteProfilePage(uid: authProvider.user!.uid);
          }

          return const NGODashboard();
        },
      );
    }
  }

  // Main Dashboard
  class NGODashboard extends StatefulWidget {
    const NGODashboard({super.key});

    @override
    State<NGODashboard> createState() => _NGODashboardState();
  }

  class _NGODashboardState extends State<NGODashboard> with TickerProviderStateMixin {
    late TabController _tabController;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    // For financial year data submission
    String? _selectedFinancialYear;
    final List<String> _financialYears = List.generate(
      27, 
      (index) => '${2024 + index}-${(2024 + index + 1).toString().substring(2)}'
    );
    
    // UPDATED: Changed to store PlatformFile temporarily until upload
    final Map<String, PlatformFile?> _yearlyDocuments = {};

    // UPDATED: For proposal submission - now stores metadata after upload
    final _proposalTitleController = TextEditingController();
    final _proposalDescriptionController = TextEditingController();
    final _proposalAmountController = TextEditingController();
    Map<String, dynamic>? _proposalDocumentMetadata;

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
        final authProvider = Provider.of<local_auth.AuthProvider>(context, listen: false);
        await authProvider.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
          AppHelpers.showErrorSnackBar(context, 'Error logging out: $e');
        }
      }
    }

    // UPDATED: Enhanced file picking for different document types
    Future<void> _pickFile(String documentType) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          
          if (!FirestoreFileService.validateFile(file)) {
            AppHelpers.showErrorSnackBar(context, 'Invalid file. Must be PDF, JPG, or PNG under 50MB');
            return;
          }

          if (documentType == 'proposal') {
            setState(() {
              _proposalDocumentMetadata = {
                'file': file,
                'original_name': file.name,
                'file_size': file.size,
              };
            });
            AppHelpers.showSuccessSnackBar(context, 'File selected: ${file.name}');
          } else {
            // For yearly documents
            setState(() {
              _yearlyDocuments[documentType] = file;
            });
            AppHelpers.showSuccessSnackBar(context, 'File selected: ${file.name}');
          }
        }
      } catch (e) {
        AppHelpers.showErrorSnackBar(context, 'Error picking file: $e');
      }
    }

    // NEW: Download function for registration documents
    Future<void> _downloadRegistrationDocument(String ngoId, String filename, String originalName) async {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Downloading document...'),
              ],
            ),
          ),
        );

        final bytes = await FirestoreFileService.downloadFile(
          ngoId: ngoId,
          filename: filename,
        );

        // Close loading dialog
        Navigator.pop(context);

        // Trigger browser download
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", originalName)
          ..click();
        html.Url.revokeObjectUrl(url);

        AppHelpers.showSuccessSnackBar(context, 'Document downloaded successfully');
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        AppHelpers.showErrorSnackBar(context, 'Download failed: $e');
      }
    }

    // NEW: Download function for yearly documents
    Future<void> _downloadYearlyDocument(String ngoId, String filename, String originalName) async {
      await _downloadRegistrationDocument(ngoId, filename, originalName);
    }

    // NEW: Download function for proposal documents
    Future<void> _downloadProposalDocument(String ngoId, String filename, String originalName) async {
      await _downloadRegistrationDocument(ngoId, filename, originalName);
    }

    // FIXED: Certificate download now shows proper status instead of placeholder
    Future<void> _downloadCertificate(String certificateType) async {
      try {
        // Check if NGO is approved for certificates
        final doc = await _firestore.collection('ngo_proposals').doc(_auth.currentUser?.uid).get();
        final status = doc.data()?['status'] ?? 'draft';
        
        if (status != 'approved' && certificateType != 'Registration Receipt') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Certificate Not Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppTheme.warningOrange),
                  const SizedBox(height: 16),
                  Text(
                    'This certificate is only available after your NGO has been approved by the admin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        
        // For now, show coming soon for all certificates
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$certificateType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.construction, size: 48, color: AppTheme.primaryRed),
                ),
                const SizedBox(height: 16),
                Text(
                  'Certificate generation feature coming soon!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature is under development and will be available in the next update.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        AppHelpers.showErrorSnackBar(context, 'Certificate download failed: $e');
      }
    }

    // FIXED: Send to CPF functionality
    Future<void> _sendProposalToCPF(Map<String, dynamic> proposalData) async {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Preparing email...'),
              ],
            ),
          ),
        );

        // Get NGO details
        final ngoDoc = await _firestore.collection('ngo_proposals').doc(_auth.currentUser?.uid).get();
        final ngoData = ngoDoc.data() ?? {};

        // Create email content
        final subject = Uri.encodeComponent('Proposal Submission: ${proposalData['title']}');
        final body = Uri.encodeComponent('''
  Dear CPF Team,

  Please find below a proposal submission from our NGO:

  NGO Details:
  - Name: ${ngoData['ngoName']}
  - Email: ${ngoData['email']}
  - Registration Date: ${ngoData['dateOfRegistration']}

  Proposal Details:
  - Title: ${proposalData['title']}
  - Description: ${proposalData['description']}
  - Requested Amount: ₹${proposalData['requestedAmount']}
  - Submitted On: ${proposalData['submittedAt']?.toDate() ?? DateTime.now()}

  Please review the proposal at your earliest convenience.

  Best regards,
  ${ngoData['chiefFunctionaryName'] ?? ngoData['ngoName']}
        ''');

        final mailtoUrl = 'mailto:support@cpfindia.org?subject=$subject&body=$body';
        
        // Close loading dialog
        Navigator.pop(context);

        // Open email client
        html.window.open(mailtoUrl, '_blank');

        // Update proposal status in Firestore
        await _firestore
            .collection('ngo_proposals')
            .doc(_auth.currentUser?.uid)
            .collection('proposals')
            .where('title', isEqualTo: proposalData['title'])
            .where('submittedAt', isEqualTo: proposalData['submittedAt'])
            .get()
            .then((querySnapshot) {
              if (querySnapshot.docs.isNotEmpty) {
                querySnapshot.docs.first.reference.update({
                  'sentToCPF': true,
                  'sentToCPFAt': FieldValue.serverTimestamp(),
                });
              }
            });

        AppHelpers.showSuccessSnackBar(context, 'Email prepared. Please send it from your email client.');
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        AppHelpers.showErrorSnackBar(context, 'Failed to prepare email: $e');
      }
    }

    // UPDATED: Enhanced yearly data submission with Plesk upload
    Future<void> _submitYearlyData() async {
      Future<void> _submitYearlyData() async {
  if (_selectedFinancialYear == null) {
    AppHelpers.showErrorSnackBar(context, 'Please select a financial year');
    return;
  }

  try {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if any documents are selected
    if (_yearlyDocuments.isEmpty || !_yearlyDocuments.values.any((file) => file != null)) {
      AppHelpers.showErrorSnackBar(context, 'Please select at least one document');
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
            Text('Uploading documents...'),
          ],
        ),
      ),
    );

    // Prepare documents for bulk upload
    Map<String, PlatformFile> documentsToUpload = {};
    _yearlyDocuments.forEach((key, value) {
      if (value != null) {
        documentsToUpload[key] = value;
      }
    });

    // Use the enhanced yearly documents submission method
    final uploadResult = await FirestoreFileService.submitYearlyDocuments(
      ngoId: user.uid,
      financialYear: _selectedFinancialYear!,
      documents: documentsToUpload,
    );

    // Close loading dialog
    Navigator.pop(context);

    if (uploadResult != null) {
      // UPDATED: Save minimal reference in Firestore (just for tracking)
      await _firestore
          .collection('ngo_proposals')
          .doc(user.uid)
          .collection('yearly_data')
          .doc(_selectedFinancialYear!)
          .set({
        'financialYear': _selectedFinancialYear,
        'documentCount': documentsToUpload.length,
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': user.email,
        'status': 'submitted',
        'storageType': 'plesk', // Flag to indicate this uses Plesk storage
      });

      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Yearly data submitted successfully');
        setState(() {
          _yearlyDocuments.clear();
          _selectedFinancialYear = null;
        });
      }
    } else {
      AppHelpers.showErrorSnackBar(context, 'Failed to upload documents');
    }
  } catch (e) {
    // Close loading dialog if still open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (mounted) {
      AppHelpers.showErrorSnackBar(context, 'Error submitting data: $e');
    }
  }
}

// Also update the yearly data display section
Widget _buildYearlyDataList(List<QueryDocumentSnapshot> docs) {
  return Column(
    children: docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
      final status = data['status'] ?? 'submitted';
      final financialYear = data['financialYear'];
      final storageType = data['storageType'] ?? 'firestore'; // Default to firestore for old data
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: AppTheme.surfaceWhite,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'FY $financialYear',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.surfaceWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (submittedAt != null)
                          Text(
                            'Submitted: ${_formatDateTime(submittedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    storageType == 'plesk' ? 'New System' : 'Legacy',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: storageType == 'plesk' ? AppTheme.accentGold : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Show documents based on storage type
              if (storageType == 'plesk') ...[
                // Load documents from Plesk API
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirestoreFileService.listFiles(
                    ngoId: _auth.currentUser!.uid,
                    documentType: 'yearly_data_$financialYear',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        'No documents found',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...snapshot.data!.map((docData) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    docData['original_name'] ?? 'Document',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _downloadYearlyDocument(
                                    _auth.currentUser!.uid,
                                    docData['filename'],
                                    docData['original_name'] ?? 'document',
                                  ),
                                  child: const Text('Download', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ] else ...[
                // Legacy Firestore documents
                if (data['documents'] != null) ...[
                  Text(
                    'Documents (Legacy):',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(data['documents'] as Map<String, dynamic>).entries.map((docEntry) {
                    final docType = docEntry.key;
                    final docData = docEntry.value as Map<String, dynamic>;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getDocumentLabel(docType),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _downloadYearlyDocument(
                              _auth.currentUser!.uid,
                              docData['filename'],
                              docData['original_name'] ?? 'document',
                            ),
                            child: const Text('Download', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  Text(
                    'Document count: ${data['documentCount'] ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }).toList(),
  );
}
    }

    // UPDATED: Enhanced proposal submission with Plesk upload
    // Replace your existing _submitProposal() method with this updated version

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
      AppHelpers.showErrorSnackBar(context, 'User not authenticated. Please log in again.');
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

    Map<String, dynamic>? proposalResult;
    
    // Upload document if provided using the enhanced method
    if (_proposalDocumentMetadata != null && _proposalDocumentMetadata!['file'] != null) {
      try {
        final file = _proposalDocumentMetadata!['file'] as PlatformFile;
        
        proposalResult = await FirestoreFileService.submitProposal(
          ngoId: user.uid,
          title: _proposalTitleController.text.trim(),
          description: _proposalDescriptionController.text.trim(),
          requestedAmount: amount,
          proposalDocument: file,
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        AppHelpers.showErrorSnackBar(context, 'Document upload failed: $e');
        return;
      }
    }

    // Get NGO name from current data
    final ngoDoc = await _firestore.collection('ngo_proposals').doc(user.uid).get();
    if (!ngoDoc.exists) {
      Navigator.pop(context);
      AppHelpers.showErrorSnackBar(context, 'NGO profile not found. Please complete your profile first.');
      return;
    }

    final ngoName = ngoDoc.data()?['ngoName'] ?? 'Unknown NGO';

    // UPDATED: Save minimal reference in Firestore (just for tracking)
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
      'storageType': 'plesk', // Flag to indicate this uses Plesk storage
      'hasDocument': proposalResult != null,
      'proposalId': proposalResult?['id'], // Reference to Plesk database ID
    });

    // Close loading dialog
    Navigator.pop(context);

    if (mounted) {
      AppHelpers.showSuccessSnackBar(context, 'Proposal submitted successfully');
      
      // Clear form
      _proposalTitleController.clear();
      _proposalDescriptionController.clear();
      _proposalAmountController.clear();
      setState(() {
        _proposalDocumentMetadata = null;
      });
    }
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (mounted) {
      AppHelpers.showErrorSnackBar(context, 'Error submitting proposal: ${e.toString()}');
    }
    print('Error submitting proposal: $e');
  }
}
    

    @override
    Widget build(BuildContext context) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('ngo_proposals').doc(_auth.currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundGray,
              body: LoadingWidget(message: 'Loading your dashboard...'),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundGray,
              body: ErrorStateWidget(
                message: 'Error loading data: ${snapshot.error}',
                onRetry: () => setState(() {}),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundGray,
              body: EmptyStateWidget(
                icon: Icons.business_center,
                title: 'No NGO Data',
                message: 'Please complete your registration first.',
                actionText: 'Complete Profile',
                onAction: () {
                  final uid = _auth.currentUser?.uid;
                  if (uid != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NGOCompleteProfilePage(uid: uid),
                      ),
                    );
                  }
                },
              ),
            );
          }

          final ngoData = snapshot.data!.data() as Map<String, dynamic>;

          return Scaffold(
            backgroundColor: AppTheme.backgroundGray,
            appBar: AppBar(
              title: Text('Welcome, ${ngoData['ngoName'] ?? 'NGO'}'),
              backgroundColor: AppTheme.surfaceWhite,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'logout':
                        _logout();
                        break;
                      case 'refresh':
                        setState(() {});
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryRed,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryRed,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Profile', icon: Icon(Icons.business)),
                  Tab(text: 'Financial Data', icon: Icon(Icons.assessment)),
                  Tab(text: 'Proposals', icon: Icon(Icons.description)),
                  Tab(text: 'Downloads', icon: Icon(Icons.download)),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(ngoData),
                _buildProfileTab(ngoData),
                _buildFinancialDataTab(),
                _buildProposalsTab(ngoData),
                _buildDownloadsTab(ngoData),
              ],
            ),
          );
        },
      );
    }

    Widget _buildDashboardTab(Map<String, dynamic> ngoData) {
      final isProfileComplete = ngoData['profileComplete'] ?? false;
      final status = ngoData['status'] ?? 'draft';
      final submittedAt = ngoData['submittedAt']?.toDate();
      final reviewedAt = ngoData['reviewedAt']?.toDate();

      return SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Real-time Status
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          size: 32,
                          color: AppTheme.surfaceWhite,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.surfaceWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ngoData['ngoName'] ?? 'Your NGO',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.surfaceWhite.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Real-time Status Indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.surfaceWhite.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: AppTheme.surfaceWhite,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(status),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.surfaceWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getStatusDescription(status),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.surfaceWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Registration and validation processes are free of charge as per CPF policy.',
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

            const SizedBox(height: 24),

            // Application Status Tracker with Live Updates
            _buildLiveStatusTracker(ngoData),

            const SizedBox(height: 16),

            // Profile Completion Check
            if (!isProfileComplete) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Incomplete',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          Text(
                            'Please complete your profile to access all features',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomButton(
                      text: 'Complete',
                      onPressed: () {
                        final uid = _auth.currentUser?.uid;
                        if (uid != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NGOCompleteProfilePage(uid: uid),
                            ),
                          );
                        }
                      },
                      icon: Icons.arrow_forward,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Actions with Dynamic Enablement
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: AppHelpers.isDesktop(context) ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionCard(
                  Icons.edit,
                  'Update Profile',
                  'Edit organization details',
                  () => _tabController.animateTo(1),
                  AppTheme.primaryRed,
                  enabled: true,
                ),
                _buildQuickActionCard(
                  Icons.assessment,
                  'Submit Data',
                  'Upload yearly documents',
                  () => _tabController.animateTo(2),
                  AppTheme.primaryOrange,
                  enabled: isProfileComplete && status != 'draft',
                ),
                _buildQuickActionCard(
                  Icons.add_circle,
                  'New Proposal',
                  'Submit funding proposal',
                  () => _tabController.animateTo(3),
                  AppTheme.accentGold,
                  enabled: isProfileComplete && status == 'approved',
                ),
                _buildQuickActionCard(
                  Icons.download,
                  'Downloads',
                  'Get certificates',
                  () => _tabController.animateTo(4),
                  AppTheme.warningOrange,
                  enabled: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Activity Feed
            _buildLiveActivityFeed(ngoData),

            const SizedBox(height: 16),

            // UPDATED: Document access section with download functionality
            if (ngoData['documents'] != null) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder, color: AppTheme.accentGold),
                        const SizedBox(width: 8),
                        Text(
                          'Your Submitted Documents',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRegistrationDocumentsList(ngoData['documents'] as Map<String, dynamic>),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Other Documents
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, color: AppTheme.accentGold),
                      const SizedBox(width: 8),
                      Text(
                        'Other Documents',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDownloadItem(
                    Icons.description,
                    'Application Summary',
                    'Complete summary of your NGO application',
                    () => _downloadCertificate('Application Summary'),
                    true,
                  ),
                  _buildDownloadItem(
                    Icons.timeline,
                    'Validation Timeline',
                    'Timeline of your application review process',
                    () => _downloadCertificate('Validation Timeline'),
                    true,
                  ),
                  if (ngoData['documents'] != null)
                    _buildDownloadItem(
                      Icons.folder_zip,
                      'Submitted Documents',
                      'Download all your submitted documents as ZIP',
                      () => _downloadCertificate('Document Package'),
                      true,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // NEW: Widget to display registration documents with download links
    Widget _buildRegistrationDocumentsList(Map<String, dynamic> documents) {
      final documentLabels = {
        'itr': 'ITR Acknowledgment',
        'audit_reports': 'Audit Reports',
        'pf_registration': 'PF Registration',
        'pan_doc': 'PAN Document',
        'tan_doc': 'TAN Document',
        'fcra_doc': 'FCRA Registration',
        'fcra_bank_change': 'FCRA Bank Change Letter',
        'csr_doc': 'CSR Registration',
        'darpan_doc': 'DARPAN ID',
        'gst_doc': 'GST Registration',
        'professional_tax_doc': 'Professional Tax Registration',
        'legal_status_doc': 'Legal Status Document',
        '12a_doc': '12A Certificate',
        '80g_doc': '80G Certificate',
        'registration_cert_doc': 'Registration Certificate',
      };

      return Column(
        children: documents.entries.map((entry) {
          final docType = entry.key;
          final docData = entry.value as Map<String, dynamic>;
          final label = documentLabels[docType] ?? docType.replaceAll('_', ' ');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: AppTheme.accentGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        docData['original_name'] ?? 'Unknown file',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _downloadRegistrationDocument(
                    _auth.currentUser!.uid,
                    docData['filename'],
                    docData['original_name'] ?? 'document',
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    Widget _buildLiveStatusTracker(Map<String, dynamic> ngoData) {
      final status = ngoData['status'] ?? 'draft';
      final submittedAt = ngoData['submittedAt']?.toDate();
      final reviewedAt = ngoData['reviewedAt']?.toDate();
      final createdAt = ngoData['createdAt']?.toDate();

      final steps = [
        {
          'title': 'Profile Created',
          'description': 'Account and basic information created',
          'status': 'completed',
          'date': createdAt,
          'icon': Icons.account_circle,
        },
        {
          'title': 'Profile Completed',
          'description': 'All required information submitted',
          'status': ngoData['profileComplete'] == true ? 'completed' : 'pending',
          'date': submittedAt,
          'icon': Icons.assignment_turned_in,
        },
        {
          'title': 'Under Review',
          'description': 'Admin reviewing submitted documents',
          'status': status == 'pending' || status == 'under_review' ? 'active' : 
                    status == 'approved' || status == 'rejected' ? 'completed' : 'pending',
          'date': status == 'pending' ? submittedAt : null,
          'icon': Icons.rate_review,
        },
        {
          'title': status == 'approved' ? 'Approved' : status == 'rejected' ? 'Rejected' : 'Final Decision',
          'description': status == 'approved' ? 'NGO validated and approved' : 
                        status == 'rejected' ? 'Application requires changes' : 'Awaiting admin decision',
          'status': status == 'approved' ? 'completed' : 
                    status == 'rejected' ? 'error' : 'pending',
          'date': reviewedAt,
          'icon': status == 'approved' ? Icons.verified : 
                  status == 'rejected' ? Icons.cancel : Icons.pending,
        },
      ];

      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Text(
                  'Application Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('ngo_proposals').doc(_auth.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                    return IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(() {}),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStepColor(step['status'] as String),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: AppTheme.surfaceWhite,
                          size: 16,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: AppTheme.borderGray,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (step['date'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(step['date'] as DateTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    }

    Widget _buildLiveActivityFeed(Map<String, dynamic> ngoData) {
      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Live activity from multiple collections
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('ngo_proposals')
                  .doc(_auth.currentUser?.uid)
                  .collection('activity_log')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildDefaultActivityItems(ngoData);
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final activity = doc.data() as Map<String, dynamic>;
                    return _buildActivityItem(
                      _getActivityIcon(activity['type']),
                      activity['title'] ?? 'Activity',
                      activity['description'] ?? '',
                      _formatDateTime(activity['timestamp']?.toDate() ?? DateTime.now()),
                      _getActivityColor(activity['type']),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      );
    }

    Widget _buildDefaultActivityItems(Map<String, dynamic> ngoData) {
      List<Widget> activities = [];

      if (ngoData['createdAt'] != null) {
        activities.add(_buildActivityItem(
          Icons.account_circle,
          'Account Created',
          'Your NGO account was created successfully',
          _formatDateTime(ngoData['createdAt'].toDate()),
          AppTheme.accentGold,
        ));
      }

      if (ngoData['submittedAt'] != null) {
        activities.add(_buildActivityItem(
          Icons.check_circle,
          'Profile Submitted',
          'Complete profile submitted for review',
          _formatDateTime(ngoData['submittedAt'].toDate()),
          AppTheme.primaryRed,
        ));
      }

      if (ngoData['reviewedAt'] != null) {
        final status = ngoData['status'];
        activities.add(_buildActivityItem(
          status == 'approved' ? Icons.verified : Icons.feedback,
          status == 'approved' ? 'Application Approved' : 'Review Completed',
          status == 'approved' ? 'Your NGO has been validated and approved' : 'Review feedback provided',
          _formatDateTime(ngoData['reviewedAt'].toDate()),
          status == 'approved' ? AppTheme.accentGold : AppTheme.warningOrange,
        ));
      }

      return Column(children: activities);
    }

    Widget _buildProfileTab(Map<String, dynamic> ngoData) {
      return SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
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
                        'NGO Profile Management',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete organizational details and documentation status',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ngoData['status'] ?? 'draft'),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    (ngoData['status'] ?? 'draft').toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.surfaceWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Basic Information
            _buildProfileSection('Basic Information', [
              _buildProfileItem('NGO Name', ngoData['ngoName']),
              _buildProfileItem('Email', ngoData['email']),
              _buildProfileItem('Registration Date', ngoData['dateOfRegistration']),
              _buildProfileItem('Location', '${ngoData['district'] ?? ''}, ${ngoData['state'] ?? ''}, ${ngoData['country'] ?? ''}'),
              _buildProfileItem('Legal Status', ngoData['legalStatus']),
            ]),

            // Chief Functionary
            _buildProfileSection('Chief Functionary', [
              _buildProfileItem('Name', ngoData['chiefFunctionaryName']),
              _buildProfileItem('Email', ngoData['chiefFunctionaryEmail']),
              _buildProfileItem('Phone', ngoData['chiefFunctionaryPhone']),
            ]),

            // Contact Persons
            if (ngoData['contactPersons'] != null) ...[
              _buildContactPersonsSection(ngoData['contactPersons']),
            ],

            // Address Information
            _buildProfileSection('Address Information', [
              _buildProfileItem('Registered Address', ngoData['registeredAddress']),
              _buildProfileItem('Correspondence Address', ngoData['correspondingAddress']),
            ]),

            // Financial Information
            _buildProfileSection('Financial Information', [
              _buildProfileItem('Financial Year', ngoData['financialYear']),
              _buildProfileItem('Gross Amount Raised', ngoData['grossAmountRaised'] != null ? '₹${ngoData['grossAmountRaised']}' : null),
              _buildProfileItem('PAN', ngoData['pan']),
              _buildProfileItem('TAN', ngoData['tan']),
            ]),

            // Registration & Compliance
            _buildProfileSection('Registration & Compliance', [
              _buildProfileItem('FCRA Registration', ngoData['fcraRegistration']),
              _buildProfileItem('CSR Registration', ngoData['csrRegistration']),
              _buildProfileItem('DARPAN ID', ngoData['darpanId']),
              _buildProfileItem('GST Registration', ngoData['gstRegistration']),
              _buildProfileItem('Professional Tax Registration', ngoData['professionalTaxRegistration']),
              _buildProfileItem('12A Certificate', ngoData['cert12A']),
              _buildProfileItem('80G Certificate', ngoData['cert80G']),
              _buildProfileItem('Registration Certificate Number', ngoData['registrationCertNumber']),
            ]),

            // Work & Networks
            _buildProfileSection('Work Areas & Networks', [
              _buildProfileItem('Sectors', (ngoData['sectorOfWork'] as List?)?.join(', ')),
              _buildProfileItem('Other Thematic Areas', ngoData['otherSectors']),
              _buildProfileItem('Network Affiliations', ngoData['networks']),
            ]),

            // FIXED: Social Media Presence with working links
            if (ngoData['socialMediaUrls'] != null && (ngoData['socialMediaUrls'] as Map).isNotEmpty) ...[
              _buildSocialMediaSection(ngoData['socialMediaUrls']),
            ],

            // UPDATED: Document Status with download functionality
            if (ngoData['documents'] != null) ...[
              _buildDocumentStatusSection(ngoData['documents']),
            ],

            const SizedBox(height: 24),
            
            CustomButton(
              text: 'Edit Profile',
              onPressed: () {
                final uid = _auth.currentUser?.uid;
                if (uid != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NGOCompleteProfilePage(uid: uid),
                    ),
                  );
                }
              },
              icon: Icons.edit,
              width: double.infinity,
            ),
          ],
        ),
      );
    }

    Widget _buildContactPersonsSection(List contactPersons) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Persons',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 16),
              ...contactPersons.asMap().entries.map((entry) {
                final index = entry.key;
                final contact = entry.value as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProfileItem('Name', contact['name']),
                      _buildProfileItem('Email', contact['email']),
                      _buildProfileItem('Phone', contact['phone']),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // FIXED: Social media links now open properly
    Widget _buildSocialMediaSection(Map<String, dynamic> socialMediaUrls) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Media Presence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 16),
              ...socialMediaUrls.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSocialMediaIcon(entry.key),
                          color: AppTheme.primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryRed,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        onPressed: () {
                          final url = entry.value.toString();
                          // Ensure URL has protocol
                          final fullUrl = url.startsWith('http') ? url : 'https://$url';
                          html.window.open(fullUrl, '_blank');
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // UPDATED: Document status section with download functionality
    Widget _buildDocumentStatusSection(Map<String, dynamic> documents) {
      final documentLabels = {
        'itr': 'ITR Acknowledgment',
        'audit_reports': 'Audit Reports',
        'pf_registration': 'PF Registration',
        'pan_doc': 'PAN Document',
        'tan_doc': 'TAN Document',
        'fcra_doc': 'FCRA Registration',
        'fcra_bank_change': 'FCRA Bank Change Letter',
        'csr_doc': 'CSR Registration',
        'darpan_doc': 'DARPAN ID',
        'gst_doc': 'GST Registration',
        'professional_tax_doc': 'Professional Tax Registration',
        'legal_status_doc': 'Legal Status Document',
        '12a_doc': '12A Certificate',
        '80g_doc': '80G Certificate',
        'registration_cert_doc': 'Registration Certificate',
      };

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open, color: AppTheme.primaryRed),
                  const SizedBox(width: 8),
                  Text(
                    'Document Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${documents.length} uploaded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...documents.entries.map((entry) {
                final docType = entry.key;
                final docData = entry.value as Map<String, dynamic>;
                final label = documentLabels[docType] ?? docType.replaceAll('_', ' ');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.accentGold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              docData['original_name'] ?? 'Unknown file',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _downloadRegistrationDocument(
                          _auth.currentUser!.uid,
                          docData['filename'],
                          docData['original_name'] ?? 'document',
                        ),
                        child: const Text('Download'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    Widget _buildFinancialDataTab() {
      return SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Year-wise Data Submission',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit and manage program, financial, and compliance data for each financial year, ensuring transparency and traceability.',
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
                    items: _financialYears.map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedFinancialYear = value),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Upload Documents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...[
                    'audit_report',
                    'activity_report',
                    'itr_acknowledgment',
                    'utilization_certificate',
                  ].map((docType) => _buildFileUploadTile(
                    _getDocumentLabel(docType),
                    docType,
                  )),

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

            // UPDATED: Previously submitted data with download functionality
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
                        return const EmptyStateWidget(
                          icon: Icons.folder_open,
                          title: 'No Data Submitted',
                          message: 'No yearly data has been submitted yet.',
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
                          final status = data['status'] ?? 'submitted';
                          final documents = data['documents'] as Map<String, dynamic>? ?? {};
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.folder,
                                          color: AppTheme.surfaceWhite,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'FY ${data['financialYear']}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(status),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: AppTheme.surfaceWhite,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (submittedAt != null)
                                              Text(
                                                'Submitted: ${_formatDateTime(submittedAt)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${documents.length} docs',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Document list with download functionality
                                  if (documents.isNotEmpty) ...[
                                    Text(
                                      'Documents:',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...documents.entries.map((docEntry) {
                                      final docType = docEntry.key;
                                      final docData = docEntry.value as Map<String, dynamic>;
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.description, size: 16, color: AppTheme.textSecondary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _getDocumentLabel(docType),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => _downloadYearlyDocument(
                                                _auth.currentUser!.uid,
                                                docData['filename'],
                                                docData['original_name'] ?? 'document',
                                              ),
                                              child: const Text('Download', style: TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
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

    Widget _buildProposalsTab(Map<String, dynamic> ngoData) {
      final status = ngoData['status'] ?? 'draft';
      final canSubmitProposals = status == 'approved';

      return SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proposal Submission',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit funding proposals monthly. Download submitted proposals and send directly to CPF for follow-up.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Status check for proposal submission
            if (!canSubmitProposals) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.warningOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proposal Submission Restricted',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          Text(
                            'You can submit proposals only after your NGO profile is approved.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Proposal Submission Form
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Submit New Proposal',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (canSubmitProposals)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ENABLED',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _proposalTitleController,
                    label: 'Proposal Title',
                    hint: 'Enter proposal title',
                    icon: Icons.title,
                    enabled: canSubmitProposals,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _proposalDescriptionController,
                    label: 'Proposal Description',
                    hint: 'Describe your proposal in detail',
                    icon: Icons.description,
                    maxLines: 5,
                    enabled: canSubmitProposals,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _proposalAmountController,
                    label: 'Requested Amount (INR)',
                    hint: 'Enter amount in INR',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    enabled: canSubmitProposals,
                  ),

                  const SizedBox(height: 16),

                  _buildFileUploadTile('Proposal Document', 'proposal', enabled: canSubmitProposals),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Submit Proposal',
                    onPressed: canSubmitProposals ? _submitProposal : null,
                    icon: Icons.send,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FIXED: Previously submitted proposals with working Send to CPF button
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
                      if (snapshot.hasError) {
                        print('Error loading proposals: ${snapshot.error}');
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Error loading proposals',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please check your internet connection and try again.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Retry',
                                onPressed: () => setState(() {}),
                                icon: Icons.refresh,
                              ),
                            ],
                          ),
                        );
                      }

                      if (_auth.currentUser?.uid == null) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.person_outline, color: AppTheme.warningOrange, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Authentication Required',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.warningOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please log in again to view your proposals.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget(message: 'Loading proposals...');
                      }

                      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return const EmptyStateWidget(
                          icon: Icons.description,
                          title: 'No Proposals Submitted',
                          message: 'You haven\'t submitted any proposals yet.',
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
                          final proposalStatus = data['status']?.toString() ?? 'submitted';
                          final documentData = data['document'] as Map<String, dynamic>?;
                          final sentToCPF = data['sentToCPF'] ?? false;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['title']?.toString() ?? 'Untitled Proposal',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (sentToCPF)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentGold.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check, size: 12, color: AppTheme.accentGold),
                                              const SizedBox(width: 4),
                                              Text(
                                                'SENT TO CPF',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.accentGold,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(proposalStatus),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          proposalStatus.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.surfaceWhite,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['description']?.toString() ?? 'No description provided',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.currency_rupee, size: 16, color: AppTheme.textSecondary),
                                      Text(
                                        '₹${data['requestedAmount']?.toString() ?? '0'}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        submittedAt != null ? _formatDate(submittedAt) : 'Unknown',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Download',
                                          onPressed: documentData != null 
                                              ? () => _downloadProposalDocument(
                                                  _auth.currentUser!.uid,
                                                  documentData['filename'],
                                                  documentData['original_name'] ?? 'proposal',
                                                )
                                              : null,
                                          icon: Icons.download,
                                          isOutlined: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomButton(
                                          text: sentToCPF ? 'Sent ✓' : 'Send to CPF',
                                          onPressed: sentToCPF ? null : () => _sendProposalToCPF(data),
                                          icon: sentToCPF ? Icons.check_circle : Icons.email,
                                          backgroundColor: sentToCPF ? AppTheme.textSecondary : AppTheme.primaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
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

    Widget _buildDownloadsTab(Map<String, dynamic> ngoData) {
      final status = ngoData['status'] ?? 'draft';
      final isApproved = status == 'approved';

      return SingleChildScrollView(
        padding: AppHelpers.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloads',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Access and download CPF validation certificates, payment receipts, and other official documents.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Certificates
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.primaryRed),
                      const SizedBox(width: 8),
                      Text(
                        'Certificates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDownloadItem(
                    Icons.verified,
                    'CPF Validation Certificate',
                    'Official validation certificate from CPF',
                    () => _downloadCertificate('CPF Certificate'),
                    isApproved,
                  ),
                  _buildDownloadItem(
                    Icons.receipt,
                    'Registration Receipt',
                    'NGO registration acknowledgment receipt',
                    () => _downloadCertificate('Registration Receipt'),
                    true,
                  ),
                  _buildDownloadItem(
                    Icons.description,
                    'Compliance Certificate',
                    'Document compliance verification certificate',
                    () => _downloadCertificate('Compliance Certificate'),
                    isApproved,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Receipts
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Receipts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All validation processes are free of charge as per CPF policy. No payment receipts are generated.',
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

              const SizedBox(height: 16),

              // Documents Archive
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.archive, color: AppTheme.warningOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Document Archive',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDownloadItem(
                      Icons.folder_zip,
                      'Complete Document Package',
                      'Download all submitted documents as ZIP file',
                      () => _downloadCertificate('Document Package'),
                      ngoData['documents'] != null,
                    ),
                    _buildDownloadItem(
                      Icons.history,
                      'Application History',
                      'Complete history of your application process',
                      () => _downloadCertificate('Application History'),
                      true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Helper Methods
      Widget _buildQuickActionCard(
        IconData icon, 
        String title, 
        String subtitle, 
        VoidCallback onTap, 
        Color color,
        {bool enabled = true}
      ) {
        return InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: CustomCard(
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      Widget _buildActivityItem(IconData icon, String title, String description, String time, Color color) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      Widget _buildProfileSection(String title, List<Widget> items) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 16),
                ...items,
              ],
            ),
          ),
        );
      }

      Widget _buildProfileItem(String label, dynamic value) {
        if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }

      Widget _buildDownloadItem(IconData icon, String title, String description, VoidCallback onDownload, bool isAvailable) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable ? AppTheme.borderGray : AppTheme.borderGray.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable 
                      ? AppTheme.primaryRed.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? AppTheme.primaryRed : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Available after approval',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningOrange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CustomButton(
                text: 'Download',
                onPressed: isAvailable ? onDownload : null,
                icon: Icons.download,
                isOutlined: true,
              ),
            ],
          ),
        );
      }

      // UPDATED: Enhanced file upload tile with better metadata display
      Widget _buildFileUploadTile(String label, String documentType, {bool enabled = true}) {
        dynamic file;
        
        if (documentType == 'proposal') {
          file = _proposalDocumentMetadata;
        } else {
          file = _yearlyDocuments[documentType];
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? AppTheme.borderGray : AppTheme.borderGray.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: file != null ? AppTheme.accentGold : 
                      enabled ? AppTheme.primaryRed : AppTheme.textSecondary,
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
                        color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                    if (file != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documentType == 'proposal' 
                                ? file['original_name'] ?? 'Unknown file'
                                : (file as PlatformFile).name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentGold,
                            ),
                          ),
                          Text(
                            'Size: ${_formatFileSize(documentType == 'proposal' ? file['file_size'] ?? 0 : (file as PlatformFile).size)}',
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
                onPressed: enabled ? () => _pickFile(documentType) : null,
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
          default:
            return docType.replaceAll('_', ' ').toUpperCase();
        }
      }

      Color _getStatusColor(String status) {
        switch (status.toLowerCase()) {
          case 'approved':
            return AppTheme.accentGold;
          case 'pending':
          case 'under_review':
            return AppTheme.warningOrange;
          case 'rejected':
            return AppTheme.errorRed;
          case 'submitted':
            return AppTheme.primaryRed;
          default:
            return AppTheme.textSecondary;
        }
      }

      Color _getStepColor(String stepStatus) {
        switch (stepStatus) {
          case 'completed':
            return AppTheme.accentGold;
          case 'active':
            return AppTheme.primaryRed;
          case 'error':
            return AppTheme.errorRed;
          default:
            return AppTheme.textSecondary;
        }
      }

      IconData _getStatusIcon(String status) {
        switch (status.toLowerCase()) {
          case 'approved':
            return Icons.verified;
          case 'pending':
            return Icons.pending;
          case 'under_review':
            return Icons.rate_review;
          case 'rejected':
            return Icons.cancel;
          case 'submitted':
            return Icons.check_circle;
          default:
            return Icons.info;
        }
      }

      String _getStatusTitle(String status) {
        switch (status.toLowerCase()) {
          case 'approved':
            return 'Application Approved';
          case 'pending':
            return 'Under Review';
          case 'under_review':
            return 'Being Reviewed';
          case 'rejected':
            return 'Needs Revision';
          case 'submitted':
            return 'Application Submitted';
          default:
            return 'Draft Application';
        }
      }

      String _getStatusDescription(String status) {
        switch (status.toLowerCase()) {
          case 'approved':
            return 'Your NGO is validated and can submit proposals';
          case 'pending':
            return 'Admin is reviewing your application';
          case 'under_review':
            return 'Documents are being verified';
          case 'rejected':
            return 'Please review feedback and resubmit';
          case 'submitted':
            return 'Application received and queued for review';
          default:
            return 'Complete your profile to submit for review';
        }
      }

      IconData _getActivityIcon(String? type) {
        switch (type?.toLowerCase()) {
          case 'profile_update':
            return Icons.edit;
          case 'document_upload':
            return Icons.upload_file;
          case 'proposal_submitted':
            return Icons.send;
          case 'status_change':
            return Icons.update;
          default:
            return Icons.info;
        }
      }

      Color _getActivityColor(String? type) {
        switch (type?.toLowerCase()) {
          case 'profile_update':
            return AppTheme.primaryRed;
          case 'document_upload':
            return AppTheme.primaryOrange;
          case 'proposal_submitted':
            return AppTheme.accentGold;
          case 'status_change':
            return AppTheme.warningOrange;
          default:
            return AppTheme.textSecondary;
        }
      }

      String _formatDateTime(DateTime date) {
        return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }

      String _formatDate(DateTime date) {
        return '${date.day}/${date.month}/${date.year}';
      }

      // Helper method to format file size
      String _formatFileSize(int bytes) {
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      IconData _getSocialMediaIcon(String platform) {
        switch (platform.toLowerCase()) {
          case 'facebook':
            return Icons.facebook;
          case 'twitter':
            return Icons.alternate_email;
          case 'linkedin':
            return Icons.business;
          case 'instagram':
            return Icons.camera_alt;
          default:
            return Icons.link;
        }
      }
    }

    // Error State Widget
    class ErrorStateWidget extends StatelessWidget {
      final String message;
      final VoidCallback onRetry;

      const ErrorStateWidget({
        super.key,
        required this.message,
        required this.onRetry,
      });

      @override
      Widget build(BuildContext context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retry',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ),
        );
      }
    }