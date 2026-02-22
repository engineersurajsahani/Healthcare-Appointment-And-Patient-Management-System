import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import 'consultation_screen.dart';
import 'doctor_availability_screen.dart'; // Import
import '../common/notifications_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final String userName;
  const DoctorDashboard({super.key, required this.userName});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final ApiService _apiService = ApiService();
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _apiService.getAppointments();
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _apiService.updateAppointmentStatus(id, status);
      _fetchAppointments(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, 
        title: Row(
          children: [
            Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )),
            Text(
              'CliniQ',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen()));
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          )
        ],
      ),
      drawer: AppDrawer(userName: widget.userName, role: 'Doctor'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          'Dr. ${widget.userName}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildStatBadge('Today', '${_appointments.length}'),
                            const SizedBox(width: 16),
                            // Manage Schedule Button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DoctorAvailabilityScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFF1E88E5), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Schedule',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF1E88E5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Upcoming Appointments',
                    style: GoogleFonts.poppins(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A2A44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _appointments.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments scheduled yet.',
                                style: GoogleFonts.poppins(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _appointments.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final appt = _appointments[index];
                            final patientName = appt['patientId'] != null 
                                ? appt['patientId']['name'] 
                                : 'Unknown Patient';
                             final patientPhone = appt['patientId'] != null 
                                ? appt['patientId']['phone'] 
                                : 'N/A';
                            final date = DateTime.parse(appt['date']);
                            final reason = appt['reason'] ?? 'No reason provided';
                            
                            // Parse time slot better if needed, for now just string
                            final timeSlot = appt['timeSlot'];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                   BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50, height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: Text(
                                                patientName[0].toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFF1E88E5),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(patientName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0A2A44))),
                                              Text(patientPhone, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          timeSlot,
                                          style: GoogleFonts.poppins(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Reason for Visit:', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text(reason, style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF0A2A44), fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 20),
                                  
                                  if (appt['status'] == 'Booked' || appt['status'] == 'Pending')
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _updateStatus(appt['_id'], 'Cancelled'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              side: BorderSide(color: Colors.grey[300]!)
                                            ),
                                            child: Text('Decline', style: GoogleFonts.poppins(color: Colors.grey[700])),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateStatus(appt['_id'], 'Approved'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1E88E5),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: Text('Accept', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (appt['status'] == 'Approved')
                                      Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ConsultationScreen(
                                                      appointmentId: appt['_id'],
                                                      patientName: patientName,
                                                    ),
                                                  ),
                                                ).then((_) => _fetchAppointments()); // Refresh after return
                                              },
                                              icon: const Icon(Icons.medical_services, color: Colors.white, size: 18),
                                              label: Text('Start Consultation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2E7D32), // Green
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (appt['reminded'] != true)
                                          SizedBox(
                                            width: double.infinity,
                                            child: TextButton.icon( // Changed from Outlined for softer look
                                              onPressed: () async {
                                                try {
                                                  await _apiService.sendReminder(appt['_id']);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent to patient')));
                                                  }
                                                  _fetchAppointments();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.notifications_active_outlined, size: 18),
                                              label: Text('Send Reminder', style: GoogleFonts.poppins()),
                                            ),
                                          )
                                        ],
                                      )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Status: ${appt['status']}',
                                        style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
