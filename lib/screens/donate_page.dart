import 'package:flutter/material.dart';
import '../util/theme.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/custome_card.dart';
import '../widgets/custom_button.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedNGO = '';
  String _selectedPaymentMethod = 'online';
  bool _isAnonymous = false;

  final List<Map<String, dynamic>> _ngos = [
    {'id': '1', 'name': 'Anudip Foundation', 'category': 'Education'},
    {
      'id': '2',
      'name': 'Dalit Vikas Abhiyan Samiti',
      'category': 'Social Justice'
    },
    {
      'id': '3',
      'name': 'Bhartiya Jan Utthan Parishad',
      'category': 'Community Development'
    },
    {
      'id': '4',
      'name': 'Nirantar Prawah Foundation',
      'category': 'Rural Development'
    },
    {'id': '5', 'name': 'ROPES', 'category': 'Child Rights'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: const CustomNavbar(
        title: 'Donate',
        isLandingPage: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make a Difference Today',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your donation helps us support verified NGOs and create sustainable social impact.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Donation Form
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 24),

                    // NGO Selection
                    Text(
                      'Select NGO to Support',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedNGO.isEmpty ? null : _selectedNGO,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose an NGO',
                      ),
                      items: _ngos.map<DropdownMenuItem<String>>((ngo) {
                        return DropdownMenuItem<String>(
                          value: ngo['id'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ngo['name']),
                              Text(
                                ngo['category'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedNGO = value ?? '');
                      },
                    ),

                    const SizedBox(height: 20),

                    // Amount Selection
                    Text(
                      'Donation Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Amount Buttons
                    Row(
                      children: [
                        Expanded(child: _buildAmountButton('₹500')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildAmountButton('₹1000')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildAmountButton('₹2500')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildAmountButton('₹5000')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Custom Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 20),

                    // Payment Method
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Online Payment'),
                            value: 'online',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() => _selectedPaymentMethod = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Bank Transfer'),
                            value: 'bank',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() => _selectedPaymentMethod = value!);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Anonymous Donation
                    CheckboxListTile(
                      title: const Text('Make this donation anonymous'),
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() => _isAnonymous = value ?? false);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Donate Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Proceed to Donate',
                        onPressed: _proceedToDonate,
                        backgroundColor: AppTheme.primaryRed,
                        icon: Icons.favorite,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Why Donate Through CPF
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified,
                            color: AppTheme.primaryGreen, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Why Donate Through CPF?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitItem(
                      context,
                      'Verified NGOs',
                      'All NGOs are thoroughly vetted and verified for credibility and compliance.',
                      Icons.verified_user,
                    ),
                    _buildBenefitItem(
                      context,
                      'Tax Benefits',
                      'Get 80G tax deduction certificate for your donations.',
                      Icons.receipt,
                    ),
                    _buildBenefitItem(
                      context,
                      'Transparency',
                      'Complete transparency in fund utilization and impact reporting.',
                      Icons.visibility,
                    ),
                    _buildBenefitItem(
                      context,
                      'Impact Tracking',
                      'Regular updates on how your donation is making a difference.',
                      Icons.trending_up,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact us for any donation-related queries or assistance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'info@cpfindia.org',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+91-XXXXXXXXXX',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButton(String amount) {
    final isSelected = _amountController.text == amount.replaceAll('₹', '');

    return InkWell(
      onTap: () {
        _amountController.text = amount.replaceAll('₹', '');
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderGray,
          ),
        ),
        child: Text(
          amount,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToDonate() {
    if (_selectedNGO.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an NGO to support')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter donation amount')),
      );
      return;
    }

    // Show donation confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'NGO: ${_ngos.firstWhere((ngo) => ngo['id'] == _selectedNGO)['name']}'),
            Text('Amount: ₹${_amountController.text}'),
            Text(
                'Payment Method: ${_selectedPaymentMethod == 'online' ? 'Online Payment' : 'Bank Transfer'}'),
            if (_isAnonymous) const Text('Anonymous: Yes'),
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
              _processDonation();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _processDonation() {
    // In a real app, this would integrate with payment gateway
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Donation processed successfully! You will receive a confirmation email shortly.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );

    // Reset form
    _amountController.clear();
    setState(() {
      _selectedNGO = '';
      _selectedPaymentMethod = 'online';
      _isAnonymous = false;
    });
  }
}
