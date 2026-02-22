import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ConsultationScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;

  const ConsultationScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _handleSave() async {
    if (_diagnosisController.text.isEmpty || _prescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter diagnosis and prescription')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.addMedicalRecord(
        appointmentId: widget.appointmentId,
        diagnosis: _diagnosisController.text,
        prescription: _prescriptionController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Consultation recorded successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consultation: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _diagnosisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                hintText: 'Enter clinical diagnosis...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prescriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Prescription (Medicines)',
                hintText: 'e.g., Paracetamol 500mg - 1-0-1 - 5 days',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Doctor Notes',
                hintText: 'Any advice or observations...',
                border: OutlineInputBorder(),
              ),
            ),
             const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Complete Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
