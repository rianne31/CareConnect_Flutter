import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CreateAuctionDialog extends StatefulWidget {
  const CreateAuctionDialog({Key? key}) : super(key: key);

  @override
  State<CreateAuctionDialog> createState() => _CreateAuctionDialogState();
}

class _CreateAuctionDialogState extends State<CreateAuctionDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingBidController = TextEditingController();
  final _minBidIncrementController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isCreating = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _startingBidController.dispose();
    _minBidIncrementController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _apiService.createAuction(
        itemName: _itemNameController.text,
        description: _descriptionController.text,
        startingBid: double.parse(_startingBidController.text),
        minBidIncrement: double.parse(_minBidIncrementController.text),
        startTime: _startTime!,
        endTime: _endTime!,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Auction',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startingBidController,
                        decoration: const InputDecoration(
                          labelText: 'Starting Bid',
                          prefixText: '₱ ',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minBidIncrementController,
                        decoration: const InputDecoration(
                          labelText: 'Min Increment',
                          prefixText: '₱ ',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateTime(context, true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startTime == null
                              ? 'Start Time'
                              : '${_startTime!.day}/${_startTime!.month} ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateTime(context, false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _endTime == null
                              ? 'End Time'
                              : '${_endTime!.day}/${_endTime!.month} ${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isCreating ? null : _createAuction,
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Auction'),
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
