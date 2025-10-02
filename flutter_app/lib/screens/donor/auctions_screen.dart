import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/auction.dart';
import '../../utils/formatters.dart';
import 'auction_detail_screen.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({Key? key}) : super(key: key);

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterStatus = 'active';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auctions'),
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
                  label: 'Active',
                  selected: _filterStatus == 'active',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'active';
                    });
                  },
                ),
                _FilterChip(
                  label: 'Ending Soon',
                  selected: _filterStatus == 'ending_soon',
                  onSelected: () {
                    setState(() {
                      _filterStatus = 'ending_soon';
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
              ],
            ),
          ),

          // Auctions List
          Expanded(
            child: FutureBuilder<List<Auction>>(
              future: _firestoreService.getAuctions(),
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
                        Icon(Icons.gavel, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No auctions available'),
                      ],
                    ),
                  );
                }

                var auctions = snapshot.data!;

                // Apply filters
                final now = DateTime.now();
                if (_filterStatus == 'active') {
                  auctions = auctions.where((auction) {
                    return auction.status == 'active' && auction.endTime.isAfter(now);
                  }).toList();
                } else if (_filterStatus == 'ending_soon') {
                  final endingSoonThreshold = now.add(const Duration(hours: 24));
                  auctions = auctions.where((auction) {
                    return auction.status == 'active' && 
                           auction.endTime.isAfter(now) &&
                           auction.endTime.isBefore(endingSoonThreshold);
                  }).toList();
                } else if (_filterStatus == 'completed') {
                  auctions = auctions.where((auction) {
                    return auction.status == 'completed' || auction.endTime.isBefore(now);
                  }).toList();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: auctions.length,
                    itemBuilder: (context, index) {
                      final auction = auctions[index];
                      return _AuctionCard(auction: auction);
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

class _AuctionCard extends StatelessWidget {
  final Auction auction;

  const _AuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive = auction.status == 'active' && auction.endTime.isAfter(now);
    final timeRemaining = auction.endTime.difference(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailScreen(auction: auction),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: auction.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        auction.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          auction.itemName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(auction.currentBid),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isActive ? 'Ends in' : 'Ended',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive
                                ? _formatTimeRemaining(timeRemaining)
                                : Formatters.formatDate(auction.endTime),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${auction.bidCount} bids',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
