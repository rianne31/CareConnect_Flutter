import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import 'make_donation_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final progress = widget.patient.fundingGoal > 0 
        ? widget.patient.currentFunding / widget.patient.fundingGoal 
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.publicAlias),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.patient.publicAlias[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.patient.publicAlias,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(widget.patient.cancerType),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),

            // Funding Progress
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raised',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(widget.patient.currentFunding),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                            'Goal',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(widget.patient.fundingGoal),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% funded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Story Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Story',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.patient.story,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Treatment Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treatment Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.medical_services,
                    label: 'Cancer Type',
                    value: widget.patient.cancerType,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Diagnosis Date',
                    value: Formatters.formatDate(widget.patient.diagnosisDate),
                  ),
                  _DetailRow(
                    icon: Icons.local_hospital,
                    label: 'Treatment Stage',
                    value: widget.patient.treatmentStage,
                  ),
                  _DetailRow(
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: widget.patient.status.toUpperCase(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.patient.status == 'active' ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MakeDonationScreen(patient: widget.patient),
                ),
              );
            } : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Donate Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
