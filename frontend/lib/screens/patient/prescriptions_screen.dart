import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      final records = await _apiService.getMyMedicalRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No prescriptions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    final doctorName = record['doctorId'] != null ? record['doctorId']['name'] : 'Unknown';
                    final date = DateTime.parse(record['createdAt']);
                    
                    return Card(
                      color: Colors.blue[50],
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.medication, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Dr. $doctorName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Spacer(),
                                Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text('MEDICINES:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                            const SizedBox(height: 8),
                            Text(
                              record['prescription'],
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            if (record['notes'] != null && record['notes'].toString().isNotEmpty)
                              Text(
                                'Note: ${record['notes']}',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
