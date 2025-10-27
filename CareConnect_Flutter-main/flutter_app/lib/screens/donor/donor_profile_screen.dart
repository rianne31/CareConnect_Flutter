import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../models/donor.dart';
import 'loyalty_rewards_screen.dart';
import 'ai_chatbot_screen.dart'; // AI Chatbot Screen import

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return Colors.grey[300]!;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey[400]!;
      default:
        return Colors.brown;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return Icons.diamond;
      case 'gold':
        return Icons.stars;
      case 'silver':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Donor>(
        future: _firestoreService.getDonor(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final donor = snapshot.data;
          if (donor == null) return const Center(child: Text('Donor profile not found'));

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              (donor.displayName ?? 'D')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(donor.displayName ?? 'Donor', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(donor.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _getTierColor(donor.tierName), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getTierIcon(donor.tierName), size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('${donor.tierName} Tier', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Total Donated', value: Formatters.formatCurrency(donor.totalDonated), icon: Icons.volunteer_activism, color: Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Donations', value: donor.donationCount.toString(), icon: Icons.favorite, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Progress to Next Tier', value: '${(donor.tierProgress * 100).toStringAsFixed(0)}%', icon: Icons.stars, color: Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Achievements', value: donor.achievements.length.toString(), icon: Icons.emoji_events, color: Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Achievements
                  if (donor.achievements.isNotEmpty) ...[
                    Text('Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: donor.achievements.map((a) => Chip(avatar: const Icon(Icons.emoji_events, size: 16), label: Text(a))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Account Actions
                  Card(
                    child: Column(
                      children: [
                        _ProfileActionTile(icon: Icons.stars, label: 'Loyalty & Rewards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyRewardsScreen()))),
                        const Divider(height: 1),
                        _ProfileActionTile(icon: Icons.edit, label: 'Edit Profile', onTap: () {}),
                        const Divider(height: 1),
                        _ProfileActionTile(icon: Icons.notifications, label: 'Notifications', onTap: () {}),
                        const Divider(height: 1),
                        _ProfileActionTile(icon: Icons.security, label: 'Privacy & Security', onTap: () {}),
                        const Divider(height: 1),
                        _ProfileActionTile(icon: Icons.help, label: 'Help & Support', onTap: () {}),
                        const Divider(height: 1),
                        _ProfileActionTile(icon: Icons.logout, label: 'Logout', labelColor: Colors.red, onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) await _authService.signOut();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ProfileActionTile({required this.icon, required this.label, required this.onTap, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: labelColor ?? Colors.black),
      title: Text(label, style: TextStyle(color: labelColor ?? Colors.black)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
