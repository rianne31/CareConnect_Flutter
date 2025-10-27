// loyalty_rewards_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../models/donor.dart';

class LoyaltyRewardsScreen extends StatefulWidget {
  const LoyaltyRewardsScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyRewardsScreen> createState() => _LoyaltyRewardsScreenState();
}

class _LoyaltyRewardsScreenState extends State<LoyaltyRewardsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final Map<String, Map<String, dynamic>> _tierInfo = {
    'Bronze': {
      'color': Colors.brown,
      'icon': Icons.star_border,
      'minDonation': 0,
      'benefits': ['Welcome badge', 'Monthly newsletter', 'Donation receipts'],
    },
    'Silver': {
      'color': Colors.grey[400],
      'icon': Icons.star,
      'minDonation': 5000,
      'benefits': ['All Bronze benefits', 'Silver badge NFT', 'Quarterly impact reports', 'Priority email support'],
    },
    'Gold': {
      'color': Colors.amber,
      'icon': Icons.stars,
      'minDonation': 25000,
      'benefits': ['All Silver benefits', 'Gold badge NFT', 'Monthly video updates', 'Invitation to annual events', 'Recognition on website'],
    },
    'Platinum': {
      'color': Colors.grey[300],
      'icon': Icons.diamond,
      'minDonation': 100000,
      'benefits': ['All Gold benefits', 'Platinum badge NFT', 'Personal impact coordinator', 'VIP event access', 'Foundation board updates', 'Custom donation projects'],
    },
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Rewards')),
      body: FutureBuilder<Donor>(
        future: _firestoreService.getDonor(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final donor = snapshot.data;
          if (donor == null) return const Center(child: Text('Donor profile not found'));

          final currentTier = donor.tierName;
          final totalDonated = donor.totalDonated;
          final loyaltyPoints = donor.donationCount; // Using donationCount as loyalty points

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Tier Card
                  Card(
                    color: _tierInfo[currentTier]!['color'],
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(_tierInfo[currentTier]!['icon'], size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text('$currentTier Tier', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Total Donated: ${Formatters.formatCurrency(totalDonated)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Loyalty Points: $loyaltyPoints', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress to Next Tier
                  if (currentTier != 'Platinum') ...[
                    Text('Progress to Next Tier', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _NextTierProgress(currentTier: currentTier, totalDonated: totalDonated, tierInfo: _tierInfo),
                    const SizedBox(height: 24),
                  ],

                  // All Tiers
                  Text('Loyalty Tiers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._tierInfo.entries.map((entry) {
                    final tierName = entry.key;
                    final tierData = entry.value;
                    final isCurrentTier = tierName == currentTier;
                    final isUnlocked = totalDonated >= tierData['minDonation'];
                    return _TierCard(tierName: tierName, tierData: tierData, isCurrentTier: isCurrentTier, isUnlocked: isUnlocked);
                  }).toList(),
                  const SizedBox(height: 24),

                  // Achievements
                  if (donor.achievements.isNotEmpty) ...[
                    Text('Your Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: donor.achievements.map((a) => Chip(avatar: const Icon(Icons.emoji_events, size: 16), label: Text(a), backgroundColor: Colors.amber[100])).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NextTierProgress extends StatelessWidget {
  final String currentTier;
  final double totalDonated;
  final Map<String, Map<String, dynamic>> tierInfo;

  const _NextTierProgress({required this.currentTier, required this.totalDonated, required this.tierInfo});

  @override
  Widget build(BuildContext context) {
    final tiers = ['Bronze', 'Silver', 'Gold', 'Platinum'];
    final currentIndex = tiers.indexOf(currentTier);
    final nextTier = tiers[currentIndex + 1];
    final nextTierMin = tierInfo[nextTier]!['minDonation'] as int;
    final progress = totalDonated / nextTierMin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Next: $nextTier Tier', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Icon(tierInfo[nextTier]!['icon'], color: tierInfo[nextTier]!['color']),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(tierInfo[nextTier]!['color']),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text('${Formatters.formatCurrency(totalDonated)} / ${Formatters.formatCurrency(nextTierMin.toDouble())}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('${Formatters.formatCurrency(nextTierMin - totalDonated)} more to unlock', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String tierName;
  final Map<String, dynamic> tierData;
  final bool isCurrentTier;
  final bool isUnlocked;

  const _TierCard({required this.tierName, required this.tierData, required this.isCurrentTier, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentTier ? tierData['color'].withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tierData['icon'], color: tierData['color'], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tierName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (isCurrentTier) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: tierData['color'], borderRadius: BorderRadius.circular(12)),
                              child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Minimum: ${Formatters.formatCurrency(tierData['minDonation'].toDouble())}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (isUnlocked) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Benefits:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(tierData['benefits'] as List<String>).map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: isUnlocked ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(benefit, style: TextStyle(color: isUnlocked ? Colors.black87 : Colors.grey))),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
