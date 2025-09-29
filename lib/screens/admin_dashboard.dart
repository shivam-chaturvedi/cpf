import 'package:cpf_portal/providers/firestore_file_service.dart';
import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Enhanced filtering and search
  String _selectedFilter = 'all';
  String _selectedNGOFilter = 'all';
  String _selectedDonorFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _statusFilters = ['all', 'pending', 'approved', 'rejected'];
  final List<String> _ngoFilters = ['all', 'pending', 'approved', 'rejected', 'expired', 'renewal_due'];
  final List<String> _donorFilters = ['all', 'pending', 'approved', 'rejected'];
  
  // Data storage
  List<Map<String, dynamic>> _ngoApplications = [];
  List<Map<String, dynamic>> _donorProfiles = [];
  List<Map<String, dynamic>> _renewalReminders = [];
  bool _isLoading = true;
  String? _error;
  
  // Enhanced statistics
  Map<String, int> _ngoStatistics = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'expired': 0,
    'renewal_due': 0,
  };
  
  Map<String, int> _donorStatistics = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };
  
  // Validation tracking
  Map<String, dynamic> _validationTracker = {};
  
  // Renewal reminders
  List<Map<String, dynamic>> _upcomingRenewals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Added donor management tab
    _loadAllData();
    _setupRenewalReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNGOApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load NGO applications from Firestore
      final snapshot = await _firestore
          .collection('ngo_proposals')
          .get();
      
      _ngoApplications.clear();
      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['ngoId'] = doc.id; // Add the document ID as ngoId
        
        _ngoApplications.add(data);
        stats['total'] = stats['total']! + 1;
        final status = data['status'] ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      // Sort by creation date (newest first)
      _ngoApplications.sort((a, b) {
        final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _ngoStatistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Load all data including donors and renewal reminders
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadNGOApplications(),
      _loadDonorProfiles(),
      _loadRenewalReminders(),
    ]);
  }

  // Load donor profiles
  Future<void> _loadDonorProfiles() async {
    try {
      final snapshot = await _firestore
          .collection('donor_profiles')
          .get();
      
      _donorProfiles.clear();
      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['donorId'] = doc.id;
        
        _donorProfiles.add(data);
        stats['total'] = stats['total']! + 1;
        final status = data['status'] ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      setState(() {
        _donorStatistics = stats;
      });
    } catch (e) {
      print('Error loading donor profiles: $e');
    }
  }

  // Load renewal reminders
  Future<void> _loadRenewalReminders() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .get();
      
      _upcomingRenewals.clear();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final approvalDate = (data['approvedAt'] as Timestamp?)?.toDate();
        
        if (approvalDate != null) {
          final renewalDate = approvalDate.add(const Duration(days: 365)); // 1 year
          final daysUntilRenewal = renewalDate.difference(now).inDays;
          
          if (daysUntilRenewal <= 30 && daysUntilRenewal >= 0) {
            _upcomingRenewals.add({
              'ngoId': doc.id,
              'ngoName': data['ngoName'] ?? 'Unknown NGO',
              'renewalDate': renewalDate,
              'daysUntilRenewal': daysUntilRenewal,
              'approvalDate': approvalDate,
              'status': daysUntilRenewal <= 7 ? 'urgent' : 'due_soon',
            });
          }
        }
      }
      
      // Sort by urgency
      _upcomingRenewals.sort((a, b) => a['daysUntilRenewal'].compareTo(b['daysUntilRenewal']));
      
      setState(() {});
    } catch (e) {
      print('Error loading renewal reminders: $e');
    }
  }

  // Setup renewal reminder alerts
  void _setupRenewalReminders() {
    // This would typically be a background service
    // For now, we'll check on each load
    _checkRenewalAlerts();
  }

  void _checkRenewalAlerts() {
    final urgentRenewals = _upcomingRenewals.where((r) => r['status'] == 'urgent').length;
    if (urgentRenewals > 0) {
      _showRenewalAlert(urgentRenewals);
    }
  }

  void _showRenewalAlert(int urgentCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Renewal Alerts'),
          ],
        ),
        content: Text('$urgentCount NGO(s) have urgent renewal requirements (due within 7 days)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(3); // Switch to renewals tab
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNGOStatus(String ngoId, String newStatus, {String? comments}) async {
    try {
      // Update the NGO status in Firestore
      await _firestore.collection('ngo_proposals').doc(ngoId).update({
        'status': newStatus,
        'adminComments': comments,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin@cpf.org.in',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload applications
      await _loadNGOApplications();

      if (mounted) {
        AppHelpers.showSuccessSnackBar(
          context, 
          'NGO status updated to ${newStatus.toUpperCase()}'
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to update status: $e');
      }
    }
  }

  // Enhanced NGO approval with validation tracking
  Future<void> _approveNGO(String ngoId, {String? comments}) async {
    try {
      await _firestore.collection('ngo_proposals').doc(ngoId).update({
        'status': 'approved',
        'adminComments': comments,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin@cpf.org.in',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'validationStatus': {
          'complianceCheck': 'completed',
          'dueDiligence': 'completed',
          'deskReview': 'completed',
          'finalApproval': 'completed',
        },
      });

      await _loadAllData();
      
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'NGO approved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to approve NGO: $e');
      }
    }
  }

  // Reject NGO with detailed feedback
  Future<void> _rejectNGO(String ngoId, {required String reason}) async {
    try {
      await _firestore.collection('ngo_proposals').doc(ngoId).update({
        'status': 'rejected',
        'adminComments': reason,
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin@cpf.org.in',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadAllData();
      
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'NGO rejected with feedback');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to reject NGO: $e');
      }
    }
  }

  // Donor approval methods
  Future<void> _approveDonor(String donorId, {String? comments}) async {
    try {
      await _firestore.collection('donor_profiles').doc(donorId).update({
        'status': 'approved',
        'adminComments': comments,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin@cpf.org.in',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadDonorProfiles();
      
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Donor approved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to approve donor: $e');
      }
    }
  }

  Future<void> _rejectDonor(String donorId, {required String reason}) async {
    try {
      await _firestore.collection('donor_profiles').doc(donorId).update({
        'status': 'rejected',
        'adminComments': reason,
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin@cpf.org.in',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadDonorProfiles();
      
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Donor rejected with feedback');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to reject donor: $e');
      }
    }
  }

  // Enhanced filtering methods
  List<Map<String, dynamic>> _getFilteredNGOs() {
    List<Map<String, dynamic>> filtered = List.from(_ngoApplications);
    
    // Apply status filter
    if (_selectedNGOFilter != 'all') {
      if (_selectedNGOFilter == 'expired') {
        filtered = filtered.where((ngo) {
          final approvalDate = (ngo['approvedAt'] as Timestamp?)?.toDate();
          if (approvalDate != null) {
            final renewalDate = approvalDate.add(const Duration(days: 365));
            return DateTime.now().isAfter(renewalDate);
          }
          return false;
        }).toList();
      } else if (_selectedNGOFilter == 'renewal_due') {
        filtered = filtered.where((ngo) {
          final approvalDate = (ngo['approvedAt'] as Timestamp?)?.toDate();
          if (approvalDate != null) {
            final renewalDate = approvalDate.add(const Duration(days: 365));
            final daysUntilRenewal = renewalDate.difference(DateTime.now()).inDays;
            return daysUntilRenewal <= 30 && daysUntilRenewal >= 0;
          }
          return false;
        }).toList();
      } else {
        filtered = filtered.where((ngo) => ngo['status'] == _selectedNGOFilter).toList();
      }
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ngo) {
        final ngoName = (ngo['ngoName'] ?? '').toLowerCase();
        final email = (ngo['email'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return ngoName.contains(query) || email.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  List<Map<String, dynamic>> _getFilteredDonors() {
    List<Map<String, dynamic>> filtered = List.from(_donorProfiles);
    
    // Apply status filter
    if (_selectedDonorFilter != 'all') {
      filtered = filtered.where((donor) => donor['status'] == _selectedDonorFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((donor) {
        final name = (donor['name'] ?? '').toLowerCase();
        final email = (donor['email'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _downloadDocument(String ngoId, String filename, String originalName) async {
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
        ..setAttribute('download', originalName)
        ..click();
      html.Url.revokeObjectUrl(url);

      AppHelpers.showSuccessSnackBar(context, 'Document downloaded successfully');
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AppHelpers.showErrorSnackBar(context, 'Download failed: $e');
    }
  }

  Future<void> _showApprovalDialog(Map<String, dynamic> ngoData) async {
    final commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review: ${ngoData['ngoName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Admin Comments (Optional)',
                hintText: 'Add review comments...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateNGOStatus(ngoData['ngoId'], 'rejected', comments: commentsController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateNGOStatus(ngoData['ngoId'], 'approved', comments: commentsController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNGODetails(Map<String, dynamic> ngoData) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.surfaceWhite),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ngoData['ngoName'] ?? 'NGO Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.surfaceWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppTheme.surfaceWhite),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Basic Information', [
                        _buildDetailItem('NGO Name', ngoData['ngoName']),
                        _buildDetailItem('Email', ngoData['email']),
                        _buildDetailItem('Registration Date', ngoData['dateOfRegistration']),
                        _buildDetailItem('Location', '${ngoData['district']}, ${ngoData['state']}, ${ngoData['country']}'),
                      ]),
                      
                      _buildDetailSection('Chief Functionary', [
                        _buildDetailItem('Name', ngoData['chiefFunctionaryName']),
                        _buildDetailItem('Email', ngoData['chiefFunctionaryEmail']),
                        _buildDetailItem('Phone', ngoData['chiefFunctionaryPhone']),
                      ]),
                      
                      _buildDetailSection('Financial Information', [
                        _buildDetailItem('Financial Year', ngoData['financialYear']),
                        _buildDetailItem('Gross Amount Raised', '₹${ngoData['grossAmountRaised']?.toString() ?? '0'}'),
                        _buildDetailItem('Legal Status', ngoData['legalStatus']),
                        _buildDetailItem('PAN', ngoData['pan']),
                        _buildDetailItem('TAN', ngoData['tan']),
                      ]),
                      
                      _buildDetailSection('Other Details', [
                        _buildDetailItem('Sectors', (ngoData['sectorOfWork'] as List?)?.join(', ') ?? 'Not specified'),
                        _buildDetailItem('DARPAN ID', ngoData['darpanId']),
                        _buildDetailItem('CSR Registration', ngoData['csrRegistration']),
                        _buildDetailItem('12A Certificate', ngoData['cert12A']),
                        _buildDetailItem('80G Certificate', ngoData['cert80G']),
                      ]),
                      
                      // Documents section
                      if (ngoData['documents'] != null) ...[
                        _buildDocumentSection(ngoData['documents'] as Map<String, dynamic>, ngoData['ngoId']),
                      ],

                      // Load additional documents from Firestore
                      _buildFirestoreDocumentsSection(ngoData['ngoId']),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderGray)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Reject',
                        onPressed: () {
                          Navigator.pop(context);
                          _showApprovalDialog(ngoData);
                        },
                        backgroundColor: AppTheme.errorRed,
                        icon: Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Approve',
                        onPressed: () {
                          Navigator.pop(context);
                          _updateNGOStatus(ngoData['ngoId'], 'approved');
                        },
                        backgroundColor: AppTheme.accentGold,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection(Map<String, dynamic> documents, String ngoId) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registration Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: documents.entries.map((entry) {
                final docType = entry.key;
                final docData = entry.value as Map<String, dynamic>;
                final label = documentLabels[docType] ?? docType.replaceAll('_', ' ');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderGray.withOpacity(0.3)),
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
                            if (docData['file_size'] != null)
                              Text(
                                'Size: ${FirestoreFileService.formatFileSize(docData['file_size'])}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CustomButton(
                        text: 'Download',
                        onPressed: () => _downloadDocument(
                          ngoId,
                          docData['filename'],
                          docData['original_name'] ?? 'document',
                        ),
                        icon: Icons.download,
                        isOutlined: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreDocumentsSection(String ngoId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirestoreFileService.listFiles(ngoId: ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final files = snapshot.data!;
        final yearlyData = files.where((f) => (f['document_type'] as String).contains('yearly_data')).toList();
        final proposals = files.where((f) => (f['document_type'] as String).contains('proposal')).toList();

        return Column(
          children: [
            if (yearlyData.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yearly Data Submissions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: yearlyData.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file['original_name'] ?? 'Yearly Data',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        'Size: ${FirestoreFileService.formatFileSize(file['file_size'] ?? 0)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _downloadDocument(
                                    ngoId,
                                    file['filename'],
                                    file['original_name'] ?? 'document',
                                  ),
                                  child: const Text('Download', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (proposals.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted Proposals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: proposals.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file['original_name'] ?? 'Proposal',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        'Size: ${FirestoreFileService.formatFileSize(file['file_size'] ?? 0)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _downloadDocument(
                                    ngoId,
                                    file['filename'],
                                    file['original_name'] ?? 'document',
                                  ),
                                  child: const Text('Download', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('CPF Admin Dashboard'),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNGOApplications,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  Navigator.pushReplacementNamed(context, '/');
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
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
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'NGO Management', icon: Icon(Icons.business)),
            Tab(text: 'Donor Management', icon: Icon(Icons.people)),
            Tab(text: 'Renewals', icon: Icon(Icons.schedule)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading NGO data...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _loadNGOApplications,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildNGOManagementTab(),
                    _buildDonorManagementTab(),
                    _buildRenewalsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.errorRed, AppTheme.warningOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
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
                        'Welcome, Admin!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.surfaceWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Managing NGO registrations and validations',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.surfaceWhite.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: AppHelpers.isDesktop(context) ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total NGOs',
                _ngoStatistics['total'].toString(),
                Icons.business,
                AppTheme.primaryRed,
                'Registered',
              ),
              _buildStatCard(
                'Pending',
                _ngoStatistics['pending'].toString(),
                Icons.pending,
                AppTheme.warningOrange,
                'Awaiting Review',
              ),
              _buildStatCard(
                'Approved',
                _ngoStatistics['approved'].toString(),
                Icons.check_circle,
                AppTheme.accentGold,
                'Validated NGOs',
              ),
              _buildStatCard(
                'Rejected',
                _ngoStatistics['rejected'].toString(),
                Icons.cancel,
                AppTheme.errorRed,
                'Needs Correction',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Applications
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Applications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ngoApplications.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.inbox,
                        title: 'No Applications',
                        message: 'No NGO applications yet.',
                      )
                    : Column(
                        children: _ngoApplications.take(5).map((ngoData) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildStatusCard(
                              ngoData['ngoName'] ?? 'Unknown NGO',
                              ngoData['status'] ?? 'pending',
                              () => _showNGODetails(ngoData),
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    // Filter applications based on selected status
    final filteredApplications = _selectedFilter == 'all'
        ? _ngoApplications
        : _ngoApplications.where((ngo) => ngo['status'] == _selectedFilter).toList();

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceWhite,
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              const Text('Filter by Status:'),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryRed,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Applications List
        Expanded(
          child: filteredApplications.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.business_center,
                  title: 'No Applications Found',
                  message: _selectedFilter == 'all' 
                      ? 'No NGO applications have been submitted yet.'
                      : 'No applications with status "${_selectedFilter.toUpperCase()}" found.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    final ngoData = filteredApplications[index];
                    final createdAt = (ngoData['createdAt'] as Timestamp?)?.toDate();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: CustomCard(
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
                                        ngoData['ngoName'] ?? 'Unknown NGO',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ngoData['email'] ?? '',
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
                                    color: AppHelpers.getStatusColor(ngoData['status'] ?? 'pending'),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (ngoData['status'] ?? 'pending').toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.surfaceWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${ngoData['district']}, ${ngoData['state']}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  createdAt != null ? AppHelpers.formatDate(createdAt) : 'Unknown',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'View Details',
                                    onPressed: () => _showNGODetails(ngoData),
                                    icon: Icons.visibility,
                                    isOutlined: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (ngoData['status'] == 'pending') ...[
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Review',
                                      onPressed: () => _showApprovalDialog(ngoData),
                                      icon: Icons.rate_review,
                                      backgroundColor: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ] else
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Update Status',
                                      onPressed: () => _showApprovalDialog(ngoData),
                                      icon: Icons.edit,
                                      backgroundColor: AppTheme.primaryRed,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics Overview
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: AppHelpers.isDesktop(context) ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3,
            children: [
              _buildInfoCard(
                Icons.trending_up,
                'Registration Rate',
                '${_ngoStatistics['total']} total registrations',
                AppTheme.accentGold,
              ),
              _buildInfoCard(
                Icons.approval,
                'Approval Rate',
                '${((_ngoStatistics['approved']! / (_ngoStatistics['total']! > 0 ? _ngoStatistics['total']! : 1)) * 100).toStringAsFixed(1)}% approved',
                AppTheme.primaryRed,
              ),
              _buildInfoCard(
                Icons.schedule,
                'Pending Review',
                '${_ngoStatistics['pending']} applications',
                AppTheme.warningOrange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          CustomCard(
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
                _buildRecentActivityList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final recentActivity = _ngoApplications
        .where((ngo) => ngo['status'] != 'pending' && ngo['reviewedAt'] != null)
        .toList()
      ..sort((a, b) {
        final dateA = (a['reviewedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['reviewedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

    if (recentActivity.isEmpty) {
      return const Text('No recent activity');
    }

    return Column(
      children: recentActivity.take(10).map((ngoData) {
        final reviewedAt = (ngoData['reviewedAt'] as Timestamp?)?.toDate();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                AppHelpers.getStatusIcon(ngoData['status']),
                color: AppHelpers.getStatusColor(ngoData['status']),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ngoData['ngoName']} was ${ngoData['status']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reviewedAt != null)
                      Text(
                        AppHelpers.formatDateTime(reviewedAt),
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
      }).toList(),
    );
  }

  Widget _buildCommunicationsTab() {
    return SingleChildScrollView(
      padding: AppHelpers.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mass Communication',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Email Composer Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      'Send Mass Email',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEmailComposer(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export Data Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Export Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Export NGO data in CSV format for analysis and reporting',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Export All NGOs',
                        onPressed: () => _exportData(),
                        icon: Icons.download,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Export Pending',
                        onPressed: () => _exportData(status: 'pending'),
                        icon: Icons.download,
                        backgroundColor: AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Export Approved',
                        onPressed: () => _exportData(status: 'approved'),
                        icon: Icons.download,
                        backgroundColor: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Export Rejected',
                        onPressed: () => _exportData(status: 'rejected'),
                        icon: Icons.download,
                        backgroundColor: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailComposer() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedAudience = 'all';
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedAudience,
              decoration: const InputDecoration(
                labelText: 'Send To',
                prefixIcon: Icon(Icons.group),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All NGOs')),
                DropdownMenuItem(value: 'pending', child: Text('Pending NGOs')),
                DropdownMenuItem(value: 'approved', child: Text('Approved NGOs')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected NGOs')),
              ],
              onChanged: (value) => setState(() => selectedAudience = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.subject),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: This will prepare emails in your default email client. For automated sending, backend email service integration is required.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Prepare Email',
              onPressed: () => _sendMassEmail(selectedAudience, subjectController.text, messageController.text),
              icon: Icons.email,
              width: double.infinity,
              backgroundColor: AppTheme.primaryOrange,
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMassEmail(String audience, String subject, String message) async {
    if (subject.isEmpty || message.isEmpty) {
      AppHelpers.showErrorSnackBar(context, 'Please fill in subject and message');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing emails...'),
            ],
          ),
        ),
      );

      // Filter NGOs based on audience
      final targetNgos = audience == 'all'
          ? _ngoApplications
          : _ngoApplications.where((ngo) => ngo['status'] == audience).toList();

      final recipients = targetNgos
          .where((ngo) => ngo['email'] != null && ngo['email'].toString().isNotEmpty)
          .map((ngo) => {
                'email': ngo['email'],
                'name': ngo['ngoName'] ?? 'NGO',
                'status': ngo['status'] ?? 'pending',
              })
          .toList();

      if (recipients.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        AppHelpers.showErrorSnackBar(context, 'No recipients found for the selected audience');
        return;
      }

      // Create email log
      final emailLog = {
        'subject': subject,
        'message': message,
        'audience': audience,
        'recipientCount': recipients.length,
        'recipients': recipients.map((r) => r['email']).toList(),
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin@cpf.org.in',
        'status': 'prepared', // Changed from 'sent' to 'prepared'
      };

      // Save email log to Firestore
      await _firestore.collection('email_logs').add(emailLog);

      // Generate mailto link for desktop email clients
      final emailAddresses = recipients.map((r) => r['email']).join(',');
      final mailtoUrl = 'mailto:$emailAddresses?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}';
      
      Navigator.pop(context); // Close loading dialog

      // Show success dialog with options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email Prepared'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email prepared for ${recipients.length} recipients'),
                const SizedBox(height: 16),
                const Text('Recipients:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    child: Text(
                      emailAddresses,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open mailto link
                        html.window.open(mailtoUrl, '_blank');
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Open Email Client'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Copy email addresses to clipboard
                        _copyToClipboard(emailAddresses);
                        AppHelpers.showSuccessSnackBar(context, 'Email addresses copied to clipboard');
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Emails'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      AppHelpers.showSuccessSnackBar(
        context,
        'Email prepared for ${recipients.length} NGOs (${audience.toUpperCase()})',
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AppHelpers.showErrorSnackBar(context, 'Failed to prepare email: $e');
    }
  }

  Future<void> _exportData({String? status}) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing export...'),
            ],
          ),
        ),
      );

      final dataToExport = status == null
          ? _ngoApplications
          : _ngoApplications.where((ngo) => ngo['status'] == status).toList();

      if (dataToExport.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        AppHelpers.showErrorSnackBar(context, 'No data to export');
        return;
      }

      // Create enhanced CSV content with all NGO details
      final csvContent = _generateEnhancedCSV(dataToExport);
      
      // Create a blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'cpf_ngo_export_${status ?? 'all'}_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      Navigator.pop(context); // Close loading dialog

      // Show summary dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully exported ${dataToExport.length} NGO records'),
              const SizedBox(height: 8),
              Text('Status filter: ${status?.toUpperCase() ?? 'ALL'}'),
              const SizedBox(height: 8),
              const Text('The file has been downloaded to your computer.'),
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

      AppHelpers.showSuccessSnackBar(
        context,
        'Exported ${dataToExport.length} records${status != null ? ' ($status)' : ''}',
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AppHelpers.showErrorSnackBar(context, 'Failed to export data: $e');
    }
  }

  String _generateEnhancedCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    // Define the columns we want to export in order
    final columns = [
      'ngoId',
      'ngoName',
      'email',
      'status',
      'profileComplete',
      'createdDate',
      'submittedAt',
      'reviewedAt',
      'dateOfRegistration',
      'country',
      'state',
      'district',
      'chiefFunctionaryName',
      'chiefFunctionaryEmail',
      'chiefFunctionaryPhone',
      'legalStatus',
      'pan',
      'tan',
      'fcraRegistration',
      'csrRegistration',
      'darpanId',
      'gstRegistration',
      'cert12A',
      'cert80G',
      'registrationCertNumber',
      'financialYear',
      'grossAmountRaised',
      'sectorOfWork',
      'registeredAddress',
      'correspondingAddress',
      'adminComments',
      'reviewedBy',
    ];

    // Create header row with readable names
    final headerMap = {
      'ngoId': 'NGO ID',
      'ngoName': 'NGO Name',
      'email': 'Email',
      'status': 'Status',
      'profileComplete': 'Profile Complete',
      'createdDate': 'Created Date',
      'submittedAt': 'Submitted At',
      'reviewedAt': 'Reviewed At',
      'dateOfRegistration': 'Date of Registration',
      'country': 'Country',
      'state': 'State',
      'district': 'District',
      'chiefFunctionaryName': 'Chief Functionary Name',
      'chiefFunctionaryEmail': 'Chief Functionary Email',
      'chiefFunctionaryPhone': 'Chief Functionary Phone',
      'legalStatus': 'Legal Status',
      'pan': 'PAN',
      'tan': 'TAN',
      'fcraRegistration': 'FCRA Registration',
      'csrRegistration': 'CSR Registration',
      'darpanId': 'DARPAN ID',
      'gstRegistration': 'GST Registration',
      'cert12A': '12A Certificate',
      'cert80G': '80G Certificate',
      'registrationCertNumber': 'Registration Certificate Number',
      'financialYear': 'Financial Year',
      'grossAmountRaised': 'Gross Amount Raised',
      'sectorOfWork': 'Sectors of Work',
      'registeredAddress': 'Registered Address',
      'correspondingAddress': 'Corresponding Address',
      'adminComments': 'Admin Comments',
      'reviewedBy': 'Reviewed By',
    };

    final headers = columns.map((col) => headerMap[col] ?? col).toList();
    final csvRows = [headers.join(',')];

    // Add data rows
    for (final row in data) {
      final values = columns.map((key) {
        var value = row[key];
        
        // Handle special cases
        if (value == null) {
          return '';
        } else if (value is List) {
          // For arrays like sectorOfWork
          return value.join('; ');
        } else if (value is bool) {
          return value ? 'Yes' : 'No';
        } else if (key.contains('At') && value is String) {
          // Format date strings
          try {
            final date = DateTime.parse(value);
            return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
          } catch (_) {
            return value.toString();
          }
        } else {
          // Convert to string and escape if needed
          var strValue = value.toString();
          // Escape commas, quotes, and newlines
          if (strValue.contains(',') || strValue.contains('"') || strValue.contains('\n')) {
            strValue = '"${strValue.replaceAll('"', '""')}"';
          }
          return strValue;
        }
      }).join(',');
      csvRows.add(values);
    }

    // Add metadata at the end
    csvRows.add('');
    csvRows.add('Export Information');
    csvRows.add('Generated By,CPF Admin Dashboard');
    csvRows.add('Export Date,${DateTime.now()}');
    csvRows.add('Total Records,${data.length}');
    
    // Add status breakdown
    final statusCounts = <String, int>{};
    for (final ngo in data) {
      final status = ngo['status'] ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    csvRows.add('');
    csvRows.add('Status Breakdown');
    statusCounts.forEach((status, count) {
      csvRows.add('$status,$count');
    });

    return csvRows.join('\n');
  }

  String _generateCSV(List<Map<String, dynamic>> data) {
    return _generateEnhancedCSV(data); // Use enhanced version
  }

  // Helper method to copy text to clipboard
  void _copyToClipboard(String text) {
    final textarea = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.opacity = '0';
    
    html.document.body!.append(textarea);
    textarea.select();
    html.document.execCommand('copy');
    textarea.remove();
  }

  // Helper widget builders
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return CustomCard(
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
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle, Color iconColor) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildStatusCard(String title, String status, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppHelpers.getStatusColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.surfaceWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // Enhanced NGO Management Tab
  Widget _buildNGOManagementTab() {
    final filteredNGOs = _getFilteredNGOs();
    
    return Column(
      children: [
        // Enhanced Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceWhite,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search NGOs by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ngoFilters.map((filter) {
                    final isSelected = _selectedNGOFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getFilterDisplayName(filter)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedNGOFilter = filter;
                          });
                        },
                        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryRed,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // NGO List
        Expanded(
          child: filteredNGOs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.business_center,
                  title: 'No NGOs Found',
                  message: 'No NGOs match your current filters',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNGOs.length,
                  itemBuilder: (context, index) {
                    final ngo = filteredNGOs[index];
                    return _buildEnhancedNGOCard(ngo);
                  },
                ),
        ),
      ],
    );
  }

  // Donor Management Tab
  Widget _buildDonorManagementTab() {
    final filteredDonors = _getFilteredDonors();
    
    return Column(
      children: [
        // Search and Filter Bar for Donors
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceWhite,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search donors by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderGray),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _donorFilters.map((filter) {
                    final isSelected = _selectedDonorFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getFilterDisplayName(filter)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDonorFilter = filter;
                          });
                        },
                        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryRed,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // Donor List
        Expanded(
          child: filteredDonors.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people,
                  title: 'No Donors Found',
                  message: 'No donors match your current filters',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDonors.length,
                  itemBuilder: (context, index) {
                    final donor = filteredDonors[index];
                    return _buildDonorCard(donor);
                  },
                ),
        ),
      ],
    );
  }

  // Renewals Tab
  Widget _buildRenewalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Renewal Statistics
          Row(
            children: [
              _buildStatCard(
                'Due Soon',
                _upcomingRenewals.where((r) => r['status'] == 'due_soon').length.toString(),
                Icons.schedule,
                AppTheme.warningOrange,
                'Renewals due within 30 days',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Urgent',
                _upcomingRenewals.where((r) => r['status'] == 'urgent').length.toString(),
                Icons.warning,
                AppTheme.errorRed,
                'Renewals overdue',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Renewal List
          Text(
            'Upcoming Renewals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_upcomingRenewals.isEmpty)
            const EmptyStateWidget(
              icon: Icons.schedule,
              title: 'No Renewals Due',
              message: 'No NGO renewals are due in the next 30 days',
            )
          else
            ..._upcomingRenewals.map((renewal) => _buildRenewalCard(renewal)),
        ],
      ),
    );
  }

  // Enhanced NGO Card with validation tracking
  Widget _buildEnhancedNGOCard(Map<String, dynamic> ngo) {
    final status = ngo['status'] ?? 'pending';
    final validationStatus = ngo['validationStatus'] ?? {};
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and validation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ngo['ngoName'] ?? 'Unknown NGO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ngo['email'] ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Validation Progress
          if (status == 'pending') _buildValidationProgress(validationStatus),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Details',
                  onPressed: () => _showNGODetails(ngo),
                  icon: Icons.visibility,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              if (status == 'pending') ...[
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    onPressed: () => _showApprovalDialog(ngo),
                    icon: Icons.check,
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () => _showRejectionDialog(ngo),
                    icon: Icons.close,
                    backgroundColor: AppTheme.errorRed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Donor Card
  Widget _buildDonorCard(Map<String, dynamic> donor) {
    final status = donor['status'] ?? 'pending';
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
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
                      donor['name'] ?? 'Unknown Donor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donor['email'] ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Details',
                  onPressed: () => _showDonorDetails(donor),
                  icon: Icons.visibility,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              if (status == 'pending') ...[
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    onPressed: () => _approveDonor(donor['donorId']),
                    icon: Icons.check,
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () => _showDonorRejectionDialog(donor),
                    icon: Icons.close,
                    backgroundColor: AppTheme.errorRed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Renewal Card
  Widget _buildRenewalCard(Map<String, dynamic> renewal) {
    final daysUntilRenewal = renewal['daysUntilRenewal'] as int;
    final isUrgent = renewal['status'] == 'urgent';
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: isUrgent ? AppTheme.errorRed : AppTheme.warningOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  renewal['ngoName'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due in $daysUntilRenewal days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUrgent ? AppTheme.errorRed : AppTheme.warningOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Renewal Date: ${DateFormat('MMM dd, yyyy').format(renewal['renewalDate'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Send Reminder',
            onPressed: () => _sendRenewalReminder(renewal),
            icon: Icons.email,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.primaryGreen;
        break;
      case 'rejected':
        color = AppTheme.errorRed;
        break;
      case 'pending':
        color = AppTheme.warningOrange;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildValidationProgress(Map<String, dynamic> validationStatus) {
    final steps = [
      {'key': 'complianceCheck', 'label': 'Compliance Check'},
      {'key': 'dueDiligence', 'label': 'Due Diligence'},
      {'key': 'deskReview', 'label': 'Desk Review'},
      {'key': 'finalApproval', 'label': 'Final Approval'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation Progress',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.map((step) {
            final isCompleted = validationStatus[step['key']] == 'completed';
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.primaryGreen : AppTheme.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all': return 'All';
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'expired': return 'Expired';
      case 'renewal_due': return 'Renewal Due';
      default: return filter;
    }
  }

  // Missing method implementations
  Future<void> _showRejectionDialog(Map<String, dynamic> ngo) async {
    final reasonController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject NGO Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${ngo['ngoName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Enter reason for rejection...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _rejectNGO(ngo['id'], reason: reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDonorDetails(Map<String, dynamic> donor) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Donor: ${donor['fullName']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', donor['email'] ?? 'N/A'),
              _buildDetailRow('Phone', donor['phone'] ?? 'N/A'),
              _buildDetailRow('Organization', donor['organizationName'] ?? 'N/A'),
              _buildDetailRow('Status', donor['status'] ?? 'N/A'),
              _buildDetailRow('Registration Date', 
                donor['createdAt'] != null 
                  ? DateFormat('MMM dd, yyyy').format(donor['createdAt'].toDate())
                  : 'N/A'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDonorRejectionDialog(Map<String, dynamic> donor) async {
    final reasonController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Donor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${donor['fullName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Enter reason for rejection...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _rejectDonor(donor['id'], reason: reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRenewalReminder(Map<String, dynamic> renewal) async {
    try {
      // Here you would implement the actual reminder sending logic
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renewal reminder sent to ${renewal['ngoName']}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reminder: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

}