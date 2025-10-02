import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

class MakeDonationScreen extends StatefulWidget {
  final Patient patient;

  const MakeDonationScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<MakeDonationScreen> createState() => _MakeDonationScreenState();
}

class _MakeDonationScreenState extends State<MakeDonationScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _paymentMethod = 'crypto';
  bool _isAnonymous = false;
  bool _isProcessing = false;

  final List<double> _quickAmounts = [100, 500, 1000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final amount = double.parse(_amountController.text);

      final result = await _apiService.createDonation(
        amount: amount,
        currency: 'PHP',
        paymentMethod: _paymentMethod,
        patientId: widget.patient.id,
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      if (_paymentMethod == 'crypto') {
        // Show blockchain transaction dialog
        _showBlockchainDialog(result);
      } else {
        // Redirect to payment gateway
        _redirectToPaymentGateway(result);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showBlockchainDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Blockchain Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please send the exact amount to the contract address:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result['contractAddress'] ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: ${result['amountInMatic']} MATIC',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your donation will be confirmed once the transaction is processed on the blockchain.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _redirectToPaymentGateway(Map<String, dynamic> result) {
    // TODO: Implement payment gateway redirect
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redirecting to Payment'),
        content: Text('Redirecting to ${_paymentMethod.toUpperCase()} payment gateway...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          widget.patient.publicAlias[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patient.publicAlias,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.patient.cancerType,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount Selection
              Text(
                'Donation Amount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _quickAmounts.map((amount) {
                  return ChoiceChip(
                    label: Text(Formatters.formatCurrency(amount)),
                    selected: _amountController.text == amount.toString(),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _amountController.text = amount.toString();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Custom Amount',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Payment Method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _PaymentMethodCard(
                title: 'Cryptocurrency (MATIC)',
                subtitle: 'Blockchain-verified donation',
                icon: Icons.currency_bitcoin,
                value: 'crypto',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              _PaymentMethodCard(
                title: 'PayMaya',
                subtitle: 'Credit/Debit Card, E-Wallet',
                icon: Icons.payment,
                value: 'paymaya',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              _PaymentMethodCard(
                title: 'GCash',
                subtitle: 'Mobile Wallet',
                icon: Icons.phone_android,
                value: 'gcash',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Anonymous Option
              CheckboxListTile(
                title: const Text('Make this donation anonymous'),
                subtitle: const Text('Your name will not be displayed publicly'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Donate Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _processDonation,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Donate Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue[50] : null,
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(subtitle),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
    );
  }
}
