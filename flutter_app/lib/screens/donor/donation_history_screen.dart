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
        title: const Text(
          'Donation History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Filter Chips
          Container(
            width: double.infinity,
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All', 'all'),
                  _buildChip('Completed', 'completed'),
                  _buildChip('Pending', 'pending'),
                  _buildChip('Failed', 'failed'),
                ],
              ),
            ),
          ),

          // 🔹 Donation List
          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _firestoreService.getDonorDonations(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading donations.',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No donations yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                var donations = snapshot.data!;
                if (_filterStatus != 'all') {
                  donations = donations
                      .where((d) => d.status == _filterStatus)
                      .toList();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      return _DonationCard(donation: donations[index]);
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

  Widget _buildChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.blueAccent,
        onSelected: (_) {
          setState(() => _filterStatus = value);
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;
  const _DonationCard({required this.donation});

  Color _statusColor() {
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

  IconData _statusIcon() {
    switch (donation.status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => _showDetails(context),
        title: Text(
          Formatters.formatCurrency(donation.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  donation.paymentMethod == 'crypto'
                      ? Icons.currency_bitcoin
                      : Icons.payment,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  donation.paymentMethod.toUpperCase(),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  Formatters.formatDate(donation.createdAt),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (donation.transactionHash != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tx: ${donation.transactionHash!.substring(0, 8)}...${donation.transactionHash!.substring(donation.transactionHash!.length - 6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(), color: _statusColor(), size: 20),
            const SizedBox(height: 4),
            Text(
              donation.status.toUpperCase(),
              style: TextStyle(
                color: _statusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Donation Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 24),
              _detailRow('Amount', Formatters.formatCurrency(donation.amount)),
              _detailRow('Status', donation.status.toUpperCase()),
              _detailRow(
                  'Payment Method', donation.paymentMethod.toUpperCase()),
              _detailRow('Patient ID', donation.patientId ?? 'N/A'),
              _detailRow('Date', Formatters.formatDate(donation.createdAt)),
              _detailRow('Anonymous', donation.isAnonymous ? 'Yes' : 'No'),
              if (donation.transactionHash != null)
                _detailRow('Transaction Hash', donation.transactionHash!),
              if (donation.blockchainVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: const [
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
