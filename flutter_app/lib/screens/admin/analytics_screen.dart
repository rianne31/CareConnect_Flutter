import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌈 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📊 Analytics & AI Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                ),
                const Icon(Icons.analytics_rounded,
                    color: AppColors.primary, size: 28),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // 🧠 AI Insights Card
            _AIInsightCard(),

            const SizedBox(height: AppSizes.paddingLarge),

            // 🔍 Retention Metrics Section
            FutureBuilder<Map<String, dynamic>>(
              future: firestoreService.getRetentionMetrics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final metrics = snapshot.data!;
                final activeDonors = metrics['activeDonors'] ?? 0;
                final atRiskDonors = metrics['atRiskDonors'] ?? 0;
                final total = (activeDonors + atRiskDonors).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donor Retention Overview',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 45,
                                sections: [
                                  PieChartSectionData(
                                    color: AppColors.success,
                                    value: activeDonors.toDouble(),
                                    title: '${((activeDonors / total) * 100).toStringAsFixed(1)}%',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: AppColors.accent,
                                    value: atRiskDonors.toDouble(),
                                    title: '${((atRiskDonors / total) * 100).toStringAsFixed(1)}%',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingLarge),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _MetricCard(
                                title: 'Active Donors',
                                value: '$activeDonors',
                                color: AppColors.success,
                              ),
                              const SizedBox(height: AppSizes.paddingMedium),
                              _MetricCard(
                                title: 'At-Risk Donors',
                                value: '$atRiskDonors',
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // 📈 Line Chart Example (Donation Trend)
            Text(
              'Weekly Donation Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt() % 7],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 5),
                        FlSpot(1, 7),
                        FlSpot(2, 6),
                        FlSpot(3, 8),
                        FlSpot(4, 10),
                        FlSpot(5, 7),
                        FlSpot(6, 9),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🧠 Mock AI Insight Card
class _AIInsightCard extends StatefulWidget {
  @override
  State<_AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<_AIInsightCard> {
  bool _loading = false;
  String _insight =
      'Tap "Generate Insight" to let AI analyze recent donation and patient data.';

  Future<void> _generateInsight() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _insight =
          '💡 AI Insight: Donation trends have increased by 25% this week, mostly from repeat donors. Consider featuring ongoing patient stories to maintain momentum.';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Insight Generator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Generate Insight'),
                  onPressed: _loading ? null : _generateInsight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    )
                  : Text(
                      _insight,
                      key: ValueKey(_insight),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 💠 Metric Card Widget
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
