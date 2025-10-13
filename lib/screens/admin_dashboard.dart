import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/ngo_provider.dart';
import '../providers/auth_provider.dart';
import '../util/theme.dart';
import '../util/responsive.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custome_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_navbar.dart';
import '../services/certificate_service.dart';
import '../services/donor_ngo_service.dart';
import '../services/certificate_generator.dart';
import '../providers/firestore_file_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _donorSearchController = TextEditingController();
  final TextEditingController _adminCommentsController =
      TextEditingController();

  // Filter states
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  String _selectedLocation = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  // Data states
  List<Map<String, dynamic>> _filteredNGOs = [];
  List<Map<String, dynamic>> _allDonors = [];
  List<Map<String, dynamic>> _filteredDonors = [];
  List<Map<String, dynamic>> _renewalAlerts = [];
  Map<String, dynamic> _validationStats = {};
  Map<String, int> _donorStats = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _donorSearchController.dispose();
    _adminCommentsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final ngoProvider = Provider.of<NGOProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Load validation statistics
      _validationStats = await ngoProvider.getValidationStatistics();

      // Load donor statistics
      _donorStats = await authProvider.getDonorStatistics();

      // Load renewal alerts
      _renewalAlerts = await ngoProvider.getNGOsApproachingRenewal();

      // Load filtered NGOs
      await _applyFilters();

      // Load donors
      _allDonors = await authProvider.getAllDonors();
      _filteredDonors = List.from(_allDonors);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFilters() async {
    final ngoProvider = Provider.of<NGOProvider>(context, listen: false);

    _filteredNGOs = await ngoProvider.getFilteredNGOs(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      location: _selectedLocation == 'all' ? null : _selectedLocation,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery:
          _searchController.text.isEmpty ? null : _searchController.text,
    );

    setState(() {});
  }

  void _filterDonors() {
    setState(() {
      _filteredDonors = _allDonors.where((donor) {
        final searchQuery = _donorSearchController.text.toLowerCase();
        if (searchQuery.isEmpty) return true;

        final name =
            (donor['name'] ?? donor['fullName'] ?? '').toString().toLowerCase();
        final email = (donor['email'] ?? '').toString().toLowerCase();
        final phone = (donor['phone'] ?? '').toString().toLowerCase();

        return name.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery);
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedCategory = 'all';
      _selectedLocation = 'all';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
      _donorSearchController.clear();
    });
    _applyFilters();
    _filterDonors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: DashboardNavbar(
        title: 'Admin Dashboard',
        userType: 'admin',
        onLogout: () => _logout(context),
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                Container(
                  color: AppTheme.primaryRed,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: ResponsiveHelper.isMobile(context),
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabAlignment: ResponsiveHelper.isMobile(context)
                        ? TabAlignment.start
                        : TabAlignment.center,
                    tabs: [
                      Tab(
                        text: 'Overview',
                        icon: Icon(
                          Icons.dashboard,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Validation Tracker',
                        icon: Icon(
                          Icons.assignment_turned_in,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'NGO Management',
                        icon: Icon(
                          Icons.business,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Donor Approval',
                        icon: Icon(
                          Icons.people,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Renewal Alerts',
                        icon: Icon(
                          Icons.schedule,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Analytics',
                        icon: Icon(
                          Icons.analytics,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Donor-NGO Assignment',
                        icon: Icon(
                          Icons.link,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Certificates',
                        icon: Icon(
                          Icons.verified,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      Tab(
                        text: 'Documents',
                        icon: Icon(
                          Icons.folder,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildValidationTrackerTab(),
                      _buildNGOManagementTab(),
                      _buildDonorApprovalTab(),
                      _buildRenewalAlertsTab(),
                      _buildAnalyticsTab(),
                      _buildDonorNGOAssignmentTab(),
                      _buildCertificatesTab(),
                      _buildDocumentsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: Column(
              children: [
                _buildStatCard(
                  'Total NGOs',
                  _validationStats['total']?.toString() ?? '0',
                  Icons.business,
                  Colors.blue,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildStatCard(
                  'Pending Review',
                  _validationStats['pending']?.toString() ?? '0',
                  Icons.pending,
                  Colors.orange,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildStatCard(
                  'Approved',
                  _validationStats['approved']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildStatCard(
                  'Rejected',
                  _validationStats['rejected']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            tablet: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total NGOs',
                        _validationStats['total']?.toString() ?? '0',
                        Icons.business,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: _buildStatCard(
                        'Pending Review',
                        _validationStats['pending']?.toString() ?? '0',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Approved',
                        _validationStats['approved']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: _buildStatCard(
                        'Rejected',
                        _validationStats['rejected']?.toString() ?? '0',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            desktop: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total NGOs',
                        _validationStats['total']?.toString() ?? '0',
                        Icons.business,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: _buildStatCard(
                        'Pending Review',
                        _validationStats['pending']?.toString() ?? '0',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: _buildStatCard(
                        'Approved',
                        _validationStats['approved']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: _buildStatCard(
                        'Rejected',
                        _validationStats['rejected']?.toString() ?? '0',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
          ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: Column(
              children: [
                CustomButton(
                  text: 'Review Pending NGOs',
                  onPressed: () => _tabController.animateTo(1),
                  backgroundColor: AppTheme.primaryRed,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                CustomButton(
                  text: 'Approve Donors',
                  onPressed: () => _tabController.animateTo(3),
                  backgroundColor: AppTheme.primaryOrange,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                CustomButton(
                  text: 'Check Renewals',
                  onPressed: () => _tabController.animateTo(4),
                  backgroundColor: AppTheme.accentGold,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                CustomButton(
                  text: 'View Analytics',
                  onPressed: () => _tabController.animateTo(5),
                  backgroundColor: Colors.purple,
                ),
              ],
            ),
            tablet: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Review Pending NGOs',
                        onPressed: () => _tabController.animateTo(1),
                        backgroundColor: AppTheme.primaryRed,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: CustomButton(
                        text: 'Approve Donors',
                        onPressed: () => _tabController.animateTo(3),
                        backgroundColor: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Check Renewals',
                        onPressed: () => _tabController.animateTo(4),
                        backgroundColor: AppTheme.accentGold,
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) / 2),
                    Expanded(
                      child: CustomButton(
                        text: 'View Analytics',
                        onPressed: () => _tabController.animateTo(5),
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            desktop: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Review Pending NGOs',
                    onPressed: () => _tabController.animateTo(1),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: CustomButton(
                    text: 'Approve Donors',
                    onPressed: () => _tabController.animateTo(3),
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: CustomButton(
                    text: 'Check Renewals',
                    onPressed: () => _tabController.animateTo(4),
                    backgroundColor: AppTheme.accentGold,
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: CustomButton(
                    text: 'View Analytics',
                    onPressed: () => _tabController.animateTo(5),
                    backgroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationTrackerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Validation Statistics
          Text(
            'Validation Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildValidationStatsGrid(),
          const SizedBox(height: 24),

          // Recent Validations
          Text(
            'Recent Validations',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildValidationList(),
        ],
      ),
    );
  }

  Widget _buildNGOManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          _buildFiltersSection(),
          const SizedBox(height: 16),

          // NGO List
          Text(
            'NGO Applications (${_filteredNGOs.length})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildNGOList(),
        ],
      ),
    );
  }

  Widget _buildDonorApprovalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donor Statistics
          Text(
            'Donor Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildDonorStatsGrid(),
          const SizedBox(height: 24),

          // Donor List
          Text(
            'Donor Applications (${_filteredDonors.length})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Search Field
          CustomTextField(
            controller: _donorSearchController,
            label: '',
            hint: 'Search Donors...',
            icon: Icons.search,
            onChanged: (value) => _filterDonors(),
          ),
          const SizedBox(height: 16),

          _buildDonorList(),
        ],
      ),
    );
  }

  Widget _buildRenewalAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Renewal Alerts (${_renewalAlerts.length})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (_renewalAlerts.isEmpty)
            const Center(
              child: Text('No NGOs approaching renewal'),
            )
          else
            _buildRenewalList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
          _buildAnalyticsCharts(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
          top: ResponsiveHelper.getResponsiveSpacing(context) / 2,
          bottom: ResponsiveHelper.getResponsiveSpacing(context) / 2,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 28,
                tablet: 32,
                desktop: 36,
              ),
              color: color,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Under Review',
          _validationStats['underReview']?.toString() ?? '0',
          Icons.assignment,
          Colors.blue,
        ),
        _buildStatCard(
          'Needs Follow-up',
          _validationStats['needsFollowUp']?.toString() ?? '0',
          Icons.follow_the_signs,
          Colors.orange,
        ),
        _buildStatCard(
          'Approval Rate',
          '${_validationStats['approvalRate'] ?? '0.0'}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Total Processed',
          _validationStats['total']?.toString() ?? '0',
          Icons.assignment_turned_in,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildValidationList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredNGOs.length,
      itemBuilder: (context, index) {
        final ngo = _filteredNGOs[index];
        return _buildNGOItem(ngo, showFollowUp: true);
      },
    );
  }

  Widget _buildFiltersSection() {
    return CustomCard(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(
                    Icons.clear_all,
                    size: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),
                  label: Text(
                    'Clear All',
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
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

            // Search
            CustomTextField(
              controller: _searchController,
              label: '',
              hint: 'Search NGOs...',
              icon: Icons.search,
              onChanged: (value) => _applyFilters(),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

            // Filter dropdowns
            ResponsiveHelper.getResponsiveLayout(
              context: context,
              mobile: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'under_review', child: Text('Under Review')),
                      DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                      _applyFilters();
                    },
                  ),
                  SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All Categories')),
                      DropdownMenuItem(
                          value: 'education', child: Text('Education')),
                      DropdownMenuItem(value: 'health', child: Text('Health')),
                      DropdownMenuItem(
                          value: 'environment', child: Text('Environment')),
                      DropdownMenuItem(
                          value: 'social', child: Text('Social Welfare')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                      _applyFilters();
                    },
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Status')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'under_review', child: Text('Under Review')),
                        DropdownMenuItem(
                            value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(
                            value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Categories')),
                        DropdownMenuItem(
                            value: 'education', child: Text('Education')),
                        DropdownMenuItem(
                            value: 'health', child: Text('Health')),
                        DropdownMenuItem(
                            value: 'environment', child: Text('Environment')),
                        DropdownMenuItem(
                            value: 'social', child: Text('Social Welfare')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Status')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'under_review', child: Text('Under Review')),
                        DropdownMenuItem(
                            value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(
                            value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Categories')),
                        DropdownMenuItem(
                            value: 'education', child: Text('Education')),
                        DropdownMenuItem(
                            value: 'health', child: Text('Health')),
                        DropdownMenuItem(
                            value: 'environment', child: Text('Environment')),
                        DropdownMenuItem(
                            value: 'social', child: Text('Social Welfare')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

            // Date filters
            ResponsiveHelper.getResponsiveLayout(
              context: context,
              mobile: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                        _applyFilters();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select date',
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
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                        _applyFilters();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          size: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select date',
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
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                          _applyFilters();
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            size: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select date',
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
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                          _applyFilters();
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            size: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select date',
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
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                          _applyFilters();
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            size: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select date',
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
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                          _applyFilters();
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            size: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select date',
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNGOList() {
    if (_filteredNGOs.isEmpty) {
      return const Center(
        child: Text('No NGOs found'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredNGOs.length,
      itemBuilder: (context, index) {
        final ngo = _filteredNGOs[index];
        return _buildNGOItem(ngo);
      },
    );
  }

  Widget _buildNGOItem(Map<String, dynamic> ngo, {bool showFollowUp = false}) {
    final status = ngo['status'] as String? ?? 'pending';
    final followUpStatus = ngo['followUpStatus'] as String? ?? '';
    final organizationName =
        ngo['organizationName'] ?? ngo['ngoName'] ?? 'Unknown NGO';
    final email = ngo['email'] ?? 'No email provided';
    final category = ngo['category'] ?? 'N/A';
    final location = ngo['location'] ?? ngo['city'] ?? 'N/A';
    final phone = ngo['phone'] ?? 'N/A';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'under_review':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        organizationName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(Icons.category, 'Category', category),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _buildInfoChip(Icons.location_on, 'Location', location),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(Icons.phone, 'Phone', phone),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                      Icons.calendar_today,
                      'Applied',
                      ngo['createdAt'] != null
                          ? (ngo['createdAt'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')[0]
                          : 'N/A'),
                ),
              ],
            ),
            if (showFollowUp && followUpStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: followUpStatus == 'needs_follow_up'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Follow-up: ${followUpStatus.replaceAll('_', ' ').toUpperCase()}',
                  style: TextStyle(
                    color: followUpStatus == 'needs_follow_up'
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showNGODetails(ngo),
                    backgroundColor: AppTheme.primaryRed,
                    icon: Icons.visibility,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending' || status == 'under_review') ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _showApprovalDialog(ngo, 'approved'),
                      backgroundColor: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () => _showApprovalDialog(ngo, 'rejected'),
                      backgroundColor: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Review',
                      onPressed: () => _showReviewDialog(ngo),
                      backgroundColor: AppTheme.primaryOrange,
                      icon: Icons.edit,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Donors',
          _donorStats['total']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending',
          _donorStats['pending']?.toString() ?? '0',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Approved',
          _donorStats['approved']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Rejected',
          _donorStats['rejected']?.toString() ?? '0',
          Icons.cancel,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildDonorList() {
    if (_filteredDonors.isEmpty) {
      return const Center(
        child: Text('No donors found'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredDonors.length,
      itemBuilder: (context, index) {
        final donor = _filteredDonors[index];
        return _buildDonorItem(donor);
      },
    );
  }

  Widget _buildDonorItem(Map<String, dynamic> donor) {
    final status = donor['status'] as String? ?? 'pending';
    final name = donor['name'] ?? donor['fullName'] ?? 'Unknown Donor';
    final email = donor['email'] ?? 'No email provided';
    final phone = donor['phone'] ?? 'N/A';
    final location = donor['location'] ?? donor['city'] ?? 'N/A';
    final occupation = donor['occupation'] ?? 'N/A';
    final collection = donor['collection'] ?? 'donors';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'under_review':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(Icons.phone, 'Phone', phone),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _buildInfoChip(Icons.location_on, 'Location', location),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(Icons.work, 'Occupation', occupation),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                      Icons.calendar_today,
                      'Applied',
                      donor['createdAt'] != null
                          ? (donor['createdAt'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')[0]
                          : 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: collection == 'donor_profiles'
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: collection == 'donor_profiles'
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
              child: Text(
                'Source: ${collection == 'donor_profiles' ? 'Donor Profiles' : 'Donors'}',
                style: TextStyle(
                  color: collection == 'donor_profiles'
                      ? Colors.blue
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showDonorDetails(donor),
                    backgroundColor: AppTheme.primaryRed,
                    icon: Icons.visibility,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending' || status == 'under_review') ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () =>
                          _showDonorApprovalDialog(donor, 'approved'),
                      backgroundColor: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () =>
                          _showDonorApprovalDialog(donor, 'rejected'),
                      backgroundColor: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Review',
                      onPressed: () => _showDonorReviewDialog(donor),
                      backgroundColor: AppTheme.primaryOrange,
                      icon: Icons.edit,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _renewalAlerts.length,
      itemBuilder: (context, index) {
        final ngo = _renewalAlerts[index];
        return _buildRenewalItem(ngo);
      },
    );
  }

  Widget _buildRenewalItem(Map<String, dynamic> ngo) {
    final approvedAt = ngo['approvedAt'] as Timestamp?;
    final daysUntilRenewal = approvedAt != null
        ? DateTime.now().difference(approvedAt.toDate()).inDays
        : 0;
    final daysRemaining = 365 - daysUntilRenewal;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ngo['organizationName'] ?? 'Unknown NGO',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysRemaining < 30
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: daysRemaining < 30 ? Colors.red : Colors.orange,
                    ),
                  ),
                  child: Text(
                    '$daysRemaining days left',
                    style: TextStyle(
                      color: daysRemaining < 30 ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ngo['email'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Approved: ${approvedAt?.toDate().toString().split(' ')[0] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Send Reminder',
                    onPressed: () => _sendRenewalReminder(ngo),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showNGODetails(ngo),
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCharts() {
    return Column(
      children: [
        // Key Metrics Overview
        ResponsiveHelper.getResponsiveLayout(
          context: context,
          mobile: Column(
            children: [
              _buildAnalyticsStatCard(
                'Total NGOs',
                _validationStats['total']?.toString() ?? '0',
                Icons.business,
                Colors.blue,
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              _buildAnalyticsStatCard(
                'Pending Review',
                _validationStats['pending']?.toString() ?? '0',
                Icons.pending,
                Colors.orange,
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              _buildAnalyticsStatCard(
                'Approved NGOs',
                _validationStats['approved']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              _buildAnalyticsStatCard(
                'Rejected NGOs',
                _validationStats['rejected']?.toString() ?? '0',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          tablet: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsStatCard(
                      'Total NGOs',
                      _validationStats['total']?.toString() ?? '0',
                      Icons.business,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: _buildAnalyticsStatCard(
                      'Pending Review',
                      _validationStats['pending']?.toString() ?? '0',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsStatCard(
                      'Approved NGOs',
                      _validationStats['approved']?.toString() ?? '0',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  SizedBox(
                      width:
                          ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Expanded(
                    child: _buildAnalyticsStatCard(
                      'Rejected NGOs',
                      _validationStats['rejected']?.toString() ?? '0',
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(
                child: _buildAnalyticsStatCard(
                  'Total NGOs',
                  _validationStats['total']?.toString() ?? '0',
                  Icons.business,
                  Colors.blue,
                ),
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              Expanded(
                child: _buildAnalyticsStatCard(
                  'Pending Review',
                  _validationStats['pending']?.toString() ?? '0',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              Expanded(
                child: _buildAnalyticsStatCard(
                  'Approved NGOs',
                  _validationStats['approved']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
              Expanded(
                child: _buildAnalyticsStatCard(
                  'Rejected NGOs',
                  _validationStats['rejected']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

        // NGO Status Distribution Chart
        CustomCard(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NGO Status Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildStatusChart(),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

        // Monthly Applications Chart
        CustomCard(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Applications Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildMonthlyChart(),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

        // Category Distribution
        CustomCard(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NGO Category Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                _buildCategoryChart(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChart() {
    final total = _validationStats['total'] as int? ?? 1;
    final pending = _validationStats['pending'] as int? ?? 0;
    final approved = _validationStats['approved'] as int? ?? 0;
    final rejected = _validationStats['rejected'] as int? ?? 0;

    return Column(
      children: [
        _buildChartBar('Pending', pending, total, Colors.orange),
        const SizedBox(height: 8),
        _buildChartBar('Approved', approved, total, Colors.green),
        const SizedBox(height: 8),
        _buildChartBar('Rejected', rejected, total, Colors.red),
      ],
    );
  }

  Widget _buildChartBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: ResponsiveHelper.isMobile(context) ? 60 : 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          child: Container(
            height: ResponsiveHelper.isMobile(context) ? 16 : 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 4),
        Text(
          '$value (${(percentage * 100).toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsStatCard(
      String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
          top: ResponsiveHelper.getResponsiveSpacing(context) / 2,
          bottom: ResponsiveHelper.getResponsiveSpacing(context) / 2,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
              color: color,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context) / 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    // This would typically fetch category data from Firestore
    // For now, showing a placeholder with sample data
    final categories = {
      'Education': 25,
      'Health': 20,
      'Environment': 15,
      'Social Welfare': 30,
      'Other': 10,
    };

    final total = categories.values.reduce((a, b) => a + b);

    return Column(
      children: categories.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total) : 0.0;
        final color = _getCategoryColor(entry.key);

        return Padding(
          padding: EdgeInsets.only(
              bottom: ResponsiveHelper.getResponsiveSpacing(context) / 4),
          child: Row(
            children: [
              SizedBox(
                width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                child: Container(
                  height: ResponsiveHelper.isMobile(context) ? 16 : 20,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context) / 4),
              Text(
                '${entry.value} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'environment':
        return Colors.teal;
      case 'social welfare':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMonthlyChart() {
    // This would typically fetch monthly data from Firestore
    // For now, showing a placeholder
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('Monthly chart would be implemented here'),
      ),
    );
  }

  void _showNGODetails(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ngo['organizationName'] ??
                          ngo['ngoName'] ??
                          'NGO Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildDetailsSection(
                        'Basic Information',
                        Icons.info,
                        [
                          _buildDetailRow(
                              'Organization Name', ngo['ngoName'] ?? 'N/A'),
                          _buildDetailRow('Email', ngo['email'] ?? 'N/A'),
                          _buildDetailRow('Phone', ngo['phone'] ?? 'N/A'),
                          _buildDetailRow('Website', ngo['website'] ?? 'N/A'),
                          _buildDetailRow('Sector of Work',
                              ngo['sectorOfWork']?.join(', ') ?? 'N/A'),
                          _buildDetailRow(
                              'Other Sectors', ngo['otherSectors'] ?? 'N/A'),
                          _buildDetailRow(
                              'Legal Status', ngo['legalStatus'] ?? 'N/A'),
                          _buildDetailRow('District', ngo['district'] ?? 'N/A'),
                          _buildDetailRow('State', ngo['state'] ?? 'N/A'),
                          _buildDetailRow('Country', ngo['country'] ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact Information Section
                      _buildDetailsSection(
                        'Contact Information',
                        Icons.contact_phone,
                        [
                          _buildDetailRow('Chief Functionary Name',
                              ngo['chiefFunctionaryName'] ?? 'N/A'),
                          _buildDetailRow('Chief Functionary Email',
                              ngo['chiefFunctionaryEmail'] ?? 'N/A'),
                          _buildDetailRow('Chief Functionary Phone',
                              ngo['chiefFunctionaryPhone'] ?? 'N/A'),
                          _buildDetailRow('Contact Persons',
                              _formatContactPersons(ngo['contactPersons'])),
                          _buildDetailRow('Networks', ngo['networks'] ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Legal Information Section
                      _buildDetailsSection(
                        'Legal Information',
                        Icons.gavel,
                        [
                          _buildDetailRow('Date of Registration',
                              ngo['dateOfRegistration'] ?? 'N/A'),
                          _buildDetailRow('Registration Certificate Number',
                              ngo['registrationCertNumber'] ?? 'N/A'),
                          _buildDetailRow('PAN Number', ngo['pan'] ?? 'N/A'),
                          _buildDetailRow('TAN Number', ngo['tan'] ?? 'N/A'),
                          _buildDetailRow('GST Registration',
                              ngo['gstRegistration'] ?? 'N/A'),
                          _buildDetailRow('FCRA Registration',
                              ngo['fcraRegistration'] ?? 'N/A'),
                          _buildDetailRow('CSR Registration',
                              ngo['csrRegistration'] ?? 'N/A'),
                          _buildDetailRow(
                              'DARPAN ID', ngo['darpanId'] ?? 'N/A'),
                          _buildDetailRow('Professional Tax Registration',
                              ngo['professionalTaxRegistration'] ?? 'N/A'),
                          _buildDetailRow(
                              '12A Certificate', ngo['cert12A'] ?? 'N/A'),
                          _buildDetailRow(
                              '80G Certificate', ngo['cert80G'] ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Financial Information Section
                      _buildDetailsSection(
                        'Financial Information',
                        Icons.account_balance,
                        [
                          _buildDetailRow(
                              'Financial Year', ngo['financialYear'] ?? 'N/A'),
                          _buildDetailRow('Gross Amount Raised',
                              ngo['grossAmountRaised']?.toString() ?? 'N/A'),
                          _buildDetailRow('Registered Address',
                              ngo['registeredAddress'] ?? 'N/A'),
                          _buildDetailRow('Corresponding Address',
                              ngo['correspondingAddress'] ?? 'N/A'),
                          _buildDetailRow('Social Media Presence',
                              ngo['socialMediaPresence']?.toString() ?? 'N/A'),
                          _buildDetailRow('Social Media URLs',
                              _formatSocialMediaUrls(ngo['socialMediaUrls'])),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Status and Timeline Section
                      _buildDetailsSection(
                        'Status & Timeline',
                        Icons.timeline,
                        [
                          _buildDetailRow(
                              'Current Status', ngo['status'] ?? 'N/A'),
                          _buildDetailRow('Registration Status',
                              ngo['registrationStatus'] ?? 'N/A'),
                          _buildDetailRow('Verification Status',
                              ngo['verificationStatus'] ?? 'N/A'),
                          _buildDetailRow('Profile Complete',
                              ngo['profileComplete']?.toString() ?? 'N/A'),
                          _buildDetailRow(
                              'Created At', _formatDate(ngo['createdAt'])),
                          _buildDetailRow(
                              'Updated At', _formatDate(ngo['updatedAt'])),
                          _buildDetailRow(
                              'Last Login', _formatDate(ngo['lastLogin'])),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      if (ngo['description'] != null)
                        _buildDetailsSection(
                          'Description',
                          Icons.description,
                          [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                ngo['description'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Documents Section
                      _buildDocumentsSection(ngo),

                      const SizedBox(height: 24),

                      // Certificates Section
                      _buildCertificatesSection(ngo),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donor['name'] ?? 'Donor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', donor['email'] ?? 'N/A'),
              _buildDetailRow('Phone', donor['phone'] ?? 'N/A'),
              _buildDetailRow('Status', donor['status'] ?? 'N/A'),
              _buildDetailRow(
                  'Created',
                  donor['createdAt'] != null
                      ? (donor['createdAt'] as Timestamp)
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
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
              child:
                  Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic> ngo) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Uploaded Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDocumentsList(ngo),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(Map<String, dynamic> ngo) {
    // Get all document fields from the NGO data
    final documentFields = [
      'registrationCertificate',
      'panCard',
      'tanCard',
      'gstCertificate',
      'fcraCertificate',
      'certificate12A',
      'certificate80G',
      'auditReport',
      'annualReport',
      'utilizationCertificate',
      'logo',
      'proposalDocument',
    ];

    final documents = <Map<String, dynamic>>[];

    for (final field in documentFields) {
      if (ngo[field] != null) {
        if (ngo[field] is Map<String, dynamic>) {
          // If it's a metadata object
          documents.add({
            'name': _getDocumentDisplayName(field),
            'type': field,
            'metadata': ngo[field],
          });
        } else if (ngo[field] is String) {
          // If it's a simple string URL
          documents.add({
            'name': _getDocumentDisplayName(field),
            'type': field,
            'url': ngo[field],
          });
        }
      }
    }

    if (documents.isEmpty) {
      return const Center(
        child: Text('No documents uploaded'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _buildDocumentItem(doc);
      },
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final metadata = doc['metadata'] as Map<String, dynamic>?;
    final url = doc['url'] as String?;
    final downloadUrl = metadata?['download_url'] ?? url;
    final fileName = metadata?['original_name'] ?? doc['name'];
    final fileSize = metadata?['file_size'] ?? 0;
    final uploadedAt = metadata?['uploaded_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(
          doc['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileName != doc['name']) Text('File: $fileName'),
            if (fileSize > 0) Text('Size: ${_formatFileSize(fileSize)}'),
            if (uploadedAt != null)
              Text('Uploaded: ${_formatDate(DateTime.parse(uploadedAt))}'),
          ],
        ),
        trailing: downloadUrl != null
            ? IconButton(
                icon: const Icon(Icons.download),
                onPressed: () =>
                    _downloadDocument({'name': fileName, 'url': downloadUrl}),
              )
            : const Icon(Icons.error, color: Colors.red),
      ),
    );
  }

  Widget _buildCertificatesSection(Map<String, dynamic> ngo) {
    final status = ngo['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Generate Certificates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: status == 'approved' || status == 'verified'
                ? _buildCertificatesList(ngo)
                : const Center(
                    child: Text('Certificates can be generated after approval'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesList(Map<String, dynamic> ngo) {
    final ngoName = ngo['ngoName'] ?? 'NGO Name';
    final ngoAddress = ngo['registeredAddress'] ??
        ngo['correspondingAddress'] ??
        'Address not provided';
    final cfoName = ngo['chiefFunctionaryName'] ?? 'Chief Functionary Name';
    final logoPath = ngo['logo']?['download_url'] ?? 'images/CPF_Logo.jpg';

    return Column(
      children: [
        _buildCertificateItem(
          'Due Diligence Certificate',
          'Official due diligence verification certificate',
          Icons.assignment_turned_in,
          Colors.red,
          () => _generateCertificate(
              'due_diligence', ngoName, ngoAddress, cfoName, logoPath),
        ),
        const SizedBox(height: 8),
        _buildCertificateItem(
          'Compliance Certificate',
          'Certificate of regulatory compliance',
          Icons.verified,
          Colors.green,
          () => _generateCertificate(
              'compliance', ngoName, ngoAddress, cfoName, logoPath),
        ),
        const SizedBox(height: 8),
        _buildCertificateItem(
          'Letterhead Certificate',
          'Official letterhead authorization certificate',
          Icons.description,
          Colors.blue,
          () => _generateCertificate(
              'letterhead', ngoName, ngoAddress, cfoName, logoPath),
        ),
      ],
    );
  }

  Widget _buildCertificateItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onGenerate,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.add_circle, size: 18),
                label: const Text('Generate Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentDisplayName(String field) {
    switch (field) {
      case 'registrationCertificate':
        return 'Registration Certificate';
      case 'panCard':
        return 'PAN Card';
      case 'tanCard':
        return 'TAN Card';
      case 'gstCertificate':
        return 'GST Certificate';
      case 'fcraCertificate':
        return 'FCRA Certificate';
      case 'certificate12A':
        return '12A Certificate';
      case 'certificate80G':
        return '80G Certificate';
      case 'auditReport':
        return 'Audit Report';
      case 'annualReport':
        return 'Annual Report';
      case 'utilizationCertificate':
        return 'Utilization Certificate';
      case 'logo':
        return 'Organization Logo';
      case 'proposalDocument':
        return 'Proposal Document';
      default:
        return field.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _generateCertificate(String type, String ngoName, String ngoAddress,
      String cfoName, String logoPath) async {
    try {
      print('Starting certificate generation: $type');
      print(
          'Parameters: NGO=$ngoName, Address=$ngoAddress, CFO=$cfoName, Logo=$logoPath');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating certificate...'),
            ],
          ),
        ),
      );

      final now = DateTime.now();
      final issueDate = now.subtract(const Duration(days: 30));
      final expiryDate = now.add(const Duration(days: 335));
      final certificateId =
          '${type.toUpperCase()}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      // Generate certificate based on type
      switch (type) {
        case 'due_diligence':
          await CertificateGenerator.generateDueDiligenceCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        case 'compliance':
          await CertificateGenerator.generateComplianceCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        case 'letterhead':
          await CertificateGenerator.generateLetterheadCertificate(
            ngoName: ngoName,
            ngoAddress: ngoAddress,
            cfoName: cfoName,
            logoPath: logoPath,
            certificateId: certificateId,
            issueDate: issueDate,
            expiryDate: expiryDate,
            context: context,
          );
          break;
        default:
          throw Exception('Unknown certificate type: $type');
      }

      print('Certificate generation completed successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error generating certificate: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating certificate: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showReviewDialog(Map<String, dynamic> ngo) {
    _adminCommentsController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review ${ngo['organizationName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${ngo['status']}'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _adminCommentsController,
              label: '',
              hint: 'Admin comments (optional)',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _updateNGOStatus(ngo, 'under_review'),
            child: const Text('Under Review'),
          ),
          TextButton(
            onPressed: () => _updateNGOStatus(ngo, 'approved'),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () => _updateNGOStatus(ngo, 'rejected'),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNGOStatus(Map<String, dynamic> ngo, String status) async {
    final ngoProvider = Provider.of<NGOProvider>(context, listen: false);

    final success = await ngoProvider.updateNGOStatus(
      ngoId: ngo['id'],
      status: status,
      adminComments: _adminCommentsController.text,
    );

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NGO status updated to $status')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update NGO status')),
      );
    }
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(Map<String, dynamic> ngo, String status) {
    final TextEditingController commentsController = TextEditingController();
    final bool isApproval = status == 'approved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproval ? 'Approve NGO' : 'Reject NGO'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'NGO: ${ngo['organizationName'] ?? ngo['ngoName'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: isApproval
                    ? 'Approval Comments (Optional)'
                    : 'Rejection Reason',
                hintText: isApproval
                    ? 'Add any comments about this approval...'
                    : 'Please provide a reason for rejection...',
                border: const OutlineInputBorder(),
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
              Navigator.pop(context);
              await _updateNGOStatusNew(ngo, status, commentsController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNGOStatusNew(
      Map<String, dynamic> ngo, String status, String comments) async {
    final ngoProvider = Provider.of<NGOProvider>(context, listen: false);
    final success = await ngoProvider.updateNGOStatus(
      ngoId: ngo['id'],
      status: status,
      adminComments: comments.isNotEmpty ? comments : null,
    );

    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NGO ${status} successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${status} NGO')),
      );
    }
  }

  void _showDonorApprovalDialog(Map<String, dynamic> donor, String status) {
    final TextEditingController commentsController = TextEditingController();
    final bool isApproval = status == 'approved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproval ? 'Approve Donor' : 'Reject Donor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donor: ${donor['name'] ?? donor['fullName'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: isApproval
                    ? 'Approval Comments (Optional)'
                    : 'Rejection Reason',
                hintText: isApproval
                    ? 'Add any comments about this approval...'
                    : 'Please provide a reason for rejection...',
                border: const OutlineInputBorder(),
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
              Navigator.pop(context);
              await _updateDonorStatusNew(
                  donor, status, commentsController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDonorStatusNew(
      Map<String, dynamic> donor, String status, String comments) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateDonorStatus(
      donorId: donor['id'],
      status: status,
      adminComments: comments.isNotEmpty ? comments : null,
      collection: donor['collection'], // Pass the collection info
    );

    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donor ${status} successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${status} donor')),
      );
    }
  }

  void _showDonorReviewDialog(Map<String, dynamic> donor) {
    final TextEditingController commentsController = TextEditingController();
    String selectedStatus = donor['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Donor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donor: ${donor['name'] ?? donor['fullName'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'under_review', child: Text('Under Review')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments',
                hintText: 'Add any comments about this donor...',
                border: OutlineInputBorder(),
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
              Navigator.pop(context);
              await _updateDonorStatusNew(
                  donor, selectedStatus, commentsController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _sendRenewalReminder(Map<String, dynamic> ngo) {
    // This would typically send an email or notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Renewal reminder sent to ${ngo['organizationName']}')),
    );
  }

  Widget _buildDonorNGOAssignmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donor-NGO Assignment Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 20),

          // Assignment Statistics
          _buildAssignmentStats(),
          const SizedBox(height: 20),

          // Assignment List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Assignments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateAssignmentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignmentList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentStats() {
    return FutureBuilder<Map<String, int>>(
      future: DonorNGOService.getAssignmentStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final stats = snapshot.data ?? {};
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Donors',
                stats['totalDonors']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total NGOs',
                stats['totalNGOs']?.toString() ?? '0',
                Icons.business,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Assigned Donors',
                stats['assignedDonors']?.toString() ?? '0',
                Icons.link,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Assignments',
                stats['totalAssignments']?.toString() ?? '0',
                Icons.assignment,
                Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DonorNGOService.getAllAssignments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No assignments found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by assigning NGOs to donors',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _buildAssignmentCard(assignment);
          },
        );
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Donor ID: ${assignment['donorId']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleAssignmentAction(value, assignment),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: AppTheme.primaryRed),
                        title: Text('Edit Assignment'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Remove Assignment'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Assigned NGOs: ${(assignment['assignedNGOs'] as List).length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assigned: ${_formatDate(assignment['assignedAt'])}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NGO Certificate Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 20),

          // Certificate Types
          Row(
            children: [
              Expanded(
                child: _buildCertificateTypeCard(
                  'Registration Certificate',
                  'Generate registration certificate for approved NGOs',
                  Icons.assignment_turned_in,
                  Colors.blue,
                  () => _showCertificateDialog('registration'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCertificateTypeCard(
                  'Compliance Certificate',
                  'Generate compliance certificate for verified NGOs',
                  Icons.verified,
                  Colors.green,
                  () => _showCertificateDialog('compliance'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCertificateTypeCard(
                  'Due Diligence Certificate',
                  'Generate due diligence certificate for verified NGOs',
                  Icons.search,
                  Colors.orange,
                  () => _showCertificateDialog('due_diligence'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCertificateTypeCard(
                  'Bulk Certificates',
                  'Generate certificates for multiple NGOs',
                  Icons.batch_prediction,
                  Colors.purple,
                  () => _showBulkCertificateDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTypeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _handleAssignmentAction(String action, Map<String, dynamic> assignment) {
    switch (action) {
      case 'edit':
        _showEditAssignmentDialog(assignment);
        break;
      case 'remove':
        _showRemoveAssignmentDialog(assignment);
        break;
    }
  }

  void _showEditAssignmentDialog(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => _AssignmentDialog(
        assignment: assignment,
        onSave: (selectedNGOs) async {
          final success = await DonorNGOService.updateNGOAssignment(
            donorId: assignment['donorId'],
            ngoIds: selectedNGOs,
            adminId: 'admin', // You can get this from auth provider
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assignment updated successfully')),
            );
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update assignment')),
            );
          }
        },
      ),
    );
  }

  void _showRemoveAssignmentDialog(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: Text(
            'Are you sure you want to remove the NGO assignment for donor ${assignment['donorId']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await DonorNGOService.removeNGOAssignment(
                  assignment['donorId']);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Assignment removed successfully')),
                );
                setState(() {});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove assignment')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showCertificateDialog(String certificateType) {
    // Show NGO selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Select NGO for ${certificateType.replaceAll('_', ' ').toUpperCase()} Certificate'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadApprovedNGOs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final ngos = snapshot.data ?? [];
              if (ngos.isEmpty) {
                return const Center(
                  child: Text('No approved NGOs found'),
                );
              }

              return ListView.builder(
                itemCount: ngos.length,
                itemBuilder: (context, index) {
                  final ngo = ngos[index];
                  return ListTile(
                    title: Text(ngo['organizationName'] ?? 'Unknown NGO'),
                    subtitle: Text(ngo['email'] ?? 'No email'),
                    onTap: () {
                      Navigator.pop(context);
                      CertificateService.showCertificateDialog(
                        context: context,
                        certificateType: certificateType,
                        ngoName: ngo['organizationName'] ?? 'Unknown NGO',
                        ngoId: ngo['id'] ?? '',
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadApprovedNGOs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _showBulkCertificateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Certificate Generation'),
        content:
            const Text('Bulk certificate generation functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAssignmentDialog(
        onSave: (donorId, selectedNGOs) async {
          final success = await DonorNGOService.assignNGOsToDonor(
            donorId: donorId,
            ngoIds: selectedNGOs,
            adminId: 'admin', // You can get this from auth provider
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assignment created successfully')),
            );
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create assignment')),
            );
          }
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Tracking',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track all uploaded documents by NGOs with Supabase storage integration',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          _buildDocumentStats(),
          const SizedBox(height: 24),
          _buildDocumentList(),
        ],
      ),
    );
  }

  Widget _buildDocumentStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDocumentStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final stats = snapshot.data ?? {};
        final totalDocuments = stats['totalDocuments'] ?? 0;
        final totalSize = stats['totalSize'] ?? 0;
        final ngosWithDocuments = stats['ngosWithDocuments'] ?? 0;

        return ResponsiveHelper.getResponsiveLayout(
          context: context,
          mobile: Column(
            children: [
              _buildStatCard('Total Documents', totalDocuments.toString(),
                  Icons.description, Colors.blue),
              const SizedBox(height: 12),
              _buildStatCard(
                  'Total Size',
                  FirestoreFileService.formatFileSize(totalSize),
                  Icons.storage,
                  Colors.green),
              const SizedBox(height: 12),
              _buildStatCard('NGOs with Documents',
                  ngosWithDocuments.toString(), Icons.business, Colors.orange),
            ],
          ),
          tablet: Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Total Documents',
                      totalDocuments.toString(),
                      Icons.description,
                      Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Total Size',
                      FirestoreFileService.formatFileSize(totalSize),
                      Icons.storage,
                      Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'NGOs with Documents',
                      ngosWithDocuments.toString(),
                      Icons.business,
                      Colors.orange)),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Total Documents',
                      totalDocuments.toString(),
                      Icons.description,
                      Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Total Size',
                      FirestoreFileService.formatFileSize(totalSize),
                      Icons.storage,
                      Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'NGOs with Documents',
                      ngosWithDocuments.toString(),
                      Icons.business,
                      Colors.orange)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllUploadedDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return const Center(
            child: Text('No documents uploaded yet'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return _buildDocumentCard(doc);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
          child: Icon(
            _getDocumentIcon(doc['documentType']),
            color: AppTheme.primaryRed,
          ),
        ),
        title: Text(
          doc['originalName'] ?? 'Unknown file',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NGO: ${doc['ngoId']}'),
            Text('Type: ${doc['documentType']}'),
            Text(
                'Size: ${FirestoreFileService.formatFileSize(doc['fileSize'] ?? 0)}'),
            Text('Uploaded: ${_formatDate(doc['uploadedAt'])}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'download':
                _downloadDocument(doc);
                break;
              case 'view':
                _viewDocument(doc);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'pan_doc':
        return Icons.credit_card;
      case 'itr':
        return Icons.receipt;
      case 'audit':
        return Icons.assessment;
      case 'proposal':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _downloadDocument(dynamic doc) {
    // Implement document download
    String fileName = 'document';
    if (doc is Map<String, dynamic>) {
      fileName = doc['originalName'] ?? doc['name'] ?? 'document';
    } else if (doc is String) {
      fileName = doc;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $fileName...')),
    );
  }

  void _viewDocument(Map<String, dynamic> doc) {
    // Implement document view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${doc['originalName']}...')),
    );
  }

  Future<Map<String, dynamic>> _getDocumentStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('ngo_proposals').get();

      int totalDocuments = 0;
      int totalSize = 0;
      int ngosWithDocuments = 0;

      for (final doc in snapshot.docs) {
        final ngoId = doc.id;
        final documentsSnapshot = await firestore
            .collection('ngo_proposals')
            .doc(ngoId)
            .collection('uploaded_documents')
            .get();

        if (documentsSnapshot.docs.isNotEmpty) {
          ngosWithDocuments++;
          totalDocuments += documentsSnapshot.docs.length;

          for (final docData in documentsSnapshot.docs) {
            totalSize += (docData.data()['fileSize'] ?? 0) as int;
          }
        }
      }

      return {
        'totalDocuments': totalDocuments,
        'totalSize': totalSize,
        'ngosWithDocuments': ngosWithDocuments,
      };
    } catch (e) {
      print('Error getting document stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getAllUploadedDocuments() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('ngo_proposals').get();

      List<Map<String, dynamic>> allDocuments = [];

      for (final doc in snapshot.docs) {
        final ngoId = doc.id;
        final documentsSnapshot = await firestore
            .collection('ngo_proposals')
            .doc(ngoId)
            .collection('uploaded_documents')
            .orderBy('uploadedAt', descending: true)
            .get();

        for (final docData in documentsSnapshot.docs) {
          final data = docData.data();
          data['id'] = docData.id;
          data['ngoId'] = ngoId;
          allDocuments.add(data);
        }
      }

      // Sort by upload date
      allDocuments.sort((a, b) {
        final dateA = a['uploadedAt'];
        final dateB = b['uploadedAt'];
        if (dateA == null || dateB == null) return 0;

        try {
          final parsedA =
              dateA is DateTime ? dateA : DateTime.parse(dateA.toString());
          final parsedB =
              dateB is DateTime ? dateB : DateTime.parse(dateB.toString());
          return parsedB.compareTo(parsedA);
        } catch (e) {
          return 0;
        }
      });

      return allDocuments;
    } catch (e) {
      print('Error getting all uploaded documents: $e');
      return [];
    }
  }

  // Helper methods for formatting data
  String _formatContactPersons(dynamic contactPersons) {
    if (contactPersons == null) return 'N/A';
    if (contactPersons is List) {
      return contactPersons.map((contact) {
        if (contact is Map<String, dynamic>) {
          return '${contact['name'] ?? 'Unknown'} (${contact['email'] ?? 'No email'})';
        }
        return contact.toString();
      }).join('\n');
    }
    return contactPersons.toString();
  }

  String _formatSocialMediaUrls(dynamic socialMediaUrls) {
    if (socialMediaUrls == null) return 'N/A';
    if (socialMediaUrls is Map<String, dynamic>) {
      return socialMediaUrls.entries
          .where((entry) =>
              entry.value != null && entry.value.toString().isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    return socialMediaUrls.toString();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split(' ')[0];
    }
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp).toString().split(' ')[0];
      } catch (e) {
        return timestamp;
      }
    }
    return timestamp.toString();
  }
}

class _AssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final Function(List<String>) onSave;

  const _AssignmentDialog({
    required this.assignment,
    required this.onSave,
  });

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  List<String> _selectedNGOs = [];
  List<Map<String, dynamic>> _availableNGOs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedNGOs = List<String>.from(widget.assignment['assignedNGOs'] ?? []);
    _loadNGOs();
  }

  Future<void> _loadNGOs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      setState(() {
        _availableNGOs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Assignment for Donor ${widget.assignment['donorId']}'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(
                    'Select NGOs to assign to this donor:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableNGOs.length,
                      itemBuilder: (context, index) {
                        final ngo = _availableNGOs[index];
                        final isSelected = _selectedNGOs.contains(ngo['id']);

                        return CheckboxListTile(
                          title: Text(ngo['organizationName'] ?? 'Unknown NGO'),
                          subtitle: Text(ngo['email'] ?? 'No email'),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedNGOs.add(ngo['id']);
                              } else {
                                _selectedNGOs.remove(ngo['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedNGOs);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  final Function(String, List<String>) onSave;

  const _CreateAssignmentDialog({
    required this.onSave,
  });

  @override
  State<_CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  String? _selectedDonorId;
  List<String> _selectedNGOs = [];
  List<Map<String, dynamic>> _availableDonors = [];
  List<Map<String, dynamic>> _availableNGOs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load donors
      final donorsSnapshot =
          await FirebaseFirestore.instance.collection('donor_profiles').get();
      final donorsSnapshot2 =
          await FirebaseFirestore.instance.collection('donors').get();

      List<Map<String, dynamic>> allDonors = [];

      for (final doc in donorsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'donor_profiles';
        allDonors.add(data);
      }

      for (final doc in donorsSnapshot2.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'donors';
        allDonors.add(data);
      }

      // Load NGOs
      final ngosSnapshot = await FirebaseFirestore.instance
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      setState(() {
        _availableDonors = allDonors;
        _availableNGOs = ngosSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Donor-NGO Assignment'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Donor Selection
                  Text(
                    'Select Donor:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDonorId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a donor',
                    ),
                    items: _availableDonors.map((donor) {
                      return DropdownMenuItem<String>(
                        value: donor['id'],
                        child: Text(
                          '${donor['name'] ?? donor['fullName'] ?? 'Unknown'} (${donor['email'] ?? 'No email'})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDonorId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // NGO Selection
                  Text(
                    'Select NGOs to assign:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableNGOs.length,
                      itemBuilder: (context, index) {
                        final ngo = _availableNGOs[index];
                        final isSelected = _selectedNGOs.contains(ngo['id']);

                        return CheckboxListTile(
                          title: Text(ngo['organizationName'] ?? 'Unknown NGO'),
                          subtitle: Text(ngo['email'] ?? 'No email'),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedNGOs.add(ngo['id']);
                              } else {
                                _selectedNGOs.remove(ngo['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedDonorId != null && _selectedNGOs.isNotEmpty
              ? () {
                  widget.onSave(_selectedDonorId!, _selectedNGOs);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Create Assignment'),
        ),
      ],
    );
  }
}
