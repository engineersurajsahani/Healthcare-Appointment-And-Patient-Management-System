import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class DoctorDetailScreen extends StatefulWidget {
  final dynamic doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final ApiService _apiService = ApiService();
  
  // State for Booking
  int _selectedDateIndex = 1; // Default to '24 Sunday'
  String _selectedTime = '8:30'; 
  bool _isBooking = false;

  final List<Map<String, String>> _dates = [
    {'day': '22', 'weekday': 'Friday'},
    {'day': '23', 'weekday': 'Saturday'},
    {'day': '24', 'weekday': 'Sunday'},
    {'day': '25', 'weekday': 'Monday'},
    {'day': '26', 'weekday': 'Tuesday'},
  ];

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    final size = MediaQuery.of(context).size;
    
    // Doctor Image
    final doctorImage = 'https://img.freepik.com/free-photo/portrait-smiling-handsome-male-doctor-man_171337-5055.jpg?t=st=1708453489~exp=1708457089~hmac=62174c3e80628292857476839352136458022791845184852504850849319808&w=1800';

    return Scaffold(
      backgroundColor: const Color(0xFFA1C6D9), // Base blueish color
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8AB6C9), Color(0xFFCDE4EE)],
              ),
            ),
          ),
          
          // Content
          Column(
            children: [
              const SizedBox(height: 60),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0A2A44), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(Icons.favorite_border, color: Color(0xFF0A2A44)),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Doctor Profile Section
              Center(
                child: Column(
                  children: [
                    // Rating tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Color(0xFF0A2A44), size: 14),
                          const SizedBox(width: 4),
                          Text('4.6', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0A2A44))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Image
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: NetworkImage(doctorImage),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Dr. ${widget.doctor['name']}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A2A44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.doctor['qualification'] ?? 'MBBS, MD'}\n${widget.doctor['specialization'] ?? 'Specialist'}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4A6A84),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleButton(Icons.info_outline, 'Details', true),
                  const SizedBox(width: 16),
                  _circleButton(Icons.call, '', false),
                  const SizedBox(width: 16),
                  _circleButton(Icons.videocam_outlined, '', false),
                  const SizedBox(width: 16),
                  _circleButton(Icons.chat_bubble_outline, '', false),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Stats
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem(Icons.access_time, '${widget.doctor['experience'] ?? 2} Years', 'Experience'),
                    _statItem(Icons.people_outline, '3.5k+', 'Patients'),
                    _statItem(Icons.star_border, '2.8k+', 'Reviews'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bottom Sheet for Booking
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Date Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Date', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                          Row(
                            children: [
                              const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                              Text(' January ', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0A2A44))),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _dates.length,
                          itemBuilder: (context, index) {
                            final isActive = index == _selectedDateIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDateIndex = index),
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFB5E0EA) : Colors.transparent, // Active light blue
                                  borderRadius: BorderRadius.circular(16),
                                  border: isActive ? null : Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dates[index]['day']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0A2A44),
                                      ),
                                    ),
                                    Text(
                                      _dates[index]['weekday']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select Time', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                      ),
                      const SizedBox(height: 16),
                      // Mock Time Slider
                      SizedBox(
                        height: 50,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _timeTick('7:30', false),
                              _timeTick('8:00', false),
                              _timeTick('8:30', true),
                              _timeTick('9:00', false),
                              _timeTick('9:30', false),
                              _timeTick('10:00', false),
                              _timeTick('10:30', false),
                            ],
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isBooking ? null : _bookSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2A44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: _isBooking 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Book Session',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, String label, bool isPill) {
    if (isPill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFB5E0EA).withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0A2A44), size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: const Color(0xFF0A2A44), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF0A2A44), size: 22),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A6A84), size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0A2A44))),
        Text(label, style: GoogleFonts.poppins(color: const Color(0xFF4A6A84), fontSize: 12)),
      ],
    );
  }

  Widget _timeTick(String time, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            height: isSelected ? 24 : 12,
            width: 3,
            color: isSelected ? const Color(0xFF0A2A44) : Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            time, 
            style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF0A2A44) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      ),
    );
  }

  Future<void> _bookSession() async {
    setState(() => _isBooking = true);
    try {
      // Simulate/Existing Booking Logic
      await _apiService.bookAppointment(
        doctorId: widget.doctor['_id'] ?? widget.doctor['userId'], // Ensure ID
        date: '2026-02-${_dates[_selectedDateIndex]['day']}', // Simple mock date construction
        timeSlot: _selectedTime,
        reason: 'General Consultation' // Default reason for quick booking
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment Booked Successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
