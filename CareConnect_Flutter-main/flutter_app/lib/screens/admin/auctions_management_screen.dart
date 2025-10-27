import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../models/auction.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AuctionsManagementScreen extends ConsumerWidget {
  const AuctionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Auctions Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Add Auction',
            onPressed: () => _showAddAuctionDialog(context, firestoreService),
          ),
        ],
      ),
      body: StreamBuilder<List<Auction>>(
        stream: firestoreService.getActiveAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No active auctions found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final auctions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            itemCount: auctions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSizes.paddingMedium),
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return _AuctionCard(auction: auction);
            },
          );
        },
      ),
    );
  }

  void _showAddAuctionDialog(
      BuildContext context, FirestoreService firestoreService) {
    final itemNameController = TextEditingController();
    final startingBidController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Auction Item',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextField(
                  controller: itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextField(
                  controller: startingBidController,
                  decoration: const InputDecoration(
                    labelText: 'Starting Bid (₱)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (itemNameController.text.isEmpty ||
                            startingBidController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        await firestoreService.addAuction(
                          itemNameController.text.trim(),
                          double.parse(startingBidController.text),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Auction added successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuctionCard extends StatefulWidget {
  final Auction auction;

  const _AuctionCard({required this.auction});

  @override
  State<_AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<_AuctionCard> {
  late Duration _timeLeft;
  late final DateTime _endTime;
  late final bool _isActive;
  late final double _progress;
  late final ValueNotifier<String> _timerText;

  @override
  void initState() {
    super.initState();
    _endTime = widget.auction.endTime ?? DateTime.now();
    _isActive = widget.auction.isActive;
    _progress = widget.auction.currentBid / widget.auction.targetBid;
    _timeLeft = _endTime.difference(DateTime.now());
    _timerText = ValueNotifier(_formatTime(_timeLeft));

    if (_isActive) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      final remaining = _endTime.difference(DateTime.now());
      if (remaining.isNegative) return false;
      _timerText.value = _formatTime(remaining);
      return true;
    });
  }

  String _formatTime(Duration d) {
    if (d.isNegative) return 'Ended';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.auction.itemName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isActive ? 'Active' : 'Ended',
                    style: TextStyle(
                      color: _isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Current Bid: ${Formatters.formatCurrency(widget.auction.currentBid)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Target Bid: ${Formatters.formatCurrency(widget.auction.targetBid)}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _progress > 1 ? 1 : _progress,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _timerText,
                  builder: (context, value, _) {
                    return Text(
                      _isActive ? 'Time Left: $value' : 'Auction Ended',
                      style: TextStyle(
                        color:
                            _isActive ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Future: show context menu (edit/delete)
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
