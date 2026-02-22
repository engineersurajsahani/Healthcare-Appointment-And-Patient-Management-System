import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import 'find_doctor_screen.dart';
import 'medical_records_screen.dart';
import '../common/notifications_screen.dart';
import 'doctor_detail_screen.dart'; // We will create this next

class PatientDashboard extends StatefulWidget {
  final String userName;
  const PatientDashboard({super.key, required this.userName});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final ApiService _apiService = ApiService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _apiService.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if web/wide screen
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Custom drawer trigger if needed, or use standard
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
              backgroundImage: const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), // Placeholder
            ),
          )
        ],
      ),
      drawer: AppDrawer(userName: widget.userName, role: 'Patient'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero / Search Area
                  const SizedBox(height: 10),
                  Text(
                    "Let's find\nyour doctor",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A2A44),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search doctor...',
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                                  ),
                                  onSubmitted: (val) {
                                     Navigator.push(
                                       context,
                                       MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
                                     );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child:  IconButton(
                            icon: const Icon(Icons.filter_list, color: Color(0xFF0A2A44)),
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (c) => const FindDoctorScreen()));
                            },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Doctor Carousel
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                         final doc = _doctors[index];
                         return _buildDoctorCard(doc);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Categories Grid
                  Text(
                    "Categories",
                     style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A2A44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildCategoryCard(
                        title: 'My Appointments', 
                        price: 'View', 
                        color: Colors.white, 
                        width: isWide ? 300 : (MediaQuery.of(context).size.width - 64) / 2,
                        onTap: () => _showMyAppointments(context),
                      ),
                      _buildCategoryCard(
                         title: 'Specialist Visits', 
                         price: '~\$89', 
                         color: Colors.white,
                         width: isWide ? 300 : (MediaQuery.of(context).size.width - 64) / 2
                      ),
                       _buildCategoryCard(
                         title: 'Medical Tests', 
                         price: '~\$120', 
                         color: Colors.white,
                         width: isWide ? 300 : (MediaQuery.of(context).size.width - 64) / 2,
                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MedicalRecordsScreen()))
                      ),
                       _buildCategoryCard(
                         title: 'Therapeutic', 
                         price: '~\$55', 
                         color: const Color(0xFF0A2A44),
                         textColor: Colors.white,
                         width: isWide ? 300 : (MediaQuery.of(context).size.width - 64) / 2,
                         isDark: true
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildDoctorCard(dynamic doc) {
    // Random images just for the UI feel if user has no image
    // doc['profileImage'] might exist if we added it, otherwise we use placeholder
    final doctorImage =  'https://img.freepik.com/free-photo/portrait-smiling-handsome-male-doctor-man_171337-5055.jpg?t=st=1708453489~exp=1708457089~hmac=62174c3e80628292857476839352136458022791845184852504850849319808&w=1800';
    // If we had real images, we'd use doc['profileImage'] ?? doctorImage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doc)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F9), // Light blueish
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  doctorImage, 
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dr. ${doc['name']}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF0A2A44),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              doc['specialization'] ?? 'Specialist',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            // Icons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 _smallIcon(Icons.star, Colors.orange, '4.8'),
                 const SizedBox(width: 8),
                 _smallIcon(Icons.people, Colors.blue, '500+'),
              ],
            ),
             const SizedBox(height: 12),
             Align(
               alignment: Alignment.center,
               child: CircleAvatar(
                 backgroundColor: const Color(0xFF0A2A44),
                 radius: 18,
                 child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _smallIcon(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
         const SizedBox(width: 4),
         Text(text, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title, 
    required String price, 
    required Color color, 
    Color textColor = const Color(0xFF0A2A44),
    required double width,
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 140, // Square-ish
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
           boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
            ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Per session',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: isDark ? Colors.white : const Color(0xFFF5F7FA),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.arrow_outward, size: 16, color: isDark ? const Color(0xFF0A2A44) : Colors.black87),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showMyAppointments(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: _apiService.getAppointments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final appointments = snapshot.data ?? [];
                if (appointments.isEmpty) {
                   return const Center(child: Text('No appointments found.'));
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    final doctorName = appt['doctorId'] != null ? appt['doctorId']['name'] ?? 'Doctor' : 'Doctor';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(doctorName[0])),
                        title: Text('Dr. $doctorName'),
                        subtitle: Text('${appt['date'].toString().split('T')[0]} @ ${appt['timeSlot']}\nStatus: ${appt['status']}'),
                        isThreeLine: true,
                        trailing: (appt['status'] == 'Approved' || appt['status'] == 'Pending') 
                        ? IconButton(
                            icon: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                            onPressed: () async {
                              // Reminder logic
                              try {
                                  await _apiService.sendReminder(appt['_id']);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent to doctor')));
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                            },
                          )
                        : null,
                      ),
                    );
                  },
                );
              },
            );
          }
        );
      }
    );
  }
}
