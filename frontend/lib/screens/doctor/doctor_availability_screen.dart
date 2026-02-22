import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  // Structure: { 'Monday': ['09:00', '10:00'], 'Tuesday': [] }
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  Map<String, List<String>> _availability = {};
  
  final List<String> _possibleSlots = [
    '09:00 - 09:30', '09:30 - 10:00',
    '10:00 - 10:30', '10:30 - 11:00',
    '11:00 - 11:30', '11:30 - 12:00',
    '02:00 - 02:30', '02:30 - 03:00',
    '03:00 - 03:30', '03:30 - 04:00',
    '04:00 - 04:30', '04:30 - 05:00',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize empty
    for (var day in _days) {
      _availability[day] = [];
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getDoctorProfile();
      if (profile['availability'] != null) {
        final List<dynamic> serverData = profile['availability'];
        setState(() {
          for (var item in serverData) {
            if (_availability.containsKey(item['day'])) {
               _availability[item['day']] = List<String>.from(item['slots']);
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    try {
      // Convert map to list for API
      List<Map<String, dynamic>> apiData = [];
      _availability.forEach((day, slots) {
        if (slots.isNotEmpty) {
          apiData.add({'day': day, 'slots': slots});
        }
      });

      await _apiService.updateAvailability(apiData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability Updated Successfully!')),
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
  
  void _toggleSlot(String day, String slot) {
    setState(() {
      if (_availability[day]!.contains(slot)) {
        _availability[day]!.remove(slot);
      } else {
        _availability[day]!.add(slot);
        _availability[day]!.sort(); // Keep sorted nicely
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAvailability,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                return _buildDayCard(day);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAvailability,
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildDayCard(String day) {
    bool hasSlots = _availability[day]!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: hasSlots ? Theme.of(context).primaryColor : Colors.black87
          ),
        ),
        subtitle: Text(
           hasSlots ? '${_availability[day]!.length} slots active' : 'Unavailable',
           style: TextStyle(color: hasSlots ? Colors.green : Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _possibleSlots.map((slot) {
                final isSelected = _availability[day]!.contains(slot);
                return FilterChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (_) => _toggleSlot(day, slot),
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[800],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
