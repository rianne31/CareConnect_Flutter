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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            color: AppColors.surface,
            child: Row(
              children: [
                Text(
                  'Auction Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Auction>>(
              stream: firestoreService.getActiveAuctions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No active auctions'),
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
                    return Card(
                      child: ListTile(
                        title: Text(auction.itemName),
                        subtitle: Text(
                          'Current bid: ${Formatters.formatCurrency(auction.currentBid)}',
                        ),
                        trailing: Text(
                          auction.isActive ? 'Active' : 'Ended',
                          style: TextStyle(
                            color: auction.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
