import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';

class EditPatientDialog extends StatefulWidget {
  final Patient patient;

  const EditPatientDialog({super.key, required this.patient});

  @override
  State<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _diagnosisController;
  late TextEditingController _fundingGoalController;
  late TextEditingController _currentFundingController;
  late int _priority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _diagnosisController = TextEditingController(text: widget.patient.diagnosis);
    _fundingGoalController =
        TextEditingController(text: widget.patient.fundingGoal.toString());
    _currentFundingController =
        TextEditingController(text: widget.patient.currentFunding.toString());
    _priority = widget.patient.priority;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diagnosisController.dispose();
    _fundingGoalController.dispose();
    _currentFundingController.dispose();
    super.dispose();
  }

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      
      await db.collection('patients').doc(widget.patient.id).update({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'diagnosis': _diagnosisController.text.trim(),
        'fundingGoal': double.parse(_fundingGoalController.text),
        'currentFunding': double.parse(_currentFundingController.text),
        'priority': _priority,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient updated successfully'),
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
                  'Edit Patient',
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                TextFormField(
                  controller: _currentFundingController,
                  decoration: const InputDecoration(
                    labelText: 'Current Funding (₱)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
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
                      onPressed: _isLoading ? null : _updatePatient,
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
                          : const Text('Update Patient'),
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
