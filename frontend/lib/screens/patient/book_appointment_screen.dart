import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart'; // Add Intl for day name formatting

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final ApiService _apiService = ApiService();
  final _reasonController = TextEditingController();
  
  List<dynamic> _doctors = [];
  String? _selectedDoctorId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = true;

  // Computed available slots based on doc + date
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _apiService.getDoctors();
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateAvailableSlots() {
    if (_selectedDoctorId == null || _selectedDate == null) {
      setState(() => _availableTimeSlots = []);
      return;
    }

    final doctor = _doctors.firstWhere((d) => d['_id'] == _selectedDoctorId);
    final List<dynamic> availability = doctor['availability'] ?? [];
    
    // Get day name (e.g., 'Monday')
    String dayName = DateFormat('EEEE').format(_selectedDate!);
    
    // Find slots for this day
    final dayData = availability.firstWhere(
      (d) => d['day'] == dayName,
      orElse: () => null,
    );

    if (dayData != null) {
      setState(() {
        _availableTimeSlots = List<String>.from(dayData['slots']);
        _availableTimeSlots.sort();
        // Reset selected slot if it's no longer valid
        if (_selectedTimeSlot != null && !_availableTimeSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
      });
    } else {
      setState(() {
        _availableTimeSlots = [];
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _handleBook() async {
    if (_selectedDoctorId == null || _selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
      return;
    }

    try {
      await _apiService.bookAppointment(
        doctorId: _selectedDoctorId!,
        date: _selectedDate!.toIso8601String(),
        timeSlot: _selectedTimeSlot!,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Appointment booked successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to dashboard
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
          SnackBar(content: Text('Error booking: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateAvailableSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Doctor Selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Doctor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _selectedDoctorId,
                    items: _doctors.map<DropdownMenuItem<String>>((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['_id'],
                        child: Text('Dr. ${doctor['name']} (${doctor['specialization']})'), // Shown Specialization
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDoctorId = val;
                        _selectedDate = null; // Reset date when doctor changes
                        _selectedTimeSlot = null;
                        _availableTimeSlots = [];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Selection
                  InkWell(
                    onTap: _selectedDoctorId == null ? null : () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select Date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        enabled: _selectedDoctorId != null, 
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Choose Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} (${DateFormat('EEEE').format(_selectedDate!)})',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Slot Selection (Dynamic)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Time Slot',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.access_time),
                      enabled: _availableTimeSlots.isNotEmpty,
                    ),
                    value: _selectedTimeSlot,
                    items: _availableTimeSlots.map<DropdownMenuItem<String>>((slot) {
                      return DropdownMenuItem<String>(
                        value: slot,
                        child: Text(slot),
                      );
                    }).toList(),
                    hint: Text(
                         _selectedDate == null 
                            ? 'Select Date first' 
                            : (_availableTimeSlots.isEmpty ? 'No slots available' : 'Select Slot')
                    ),
                    onChanged: (val) {
                      setState(() {
                        _selectedTimeSlot = val;
                      });
                    },
                  ),
                  if (_selectedDate != null && _availableTimeSlots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12),
                      child: Text(
                        'Doctor is not available on ${DateFormat('EEEE').format(_selectedDate!)}.',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),
                  
                  // Reason Input
                   TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Visit',
                      hintText: 'E.g., High fever, cold, checkup...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _handleBook,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirm Booking'),
                  ),
                ],
              ),
            ),
    );
  }
}
