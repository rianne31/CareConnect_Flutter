import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'add_patient_dialog.dart';
import 'edit_patient_dialog.dart';

class PatientsManagementScreen extends ConsumerStatefulWidget {
  const PatientsManagementScreen({super.key});

  @override
  ConsumerState<PatientsManagementScreen> createState() =>
      _PatientsManagementScreenState();
}

class _PatientsManagementScreenState
    extends ConsumerState<PatientsManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                        vertical: AppSizes.paddingSmall,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddPatientDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Patient list
          Expanded(
            child: StreamBuilder<List<Patient>>(
              stream: _firestoreService.getAdminPatients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No patients found'),
                  );
                }

                var patients = snapshot.data!;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  patients = patients.where((patient) {
                    return (patient.name?.toLowerCase().contains(_searchQuery) ??
                            false) ||
                        patient.diagnosis.toLowerCase().contains(_searchQuery) ||
                        patient.anonymousId.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  itemCount: patients.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.paddingMedium),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _PatientCard(patient: patient);
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

class _PatientCard extends StatelessWidget {
  final Patient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    patient.age.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            patient.name ?? patient.anonymousId,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(patient.priority)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSmall),
                            ),
                            child: Text(
                              'Priority ${patient.priority}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(patient.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.diagnosis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditPatientDialog(patient: patient),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            
            // Funding progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Funding Progress',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${Formatters.formatCurrency(patient.currentFunding)} / ${Formatters.formatCurrency(patient.fundingGoal)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: patient.fundingProgress / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          patient.fundingProgress >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            
            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // View full details
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                TextButton.icon(
                  onPressed: () {
                    // View documents
                  },
                  icon: const Icon(Icons.folder, size: 18),
                  label: const Text('Documents'),
                ),
                const Spacer(),
                Text(
                  'Updated ${Formatters.formatRelativeTime(patient.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return AppColors.error;
    if (priority >= 5) return AppColors.accent;
    return AppColors.success;
  }
}
