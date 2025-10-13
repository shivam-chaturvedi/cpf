import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpf_portal/util/helpers.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/widgets/custom_button.dart';
import 'package:cpf_portal/widgets/custome_card.dart';
import 'package:cpf_portal/widgets/loading_widget.dart';
import 'package:cpf_portal/widgets/empty_state_widget.dart';
import 'package:cpf_portal/widgets/custom_navbar.dart';
import 'package:cpf_portal/services/donor_ngo_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> _filteredNGOs = [];
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _ngoSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDonorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ngoSearchController.dispose();
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

      // Load donor profile from either collection
      final donorProfilesDoc =
          await _firestore.collection('donor_profiles').doc(user.uid).get();
      final donorsDoc =
          await _firestore.collection('donors').doc(user.uid).get();

      if (donorProfilesDoc.exists) {
        _donorProfile = donorProfilesDoc.data();
      } else if (donorsDoc.exists) {
        _donorProfile = donorsDoc.data();
      } else {
        Navigator.pushReplacementNamed(context, '/donor-login');
        return;
      }

      // Check if donor is verified before loading NGOs
      final donorStatus = _donorProfile?['status'] ?? 'pending';

      _approvedNGOs.clear();
      if (donorStatus == 'approved') {
        // Load ONLY assigned NGOs for this donor
        print('Loading assigned NGOs for donor: ${user.uid}');
        final assignedNGOIds = await DonorNGOService.getAssignedNGOs(user.uid);
        print('Assigned NGO IDs: $assignedNGOIds');

        if (assignedNGOIds.isNotEmpty) {
          for (final ngoId in assignedNGOIds) {
            final ngoDoc =
                await _firestore.collection('ngo_proposals').doc(ngoId).get();

            if (ngoDoc.exists) {
              final data = ngoDoc.data()!;
              data['ngoId'] = ngoId;
              _approvedNGOs.add(data);
              print(
                  'Added NGO: ${data['ngoName'] ?? data['organizationName']}');
            }
          }
        } else {
          print('No NGOs assigned to this donor');
        }
      }
      // If donor is not approved or has no assignments, _approvedNGOs remains empty

      // Load donations (placeholder for now)
      _donations = [];

      // Initialize filtered NGOs
      _filteredNGOs = List.from(_approvedNGOs);

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

  void _filterNGOs() {
    setState(() {
      _filteredNGOs = _approvedNGOs.where((ngo) {
        final searchQuery = _ngoSearchController.text.toLowerCase();
        if (searchQuery.isEmpty) return true;

        final name = (ngo['organizationName'] ?? ngo['ngoName'] ?? '')
            .toString()
            .toLowerCase();
        final email = (ngo['email'] ?? '').toString().toLowerCase();
        final category = (ngo['category'] ?? '').toString().toLowerCase();
        final location = (ngo['location'] ?? '').toString().toLowerCase();

        return name.contains(searchQuery) ||
            email.contains(searchQuery) ||
            category.contains(searchQuery) ||
            location.contains(searchQuery);
      }).toList();
    });
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
      appBar: DashboardNavbar(
        title: 'Welcome, ${_donorProfile?['name'] ?? 'Donor'}',
        userType: 'donor',
        onLogout: _logout,
        onRefresh: _loadDonorData,
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
              : Column(
                  children: [
                    Container(
                      color: AppTheme.primaryRed,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        isScrollable: ResponsiveHelper.isMobile(context),
                        tabAlignment: ResponsiveHelper.isMobile(context)
                            ? TabAlignment.start
                            : TabAlignment.fill,
                        tabs: [
                          Tab(
                            text: 'Dashboard',
                            icon: Icon(
                              Icons.dashboard,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 18 : 24,
                            ),
                          ),
                          Tab(
                            text: 'NGOs',
                            icon: Icon(
                              Icons.business,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 18 : 24,
                            ),
                          ),
                          Tab(
                            text: 'Donations',
                            icon: Icon(
                              Icons.favorite,
                              size:
                                  ResponsiveHelper.isMobile(context) ? 18 : 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDashboardTab(),
                          _buildNGOTab(),
                          _buildDonationsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDashboardTab() {
    final status = _donorProfile?['status'] ?? 'pending';

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
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
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

          // Show different content based on verification status
          if (status != 'approved')
            Container(
              padding: ResponsiveHelper.getResponsivePadding(context),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppTheme.textSecondary,
                    size: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 32,
                      tablet: 36,
                      desktop: 40,
                    ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 3),
                  Text(
                    'Account Verification Required',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 6),
                  Text(
                    'Quick actions will be available once your account is verified.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ResponsiveHelper.getResponsiveLayout(
              context: context,
              mobile: Column(
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.search,
                    title: 'Browse NGOs',
                    subtitle: 'Find NGOs to support',
                    color: AppTheme.primaryRed,
                    onTap: () => _tabController.animateTo(1),
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.history,
                    title: 'Donation History',
                    subtitle: 'View past donations',
                    color: AppTheme.primaryOrange,
                    onTap: () => _tabController.animateTo(2),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.search,
                      title: 'Browse NGOs',
                      subtitle: 'Find NGOs to support',
                      color: AppTheme.primaryRed,
                      onTap: () => _tabController.animateTo(1),
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.history,
                      title: 'Donation History',
                      subtitle: 'View past donations',
                      color: AppTheme.primaryOrange,
                      onTap: () => _tabController.animateTo(2),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.search,
                      title: 'Browse NGOs',
                      subtitle: 'Find NGOs to support',
                      color: AppTheme.primaryRed,
                      onTap: () => _tabController.animateTo(1),
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.history,
                      title: 'Donation History',
                      subtitle: 'View past donations',
                      color: AppTheme.primaryOrange,
                      onTap: () => _tabController.animateTo(2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNGOTab() {
    final donorStatus = _donorProfile?['status'] ?? 'pending';

    return Column(
      children: [
        // Show verification message if donor is not approved
        if (donorStatus != 'approved')
          Container(
            margin: ResponsiveHelper.getResponsivePadding(context),
            padding: ResponsiveHelper.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.warningOrange,
                  size: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 48,
                    tablet: 56,
                    desktop: 64,
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Text(
                  'Account Verification Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningOrange,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
                Text(
                  'To view and support NGOs, your account needs to be verified first. Please wait for admin approval.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Container(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.textSecondary,
                        size: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                      SizedBox(
                          width:
                              ResponsiveHelper.getResponsiveSpacing(context) /
                                  3),
                      Expanded(
                        child: Text(
                          'You will be notified via email once your account is verified.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Search Bar (only show if donor is approved)
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context),
            color: AppTheme.surfaceWhite,
            child: TextField(
              controller: _ngoSearchController,
              decoration: InputDecoration(
                hintText: 'Search NGOs...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.primaryRed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryRed),
                ),
              ),
              onChanged: (value) => _filterNGOs(),
            ),
          ),

          // NGO List
          Expanded(
            child: _filteredNGOs.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.business_center,
                    title: 'No NGOs Found',
                    message: 'No NGOs match your search criteria.',
                  )
                : ListView.builder(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    itemCount: _filteredNGOs.length,
                    itemBuilder: (context, index) {
                      final ngo = _filteredNGOs[index];
                      return _buildNGOCard(ngo);
                    },
                  ),
          ),
        ],
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
            padding: ResponsiveHelper.getResponsivePadding(context),
            itemCount: _donations.length,
            itemBuilder: (context, index) {
              final donation = _donations[index];
              return _buildDonationCard(donation);
            },
          );
  }

  Widget _buildNGOCard(Map<String, dynamic> ngo) {
    return CustomCard(
      margin: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context) / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngo['organizationName'] ?? ngo['ngoName'] ?? 'Unknown NGO',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ngo['email'] ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isMobile(context) ? 8 : 12,
                    vertical: ResponsiveHelper.isMobile(context) ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.isMobile(context) ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
            tablet: Row(
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
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ngo['email'] ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isMobile(context) ? 8 : 12,
                    vertical: ResponsiveHelper.isMobile(context) ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.isMobile(context) ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
            desktop: Row(
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
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ngo['email'] ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isMobile(context) ? 8 : 12,
                    vertical: ResponsiveHelper.isMobile(context) ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.isMobile(context) ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
          if (ngo['sectorOfWork'] != null &&
              (ngo['sectorOfWork'] as List).isNotEmpty)
            Wrap(
              children: (ngo['sectorOfWork'] as List).map((sector) {
                return Container(
                  margin: EdgeInsets.only(
                    right: ResponsiveHelper.getResponsiveSpacing(context) / 3,
                    bottom: ResponsiveHelper.getResponsiveSpacing(context) / 6,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isMobile(context) ? 6 : 8,
                    vertical: ResponsiveHelper.isMobile(context) ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sector.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                        ),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
          ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: Column(
              children: [
                CustomButton(
                  text: 'View Details',
                  onPressed: () => _showNGODetails(ngo),
                  icon: Icons.visibility,
                  isOutlined: true,
                  width: double.infinity,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 3),
                CustomButton(
                  text: 'Support',
                  onPressed: () => _showSupportDialog(ngo),
                  icon: Icons.favorite,
                  backgroundColor: AppTheme.primaryRed,
                  width: double.infinity,
                ),
              ],
            ),
            tablet: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showNGODetails(ngo),
                    icon: Icons.visibility,
                    isOutlined: true,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 3),
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
            desktop: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showNGODetails(ngo),
                    icon: Icons.visibility,
                    isOutlined: true,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 3),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    return CustomCard(
      margin: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context) / 2),
      child: ResponsiveHelper.getResponsiveLayout(
        context: context,
        mobile: Padding(
          padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveSpacing(context) / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    radius: ResponsiveHelper.isMobile(context) ? 20 : 24,
                    child: Icon(
                      Icons.favorite,
                      color: AppTheme.primaryRed,
                      size: ResponsiveHelper.isMobile(context) ? 16 : 20,
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 3),
                  Expanded(
                    child: Text(
                      donation['organizationName'] ??
                          donation['ngoName'] ??
                          'Unknown NGO',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
              Text(
                'Amount: ₹${donation['amount'] ?? '0'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 8),
              Text(
                'Date: ${donation['date'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                    ),
              ),
            ],
          ),
        ),
        tablet: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            radius: ResponsiveHelper.isMobile(context) ? 20 : 24,
            child: Icon(
              Icons.favorite,
              color: AppTheme.primaryRed,
              size: ResponsiveHelper.isMobile(context) ? 16 : 20,
            ),
          ),
          title: Text(
            donation['organizationName'] ??
                donation['ngoName'] ??
                'Unknown NGO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ₹${donation['amount'] ?? '0'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
              Text(
                'Date: ${donation['date'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                    ),
              ),
            ],
          ),
        ),
        desktop: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            radius: ResponsiveHelper.isMobile(context) ? 20 : 24,
            child: Icon(
              Icons.favorite,
              color: AppTheme.primaryRed,
              size: ResponsiveHelper.isMobile(context) ? 16 : 20,
            ),
          ),
          title: Text(
            donation['organizationName'] ??
                donation['ngoName'] ??
                'Unknown NGO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ₹${donation['amount'] ?? '0'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
              Text(
                'Date: ${donation['date'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveSpacing(context) / 2),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 28,
                  tablet: 32,
                  desktop: 36,
                ),
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 11,
                        tablet: 12,
                        desktop: 14,
                      ),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
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

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context) / 8),
      child: ResponsiveHelper.getResponsiveLayout(
        context: context,
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 16),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
          ],
        ),
        tablet: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: ResponsiveHelper.isMobile(context) ? 120 : 140,
              child: Text(
                '$label:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
            ),
          ],
        ),
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: ResponsiveHelper.isMobile(context) ? 120 : 140,
              child: Text(
                '$label:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
              ),
            ),
          ],
        ),
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
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open website: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening website: $e')),
        );
      }
    }
  }

  void _launchEmail(String email) async {
    try {
      final Uri uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open email client')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening email: $e')),
        );
      }
    }
  }

  void _launchPhone(String phone) async {
    try {
      final Uri uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening phone: $e')),
        );
      }
    }
  }

  void _showNGODetails(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ngo['organizationName'] ?? ngo['ngoName'] ?? 'NGO Details',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
          ),
        ),
        content: SizedBox(
          width: ResponsiveHelper.isMobile(context)
              ? MediaQuery.of(context).size.width * 0.9
              : ResponsiveHelper.isTablet(context)
                  ? MediaQuery.of(context).size.width * 0.7
                  : MediaQuery.of(context).size.width * 0.5,
          child: SingleChildScrollView(
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
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailField('Organization Name',
                    ngo['ngoName'] ?? ngo['organizationName'] ?? 'N/A'),
                _buildDetailField('Email', ngo['email'] ?? 'N/A'),
                _buildDetailField('Phone', ngo['phone'] ?? 'N/A'),
                _buildDetailField('Website', ngo['website'] ?? 'N/A'),
                _buildDetailField(
                    'Registration Number',
                    ngo['registrationCertNumber'] ??
                        ngo['registrationNumber'] ??
                        'N/A'),
                _buildDetailField(
                    'PAN Number', ngo['pan'] ?? ngo['panNumber'] ?? 'N/A'),
                _buildDetailField('12A Certificate',
                    ngo['cert12A'] ?? ngo['certificate12A'] ?? 'N/A'),
                _buildDetailField('80G Certificate',
                    ngo['cert80G'] ?? ngo['certificate80G'] ?? 'N/A'),

                const SizedBox(height: 16),

                // Address Information
                Text(
                  'Address Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailField('Registered Address',
                    ngo['registeredAddress'] ?? ngo['address'] ?? 'N/A'),
                _buildDetailField('Corresponding Address',
                    ngo['correspondingAddress'] ?? 'N/A'),
                _buildDetailField('District', ngo['district'] ?? 'N/A'),
                _buildDetailField('State', ngo['state'] ?? 'N/A'),
                _buildDetailField('Country', ngo['country'] ?? 'N/A'),

                const SizedBox(height: 16),

                // Work Information
                Text(
                  'Work Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailField('Category', ngo['category'] ?? 'N/A'),
                _buildDetailField('Sectors of Work',
                    (ngo['sectorOfWork'] as List?)?.join(', ') ?? 'N/A'),
                _buildDetailField('Target Beneficiaries',
                    ngo['targetBeneficiaries'] ?? 'N/A'),
                _buildDetailField(
                    'Geographic Focus', ngo['geographicFocus'] ?? 'N/A'),

                const SizedBox(height: 16),

                // Financial Information
                Text(
                  'Financial Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailField(
                    'Annual Budget', ngo['annualBudget'] ?? 'N/A'),
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailField('Chief Functionary Name',
                    ngo['chiefFunctionaryName'] ?? 'N/A'),
                _buildDetailField('Chief Functionary Email',
                    ngo['chiefFunctionaryEmail'] ?? 'N/A'),
                _buildDetailField('Chief Functionary Phone',
                    ngo['chiefFunctionaryPhone'] ?? 'N/A'),
                if (ngo['contactPersons'] != null)
                  _buildDetailField(
                      'Contact Persons',
                      (ngo['contactPersons'] as List?)
                              ?.map((cp) =>
                                  '${cp['name']} (${cp['designation']})')
                              .join(', ') ??
                          'N/A'),

                const SizedBox(height: 16),

                // Description
                if (ngo['description'] != null &&
                    ngo['description'].toString().isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
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
        ),
        actions: ResponsiveHelper.isMobile(context)
            ? [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSupportDialog(ngo);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical:
                            ResponsiveHelper.getResponsiveSpacing(context) / 3,
                      ),
                    ),
                    child: Text(
                      'Support NGO',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 3),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSupportDialog(ngo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical:
                          ResponsiveHelper.getResponsiveSpacing(context) / 3,
                    ),
                  ),
                  child: Text(
                    'Support NGO',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                    ),
                  ),
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
                      'cpfindia.org',
                      () => _launchWebsite('https://cpfindia.org/'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.email,
                      'Email',
                      'contact@cpfindia.org',
                      () => _launchEmail('contact@cpfindia.org'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.phone,
                      'Phone',
                      '+91 9871216099',
                      () => _launchPhone('+919871216099'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.location_on,
                      'Address',
                      'Plot/Site No.2, First Floor, Sector C (OFC Pocket),\nNelson Mandela Marg, Vasant Kunj, New Delhi - 110070',
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
              _launchWebsite('https://cpfindia.org/');
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
