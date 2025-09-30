import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'package:cpf_portal/widgets/loading_widget.dart';
import 'package:cpf_portal/widgets/empty_state_widget.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _donorProfile;
  List<Map<String, dynamic>> _approvedNGOs = [];
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDonorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDonorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/donor-login');
        return;
      }

      // Load donor profile
      final donorDoc =
          await _firestore.collection('donor_profiles').doc(user.uid).get();

      if (donorDoc.exists) {
        _donorProfile = donorDoc.data();
      } else {
        Navigator.pushReplacementNamed(context, '/donor-login');
        return;
      }

      // Load approved NGOs
      final ngoSnapshot = await _firestore
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      _approvedNGOs.clear();
      for (final doc in ngoSnapshot.docs) {
        final data = doc.data();
        data['ngoId'] = doc.id;
        _approvedNGOs.add(data);
      }

      // Load donations (placeholder for now)
      _donations = [];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Text('Welcome, ${_donorProfile?['name'] ?? 'Donor'}'),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDonorData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('View Profile'),
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
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'NGOs', icon: Icon(Icons.business)),
            Tab(text: 'Donations', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading donor data...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _loadDonorData,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildNGOTab(),
                    _buildDonationsTab(),
                  ],
                ),
    );
  }

  Widget _buildDashboardTab() {
    final status = _donorProfile?['status'] ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending, color: AppTheme.warningOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Pending Approval',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningOrange,
                                  ),
                        ),
                        Text(
                          'Your account is under review. You will be notified once approved.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'approved')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Approved',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                        ),
                        Text(
                          'You can now browse and support NGOs.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
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
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available NGOs',
                  _approvedNGOs.length.toString(),
                  AppTheme.primaryRed,
                  Icons.business_center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Donations',
                  _donations.length.toString(),
                  AppTheme.primaryGreen,
                  Icons.favorite,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomCard(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.search,
                              color: AppTheme.primaryRed, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Browse NGOs',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          Text(
                            'Find NGOs to support',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCard(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(2),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.history,
                              color: AppTheme.primaryOrange, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Donation History',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          Text(
                            'View past donations',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNGOTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceWhite,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search NGOs...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryRed),
              ),
            ),
          ),
        ),

        // NGO List
        Expanded(
          child: _approvedNGOs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.business_center,
                  title: 'No NGOs Available',
                  message: 'No approved NGOs found',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _approvedNGOs.length,
                  itemBuilder: (context, index) {
                    final ngo = _approvedNGOs[index];
                    return _buildNGOCard(ngo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDonationsTab() {
    return _donations.isEmpty
        ? const EmptyStateWidget(
            icon: Icons.favorite,
            title: 'No Donations Yet',
            message: 'You haven\'t made any donations yet',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _donations.length,
            itemBuilder: (context, index) {
              final donation = _donations[index];
              return _buildDonationCard(donation);
            },
          );
  }

  Widget _buildNGOCard(Map<String, dynamic> ngo) {
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
                      ngo['organizationName'] ??
                          ngo['ngoName'] ??
                          'Unknown NGO',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ngo['sectorOfWork'] != null &&
              (ngo['sectorOfWork'] as List).isNotEmpty)
            Wrap(
              children: (ngo['sectorOfWork'] as List).map((sector) {
                return Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sector.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
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
              Expanded(
                child: CustomButton(
                  text: 'Support',
                  onPressed: () => _showSupportDialog(ngo),
                  icon: Icons.favorite,
                  backgroundColor: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
          child: Icon(Icons.favorite, color: AppTheme.primaryRed),
        ),
        title: Text(donation['organizationName'] ??
            donation['ngoName'] ??
            'Unknown NGO'),
        subtitle: Text('Amount: \$${donation['amount'] ?? '0'}'),
        trailing: Text(
          donation['date'] ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return CustomCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileField('Name', _donorProfile?['name'] ?? 'N/A'),
            _buildProfileField('Email', _donorProfile?['email'] ?? 'N/A'),
            _buildProfileField(
                'Organization', _donorProfile?['organization'] ?? 'N/A'),
            _buildProfileField('Phone', _donorProfile?['phone'] ?? 'N/A'),
            _buildProfileField(
                'Donor Type', _donorProfile?['donorType'] ?? 'N/A'),
            _buildProfileField('Status', _donorProfile?['status'] ?? 'N/A'),
          ],
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

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              onTap != null ? AppTheme.surfaceWhite : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? AppTheme.borderGray
                : AppTheme.borderGray.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: onTap != null
                    ? AppTheme.primaryRed
                    : AppTheme.textSecondary,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onTap != null
                              ? AppTheme.primaryRed
                              : AppTheme.textSecondary,
                          fontWeight: onTap != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  void _launchWebsite(String url) async {
    try {
      // In a real app, you would use url_launcher package
      // await launchUrl(Uri.parse(url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening website: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open website: $e')),
      );
    }
  }

  void _launchEmail(String email) async {
    try {
      // In a real app, you would use url_launcher package
      // await launchUrl(Uri.parse('mailto:$email'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening email: $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email: $e')),
      );
    }
  }

  void _launchPhone(String phone) async {
    try {
      // In a real app, you would use url_launcher package
      // await launchUrl(Uri.parse('tel:$phone'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening phone: $phone')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone: $e')),
      );
    }
  }

  void _showNGODetails(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ngo['organizationName'] ?? ngo['ngoName'] ?? 'NGO Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NGO Header with Status
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
                    Icon(Icons.verified,
                        color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFIED NGO',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField('Organization Name',
                  ngo['organizationName'] ?? ngo['ngoName'] ?? 'N/A'),
              _buildDetailField('Email', ngo['email'] ?? 'N/A'),
              _buildDetailField('Phone', ngo['phone'] ?? 'N/A'),
              _buildDetailField('Website', ngo['website'] ?? 'N/A'),
              _buildDetailField(
                  'Registration Number', ngo['registrationNumber'] ?? 'N/A'),
              _buildDetailField('PAN Number', ngo['panNumber'] ?? 'N/A'),
              _buildDetailField(
                  '12A Certificate', ngo['certificate12A'] ?? 'N/A'),
              _buildDetailField(
                  '80G Certificate', ngo['certificate80G'] ?? 'N/A'),

              const SizedBox(height: 16),

              // Address Information
              Text(
                'Address Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField('Address', ngo['address'] ?? 'N/A'),
              _buildDetailField('City', ngo['city'] ?? 'N/A'),
              _buildDetailField('State', ngo['state'] ?? 'N/A'),
              _buildDetailField('Pincode', ngo['pincode'] ?? 'N/A'),
              _buildDetailField('Country', ngo['country'] ?? 'N/A'),

              const SizedBox(height: 16),

              // Work Information
              Text(
                'Work Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField('Category', ngo['category'] ?? 'N/A'),
              _buildDetailField('Sectors of Work',
                  (ngo['sectorOfWork'] as List?)?.join(', ') ?? 'N/A'),
              _buildDetailField(
                  'Target Beneficiaries', ngo['targetBeneficiaries'] ?? 'N/A'),
              _buildDetailField(
                  'Geographic Focus', ngo['geographicFocus'] ?? 'N/A'),

              const SizedBox(height: 16),

              // Financial Information
              Text(
                'Financial Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField('Annual Budget', ngo['annualBudget'] ?? 'N/A'),
              _buildDetailField(
                  'Funding Sources', ngo['fundingSources'] ?? 'N/A'),
              _buildDetailField(
                  'Bank Account Number', ngo['bankAccountNumber'] ?? 'N/A'),
              _buildDetailField('Bank Name', ngo['bankName'] ?? 'N/A'),
              _buildDetailField('IFSC Code', ngo['ifscCode'] ?? 'N/A'),

              const SizedBox(height: 16),

              // Contact Person Information
              Text(
                'Contact Person',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField(
                  'Contact Person Name', ngo['contactPersonName'] ?? 'N/A'),
              _buildDetailField('Contact Person Designation',
                  ngo['contactPersonDesignation'] ?? 'N/A'),
              _buildDetailField(
                  'Contact Person Email', ngo['contactPersonEmail'] ?? 'N/A'),
              _buildDetailField(
                  'Contact Person Phone', ngo['contactPersonPhone'] ?? 'N/A'),

              const SizedBox(height: 16),

              // Description
              if (ngo['description'] != null &&
                  ngo['description'].toString().isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderGray),
                  ),
                  child: Text(
                    ngo['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Registration Dates
              Text(
                'Registration Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              _buildDetailField(
                  'Registration Date', ngo['registrationDate'] ?? 'N/A'),
              _buildDetailField(
                  'Application Date',
                  ngo['createdAt'] != null
                      ? (ngo['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                      : 'N/A'),
              _buildDetailField(
                  'Approval Date',
                  ngo['approvedAt'] != null
                      ? (ngo['approvedAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                      : 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSupportDialog(ngo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Support NGO'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Support ${ngo['organizationName'] ?? ngo['ngoName'] ?? 'NGO'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NGO Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business,
                            color: AppTheme.primaryRed, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'NGO Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryRed,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ngo['organizationName'] ??
                          ngo['ngoName'] ??
                          'Unknown NGO',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    if (ngo['email'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${ngo['email']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                    if (ngo['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${ngo['phone']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CPF Contact Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_support,
                            color: AppTheme.accentGold, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Contact CPF for Support',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentGold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To support this NGO or for any donation-related queries, please contact CPF:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Details
                    _buildContactItem(
                      Icons.web,
                      'Website',
                      'www.cpf.org.in',
                      () => _launchWebsite('https://www.cpf.org.in'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.email,
                      'Email',
                      'info@cpf.org.in',
                      () => _launchEmail('info@cpf.org.in'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.phone,
                      'Phone',
                      '+91-XXXXXXXXXX',
                      () => _launchPhone('+91XXXXXXXXXX'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.location_on,
                      'Address',
                      'CPF Office, City, State, India',
                      null,
                    ),

                    const SizedBox(height: 16),

                    // Additional Information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Process:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Contact CPF through any of the above channels\n'
                            '2. Specify the NGO you want to support\n'
                            '3. CPF will guide you through the donation process\n'
                            '4. All donations are tax-deductible under 80G',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Note
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
                    Icon(Icons.info, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All donations are processed through CPF to ensure transparency and proper documentation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryGreen,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchWebsite('https://www.cpf.org.in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Visit CPF Website'),
          ),
        ],
      ),
    );
  }
}
