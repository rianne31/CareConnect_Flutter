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

class _EditPatientDialogState extends State<EditPatientDialog>
    with SingleTickerProviderStateMixin {
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
    _diagnosisController =
        TextEditingController(text: widget.patient.diagnosis);
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

    setState(() => _isLoading = true);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.blue[50]!.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.shade100,
                            Colors.tealAccent.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Edit Patient Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Fields
                    _buildTextField(_nameController, 'Full Name'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(_ageController, 'Age',
                              keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _fundingGoalController,
                            'Funding Goal (₱)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _currentFundingController,
                      'Current Funding (₱)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _diagnosisController,
                      'Diagnosis',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Priority Slider
                    Text(
                      'Priority Level: $_priority',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.teal,
                      inactiveColor: Colors.blueGrey.shade200,
                      label: _priority.toString(),
                      onChanged: (value) =>
                          setState(() => _priority = value.toInt()),
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updatePatient,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                const Color(0xFF4FC3F7), // CareConnect blue
                            elevation: 5,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded,
                                  color: Colors.white),
                          label: const Text(
                            'Update Patient',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF4FC3F7), width: 1.8), // Sky blue
        ),
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.blueAccent.shade100,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
