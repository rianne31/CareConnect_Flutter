// Using a mock Timestamp class since cloud_firestore is causing issues
class Timestamp {
  final int seconds;
  final int nanoseconds;
  
  Timestamp(this.seconds, this.nanoseconds);
  
  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
  
  static Timestamp fromDate(DateTime dateTime) {
    return Timestamp(dateTime.millisecondsSinceEpoch ~/ 1000, 0);
  }
}

class Auction {
  final String id;
  final String sellerId;
  final String itemName;
  final String itemDescription;
  final String itemImageUrl;
  final String imageUrl; // Added missing property
  final String description; // Added missing property
  final int bidCount; // Added missing property
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
    return Auction(
      id: id,
      sellerId: data['sellerId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      itemImageUrl: data['itemImageUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? data['itemImageUrl'] ?? '',
      description: data['description'] ?? data['itemDescription'] ?? '',
      bidCount: data['bidCount'] ?? 0,
      startingBid: (data['startingBid'] ?? 0).toDouble(),
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      currentBidderId: data['currentBidderId'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      blockchainAuctionId: data['blockchainAuctionId'],
      blockchainTxHash: data['blockchainTxHash'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      minBidIncrement: (data['minBidIncrement'] ?? 0.1).toDouble(),
      tokenId: data['tokenId'],
    );
  }

  bool get isActive => status == 'active' && DateTime.now().isBefore(endTime);
  
  Duration get timeRemaining => endTime.difference(DateTime.now());
  
  // Alias for compatibility with existing code
  String? get highestBidderId => currentBidderId;
}
