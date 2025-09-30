import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../util/theme.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/custome_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class NGOListPage extends StatefulWidget {
  const NGOListPage({super.key});

  @override
  State<NGOListPage> createState() => _NGOListPageState();
}

class _NGOListPageState extends State<NGOListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _ngos = [];
  List<Map<String, dynamic>> _filteredNGOs = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadNGOs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNGOs() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      _ngos = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _filteredNGOs = List.from(_ngos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading NGOs: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterNGOs() {
    setState(() {
      _filteredNGOs = _ngos.where((ngo) {
        final matchesSearch = _searchController.text.isEmpty ||
            (ngo['organizationName']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ??
                false) ||
            (ngo['email']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ??
                false);

        final matchesCategory = _selectedCategory == 'all' ||
            (ngo['category']?.toString().toLowerCase() ==
                _selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: const CustomNavbar(
        title: 'Verified NGOs',
        isLandingPage: false,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceWhite,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
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
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('education', 'Education'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('health', 'Health'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('environment', 'Environment'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('social', 'Social Welfare'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // NGO List
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading NGOs...')
                : _filteredNGOs.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.business_center,
                        title: 'No NGOs Found',
                        message: 'No verified NGOs match your search criteria',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredNGOs.length,
                        itemBuilder: (context, index) {
                          final ngo = _filteredNGOs[index];
                          return _buildNGOCard(ngo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = category);
        _filterNGOs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNGOCard(Map<String, dynamic> ngo) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo['organizationName'] ?? 'Unknown NGO',
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
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category and Location
            Row(
              children: [
                if (ngo['category'] != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ngo['category'].toString().toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (ngo['location'] != null) ...[
                  Icon(Icons.location_on,
                      color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    ngo['location'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (ngo['description'] != null &&
                ngo['description'].toString().isNotEmpty) ...[
              Text(
                ngo['description'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Sectors of Work
            if (ngo['sectorOfWork'] != null &&
                (ngo['sectorOfWork'] as List).isNotEmpty) ...[
              Wrap(
                children: (ngo['sectorOfWork'] as List).take(3).map((sector) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sector.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showNGODetails(ngo),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryRed,
                      side: const BorderSide(color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSupportDialog(ngo),
                    icon: const Icon(Icons.favorite, size: 18),
                    label: const Text('Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
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

  void _showNGODetails(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ngo['organizationName'] ?? 'NGO Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', ngo['email'] ?? 'N/A'),
              _buildDetailRow('Phone', ngo['phone'] ?? 'N/A'),
              _buildDetailRow('Category', ngo['category'] ?? 'N/A'),
              _buildDetailRow('Location', ngo['location'] ?? 'N/A'),
              _buildDetailRow('Address', ngo['address'] ?? 'N/A'),
              if (ngo['website'] != null)
                _buildDetailRow('Website', ngo['website']),
              if (ngo['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(ngo['description']),
              ],
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

  void _showSupportDialog(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Support ${ngo['organizationName']}'),
        content: const Text(
          'To support this NGO, please contact CPF at info@cpfindia.org or visit our website at www.cpfindia.org for more information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contact');
            },
            child: const Text('Contact CPF'),
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
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
