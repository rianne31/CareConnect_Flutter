import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/auction.dart';
import '../../services/api_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import 'dart:async';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailScreen({Key? key, required this.auction}) : super(key: key);

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final _bidController = TextEditingController();
  
  bool _isPlacingBid = false;
  Timer? _timer;
  late Auction _auction;

  @override
  void initState() {
    super.initState();
    _auction = widget.auction;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _placeBid() async {
    if (!_bidController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a bid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= _auction.currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bid must be higher than ${Formatters.formatCurrency(_auction.currentBid)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingBid = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final result = await _apiService.placeBid(
        auctionId: _auction.id,
        bidderId: user!.uid,
        amount: bidAmount,
      );

      if (!mounted) return;

      // Refresh auction data
      final updatedAuction = await _firestoreService.getAuction(_auction.id);
      if (updatedAuction != null) {
        setState(() {
          _auction = updatedAuction;
        });
      }

      _bidController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
          _isPlacingBid = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive = _auction.status == 'active' && _auction.endTime.isAfter(now);
    final timeRemaining = _auction.endTime.difference(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: _auction.imageUrl != null
                  ? Image.network(
                      _auction.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image, size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _auction.itemName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Current Bid Section
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Bid',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(_auction.currentBid),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                                    isActive ? 'Time Remaining' : 'Ended',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isActive
                                        ? _formatTimeRemaining(timeRemaining)
                                        : 'Auction Ended',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_auction.bidCount} bids',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              if (_auction.highestBidderId != null)
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, size: 16, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Leading bidder',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _auction.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Item Details
                  Text(
                    'Item Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Starting Bid',
                    value: Formatters.formatCurrency(_auction.startingBid),
                  ),
                  _DetailRow(
                    label: 'Minimum Increment',
                    value: Formatters.formatCurrency(_auction.minBidIncrement),
                  ),
                  _DetailRow(
                    label: 'Start Time',
                    value: Formatters.formatDate(_auction.startTime),
                  ),
                  _DetailRow(
                    label: 'End Time',
                    value: Formatters.formatDate(_auction.endTime),
                  ),
                  if (_auction.tokenId != null)
                    _DetailRow(
                      label: 'NFT Token ID',
                      value: _auction.tokenId!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isActive
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bidController,
                        decoration: InputDecoration(
                          labelText: 'Your Bid',
                          prefixText: '₱ ',
                          hintText: 'Min: ${Formatters.formatCurrency(_auction.currentBid + _auction.minBidIncrement)}',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isPlacingBid ? null : _placeBid,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                      ),
                      child: _isPlacingBid
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Place Bid'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
