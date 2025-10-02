import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/donation.dart';
import '../../utils/formatters.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == 'all',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'all';
                    });
                  },
                ),
                _FilterChip(
                  label: 'Completed',
                  selected: _filterStatus == 'completed',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'completed';
                    });
                  },
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _filterStatus == 'pending',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'pending';
                    });
                  },
                ),
                _FilterChip(
                  label: 'Failed',
                  selected: _filterStatus == 'failed',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'failed';
                    });
                  },
                ),
              ],
            ),
          ),

          // Donations List
          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _firestoreService.getDonorDonations(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No donations yet'),
                      ],
                    ),
                  );
                }

                var donations = snapshot.data!;

                // Apply filter
                if (_filterStatus != 'all') {
                  donations = donations.where((donation) {
                    return donation.status == _filterStatus;
                  }).toList();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final donation = donations[index];
                      return _DonationCard(donation: donation);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;

  const _DonationCard({required this.donation});

  Color _getStatusColor() {
    switch (donation.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (donation.status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showDonationDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatCurrency(donation.amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor(),
                    ),
                    label: Text(
                      donation.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(),
                      ),
                    ),
                    backgroundColor: _getStatusColor().withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Patient ID: ${donation.patientId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    donation.paymentMethod == 'crypto' 
                        ? Icons.currency_bitcoin 
                        : Icons.payment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    donation.paymentMethod.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDate(donation.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (donation.transactionHash != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Tx: ${donation.transactionHash!.substring(0, 10)}...${donation.transactionHash!.substring(donation.transactionHash!.length - 8)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDonationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Donation Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Amount', value: Formatters.formatCurrency(donation.amount)),
              _DetailRow(label: 'Status', value: donation.status.toUpperCase()),
              _DetailRow(label: 'Payment Method', value: donation.paymentMethod.toUpperCase()),
              _DetailRow(label: 'Patient ID', value: donation.patientId),
              _DetailRow(label: 'Date', value: Formatters.formatDate(donation.createdAt)),
              _DetailRow(label: 'Anonymous', value: donation.isAnonymous ? 'Yes' : 'No'),
              if (donation.transactionHash != null)
                _DetailRow(label: 'Transaction Hash', value: donation.transactionHash!),
              if (donation.blockchainVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Blockchain Verified',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
