// Using a mock Timestamp class if not already defined elsewhere
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

enum DonorTier { bronze, silver, gold, platinum }

class Donor {
  final String id;
  final String email;
  final String? displayName;
  final double totalDonated;
  final int donationCount;
  final DonorTier tier;
  final DateTime? lastDonationAt;
  final DateTime createdAt;
  final List<String> achievements;

  Donor({
    required this.id,
    required this.email,
    this.displayName,
    required this.totalDonated,
    required this.donationCount,
    required this.tier,
    this.lastDonationAt,
    required this.createdAt,
    required this.achievements,
  });

  factory Donor.fromFirestore(Map<String, dynamic> data, {required String id}) {
    return Donor(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      totalDonated: (data['totalDonated'] ?? 0).toDouble(),
      donationCount: data['donationCount'] ?? 0,
      tier: _parseTier(data['tier']),
      lastDonationAt: data['lastDonationAt'] != null
          ? (data['lastDonationAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      achievements: List<String>.from(data['achievements'] ?? []),
    );
  }

  static DonorTier _parseTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'platinum':
        return DonorTier.platinum;
      case 'gold':
        return DonorTier.gold;
      case 'silver':
        return DonorTier.silver;
      default:
        return DonorTier.bronze;
    }
  }

  String get tierName {
    switch (tier) {
      case DonorTier.platinum:
        return 'Platinum';
      case DonorTier.gold:
        return 'Gold';
      case DonorTier.silver:
        return 'Silver';
      case DonorTier.bronze:
        return 'Bronze';
    }
  }

  double get tierProgress {
    switch (tier) {
      case DonorTier.bronze:
        return (totalDonated / 5000).clamp(0.0, 1.0);
      case DonorTier.silver:
        return ((totalDonated - 5000) / 15000).clamp(0.0, 1.0);
      case DonorTier.gold:
        return ((totalDonated - 20000) / 30000).clamp(0.0, 1.0);
      case DonorTier.platinum:
        return 1.0;
    }
  }

  String get nextTierAmount {
    switch (tier) {
      case DonorTier.bronze:
        return '₱5,000';
      case DonorTier.silver:
        return '₱20,000';
      case DonorTier.gold:
        return '₱50,000';
      case DonorTier.platinum:
        return 'Max tier reached';
    }
  }
}
