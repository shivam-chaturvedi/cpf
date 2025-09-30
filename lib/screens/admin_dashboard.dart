import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/ngo_provider.dart';
import '../providers/auth_provider.dart';
import '../util/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custome_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_navbar.dart';
import '../services/certificate_service.dart';
import '../services/donor_ngo_service.dart';

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
    _tabController = TabController(length: 8, vsync: this);
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
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                      Tab(
                          text: 'Validation Tracker',
                          icon: Icon(Icons.assignment_turned_in)),
                      Tab(text: 'NGO Management', icon: Icon(Icons.business)),
                      Tab(text: 'Donor Approval', icon: Icon(Icons.people)),
                      Tab(text: 'Renewal Alerts', icon: Icon(Icons.schedule)),
                      Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                      Tab(text: 'Donor-NGO Assignment', icon: Icon(Icons.link)),
                      Tab(text: 'Certificates', icon: Icon(Icons.verified)),
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Review Pending NGOs',
                  onPressed: () => _tabController.animateTo(1),
                  backgroundColor: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Approve Donors',
                  onPressed: () => _tabController.animateTo(3),
                  backgroundColor: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Check Renewals',
                  onPressed: () => _tabController.animateTo(4),
                  backgroundColor: AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCharts(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Search
            CustomTextField(
              controller: _searchController,
              label: '',
              hint: 'Search NGOs...',
              icon: Icons.search,
              onChanged: (value) => _applyFilters(),
            ),
            const SizedBox(height: 16),

            // Filter dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date filters
            Row(
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
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Select date'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'Select date'),
                    ),
                  ),
                ),
              ],
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
        // NGO Status Distribution
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NGO Status Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatusChart(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Applications
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Applications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMonthlyChart(),
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
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Container(
            height: 20,
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
        const SizedBox(width: 8),
        Text(
          '$value (${(percentage * 100).toStringAsFixed(1)}%)',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
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
      builder: (context) => AlertDialog(
        title: Text(ngo['organizationName'] ?? 'NGO Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', ngo['email'] ?? 'N/A'),
              _buildDetailRow('Phone', ngo['phone'] ?? 'N/A'),
              _buildDetailRow('Category', ngo['category'] ?? 'N/A'),
              _buildDetailRow('Location', ngo['location'] ?? 'N/A'),
              _buildDetailRow('Status', ngo['status'] ?? 'N/A'),
              _buildDetailRow(
                  'Created',
                  ngo['createdAt'] != null
                      ? (ngo['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                      : 'N/A'),
              if (ngo['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ngo['description'],
                          style: Theme.of(context).textTheme.bodyMedium),
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
        ],
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split(' ')[0];
    }
    return timestamp.toString();
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
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
