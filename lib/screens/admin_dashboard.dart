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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
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
  List<Map<String, dynamic>> _renewalAlerts = [];
  Map<String, dynamic> _validationStats = {};
  Map<String, int> _donorStats = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
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
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildValidationTrackerTab(),
                _buildNGOManagementTab(),
                _buildDonorApprovalTab(),
                _buildRenewalAlertsTab(),
                _buildAnalyticsTab(),
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
            'Donor Applications (${_allDonors.length})',
            style: Theme.of(context).textTheme.headlineMedium,
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
                  child: Text(
                    ngo['organizationName'] ?? 'Unknown NGO',
                    style: Theme.of(context).textTheme.titleLarge,
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
            const SizedBox(height: 8),
            Text(
              ngo['email'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${ngo['category'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${ngo['location'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showNGODetails(ngo),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending' || status == 'under_review')
                  Expanded(
                    child: CustomButton(
                      text: 'Review',
                      onPressed: () => _showReviewDialog(ngo),
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
    if (_allDonors.isEmpty) {
      return const Center(
        child: Text('No donors found'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allDonors.length,
      itemBuilder: (context, index) {
        final donor = _allDonors[index];
        return _buildDonorItem(donor);
      },
    );
  }

  Widget _buildDonorItem(Map<String, dynamic> donor) {
    final status = donor['status'] as String? ?? 'pending';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
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
                  child: Text(
                    donor['name'] ?? 'Unknown Donor',
                    style: Theme.of(context).textTheme.titleLarge,
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
            const SizedBox(height: 8),
            Text(
              donor['email'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${donor['phone'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () => _showDonorDetails(donor),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending')
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _approveDonor(donor),
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (status == 'pending') const SizedBox(width: 8),
                if (status == 'pending')
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () => _rejectDonor(donor),
                      backgroundColor: Colors.red,
                    ),
                  ),
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

  Future<void> _approveDonor(Map<String, dynamic> donor) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateDonorStatus(
      donorId: donor['id'],
      status: 'approved',
      adminComments: 'Approved by admin',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor approved successfully')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve donor')),
      );
    }
  }

  Future<void> _rejectDonor(Map<String, dynamic> donor) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateDonorStatus(
      donorId: donor['id'],
      status: 'rejected',
      adminComments: 'Rejected by admin',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor rejected')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject donor')),
      );
    }
  }

  void _sendRenewalReminder(Map<String, dynamic> ngo) {
    // This would typically send an email or notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Renewal reminder sent to ${ngo['organizationName']}')),
    );
  }
}
