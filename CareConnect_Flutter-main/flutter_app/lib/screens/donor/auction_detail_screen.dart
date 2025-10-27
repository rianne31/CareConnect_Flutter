import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/auction.dart';
import '../../services/api_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import 'ai_chatbot_screen.dart';

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

  final Color _rose = const Color(0xFFFF6F91);
  final Color _gold = const Color(0xFFFFC75F);
  final Color _bg = const Color(0xFFFFF8F0);

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
      if (mounted) setState(() {});
    });
  }

  Future<void> _placeBid() async {
    if (_bidController.text.trim().isEmpty) {
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
          content: Text(
              'Bid must be higher than ${Formatters.formatCurrency(_auction.currentBid)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingBid = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to place a bid');
      }

      await _apiService.placeBid(
        _auction.id,
        bidAmount,
        user.uid,
      );

      final updatedAuction = await _firestoreService.getAuction(_auction.id);
      if (updatedAuction != null) setState(() => _auction = updatedAuction);

      _bidController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isPlacingBid = false);
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // --- Floating Chatbot FAB ---
  Widget _buildChatFab(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'careconnect_bot_fab',
      backgroundColor: _rose,
      onPressed: () => _openChatModal(context),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }

  void _openChatModal(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final conversationId = user != null
        ? '${user.uid}_${_auction.id}'
        : 'guest_${_auction.id}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.85;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: AiChatbotScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive =
        _auction.status == 'active' && _auction.endTime.isAfter(now);
    final timeRemaining = _auction.endTime.difference(now);

    return Scaffold(
      floatingActionButton: _buildChatFab(context),
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_rose, _gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Auction Details',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _auction.imageUrl != null
                  ? Image.network(
                      _auction.imageUrl!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 260,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 80),
                    ),
            ),
            const SizedBox(height: 20),

            // Title + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _auction.itemName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isActive
                        ? 'LIVE ⏱ ${_formatTimeRemaining(timeRemaining)}'
                        : 'ENDED',
                    style: TextStyle(
                      color: isActive ? Colors.green[800] : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Bid Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Bid',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(_auction.currentBid),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Bids',
                            style: TextStyle(
                                fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          '${_auction.bidCount}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_auction.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),

            // Item Details
            const Text(
              'Item Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Starting Bid', value: Formatters.formatCurrency(_auction.startingBid)),
            _DetailRow(label: 'Min Increment', value: Formatters.formatCurrency(_auction.minBidIncrement)),
            _DetailRow(label: 'Start Time', value: Formatters.formatDate(_auction.startTime)),
            _DetailRow(label: 'End Time', value: Formatters.formatDate(_auction.endTime)),
            if (_auction.tokenId != null)
              _DetailRow(label: 'NFT Token ID', value: _auction.tokenId!),
          ],
        ),
      ),
      bottomNavigationBar: isActive
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bidController,
                        decoration: InputDecoration(
                          labelText: 'Enter your bid',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isPlacingBid ? null : _placeBid,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        backgroundColor: _rose,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPlacingBid
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Place Bid',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}
