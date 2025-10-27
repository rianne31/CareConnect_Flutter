import 'package:cloud_firestore/cloud_firestore.dart';

class Auction {
  final String id;
  final String sellerId;
  final String itemName;
  final String itemDescription;
  final String itemImageUrl;
  final String imageUrl; // Added missing property
  final String description; // Added missing property
  final int bidCount; // Added missing property
  final double targetBid; // Added target bid for progress and UI
  final double startingBid;
  final double currentBid;
  final String? currentBidderId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int? blockchainAuctionId;
  final String? blockchainTxHash;
  final DateTime createdAt;
  final double minBidIncrement;
  final String? tokenId;

  Auction({
    required this.id,
    required this.sellerId,
    required this.itemName,
    required this.itemDescription,
    required this.itemImageUrl,
    required this.imageUrl,
    required this.description,
    required this.bidCount,
    required this.targetBid,
    required this.startingBid,
    required this.currentBid,
    this.currentBidderId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.blockchainAuctionId,
    this.blockchainTxHash,
    required this.createdAt,
    this.minBidIncrement = 0.1,
    this.tokenId,
  });

  factory Auction.fromFirestore(Map<String, dynamic> data, {required String id}) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      try {
        final d = v.toDate();
        if (d is DateTime) return d;
      } catch (_) {}
      return DateTime.now();
    }

    return Auction(
      id: id,
      sellerId: data['sellerId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      itemImageUrl: data['itemImageUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? data['itemImageUrl'] ?? '',
      description: data['description'] ?? data['itemDescription'] ?? '',
      bidCount: data['bidCount'] ?? 0,
      targetBid: (data['targetBid'] ?? data['startingBid'] ?? 0).toDouble(),
      startingBid: (data['startingBid'] ?? 0).toDouble(),
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      currentBidderId: data['currentBidderId'],
      startTime: _toDate(data['startTime']),
      endTime: _toDate(data['endTime']),
      status: data['status'] ?? 'pending',
      blockchainAuctionId: data['blockchainAuctionId'],
      blockchainTxHash: data['blockchainTxHash'],
      createdAt: _toDate(data['createdAt']),
      minBidIncrement: (data['minBidIncrement'] ?? 0.1).toDouble(),
      tokenId: data['tokenId'],
    );
  }

  bool get isActive => status == 'active' && DateTime.now().isBefore(endTime);
  
  Duration get timeRemaining => endTime.difference(DateTime.now());
  
  // Alias for compatibility with existing code
  String? get highestBidderId => currentBidderId;
}
