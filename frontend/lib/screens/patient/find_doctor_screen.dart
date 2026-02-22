import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../patient/book_appointment_screen.dart'; // To navigate to booking

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _allDoctors = [];
  List<dynamic> _filteredDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _apiService.getDoctors();
      setState(() {
        _allDoctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterDoctors(String query) {
    if (query.isEmpty) {
      setState(() => _filteredDoctors = _allDoctors);
      return;
    }

    final lowerQuery = query.toLowerCase();
    
    // Simple logic to suggest doctor based on symptom
    // e.g. "heart" -> Cardiology, "child" -> Pediatrics
    String targetSpecialization = '';
    
    if (lowerQuery.contains('heart') || lowerQuery.contains('chest')) {
      targetSpecialization = 'Cardiology';
    } else if (lowerQuery.contains('skin') || lowerQuery.contains('rash')) {
      targetSpecialization = 'Dermatology';
    } else if (lowerQuery.contains('child') || lowerQuery.contains('baby') || lowerQuery.contains('fever')) {
      targetSpecialization = 'Pediatrics'; // Fever often general or peds
    } else if (lowerQuery.contains('bone') || lowerQuery.contains('fracture')) {
      targetSpecialization = 'Orthopedics';
    }

    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final name = doctor['name'].toString().toLowerCase();
        final specialization = doctor['specialization'].toString().toLowerCase();
        
        bool matchesName = name.contains(lowerQuery);
        bool matchesSpec = specialization.contains(lowerQuery);
        bool matchesSymptom = targetSpecialization.isNotEmpty && 
                              specialization.contains(targetSpecialization.toLowerCase());

        return matchesName || matchesSpec || matchesSymptom;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name, Specialization or Symptom',
                hintText: 'e.g. Heart pain, Pediatrics...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterDoctors,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? const Center(child: Text('No doctors found matching your query.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColorLight,
                                child: Text(doctor['name'][0].toUpperCase()),
                              ),
                              title: Text(
                                'Dr. ${doctor['name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor['specialization'] ?? 'General',
                                    style: TextStyle(color: Theme.of(context).primaryColor),
                                  ),
                                  Text('Experience: ${doctor['experience'] ?? 0} years'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Navigate to Book Appointment with this doctor selected would be ideal
                                  // For now, just go to general booking
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: const Size(60, 32),
                                ),
                                child: const Text('Book'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
