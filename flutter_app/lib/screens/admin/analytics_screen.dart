import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics & Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            
            FutureBuilder<Map<String, dynamic>>(
              future: firestoreService.getRetentionMetrics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final metrics = snapshot.data!;

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Donor Retention',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Active Donors',
                                    value: '${metrics['activeDonors'] ?? 0}',
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.paddingMedium),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'At-Risk Donors',
                                    value: '${metrics['atRiskDonors'] ?? 0}',
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
