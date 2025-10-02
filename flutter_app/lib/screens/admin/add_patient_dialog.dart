import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _medicalUrgencyController = TextEditingController();
  final _familySituationController = TextEditingController();
  int _priority = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diagnosisController.dispose();
    _fundingGoalController.dispose();
    _medicalUrgencyController.dispose();
    _familySituationController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      
      // Create patient document
      await db.collection('patients').add({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'diagnosis': _diagnosisController.text.trim(),
        'fundingGoal': double.parse(_fundingGoalController.text),
        'currentFunding': 0,
        'priority': _priority,
        'medicalUrgency': _medicalUrgencyController.text.trim(),
        'familySituation': _familySituationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Patient',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter patient name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid age';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: TextFormField(
                        controller: _fundingGoalController,
                        decoration: const InputDecoration(
                          labelText: 'Funding Goal (₱)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter diagnosis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                TextFormField(
                  controller: _medicalUrgencyController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Urgency',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                TextFormField(
                  controller: _familySituationController,
                  decoration: const InputDecoration(
                    labelText: 'Family Situation',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                Text(
                  'Priority Level: $_priority',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Slider(
                  value: _priority.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _priority.toString(),
                  onChanged: (value) {
                    setState(() {
                      _priority = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Patient'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
