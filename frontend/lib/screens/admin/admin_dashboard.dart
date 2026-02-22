import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../common/notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String userName;
  const AdminDashboard({super.key, required this.userName});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _stats;
  List<dynamic> _doctors = [];
  List<dynamic> _patients = [];
  List<dynamic> _logs = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _apiService.getSystemStats();
      final doctors = await _apiService.getUsersByRole('doctor');
      final patients = await _apiService.getUsersByRole('patient');
      final logs = await _apiService.getAuditLogs(); 

      if (mounted) {
        setState(() {
          _stats = stats;
          _doctors = doctors;
          _patients = patients;
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAccess(String userId) async {
    try {
      await _apiService.toggleUserAccess(userId);
      _loadData(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User access updated')),
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
      backgroundColor: const Color(0xFFF5F7FA),
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
              'CliniQ Admin',
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
              child: const Icon(Icons.admin_panel_settings, color: Colors.grey),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0A2A44),
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF0A2A44),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Doctors'),
            Tab(text: 'Patients'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      drawer: AppDrawer(userName: widget.userName, role: 'Admin'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
            _buildOverviewTab(),
            _buildUserListTab(_doctors, isDoctor: true),
            _buildUserListTab(_patients, isDoctor: false),
            _buildAuditLogsTab(), 
          ],
        ),
    );
  }

  Widget _buildAuditLogsTab() {
    if (_logs.isEmpty) return _emptyState('No audit logs found');
    return ListView.separated(
      itemCount: _logs.length,
      padding: const EdgeInsets.all(24),
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final user = log['userId'] != null ? log['userId']['name'] : 'Unknown';
        final role = log['userId'] != null ? log['userId']['role'] : '';
        final date = DateTime.parse(log['timestamp']);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.history, color: Colors.grey[600], size: 20),
            ),
            title: Text(log['action'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0A2A44))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$user ($role)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                Text('${date.day}/${date.month} ${date.hour}:${date.minute}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
            trailing: Text(log['ipAddress'] ?? 'IP N/A', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Overview", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0A2A44))),
          const SizedBox(height: 20),
          _buildStatCard(
            'Total Doctors',
            _stats?['doctors']?.toString() ?? '0',
            Icons.medical_services,
            const Color(0xFF1E88E5), // Blue
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Patients',
            _stats?['patients']?.toString() ?? '0',
            Icons.people,
            const Color(0xFF43A047), // Green
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Appointments',
            _stats?['appointments']?.toString() ?? '0',
            Icons.calendar_today,
            const Color(0xFFFB8C00), // Orange
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
         boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A2A44),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTab(List<dynamic> users, {required bool isDoctor}) {
    if (users.isEmpty) return _emptyState('No users found');
    return ListView.separated(
      itemCount: users.length,
      padding: const EdgeInsets.all(24),
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        final isActive = user['isActive'] ?? true;

        return Container(
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              child: Icon(
                isDoctor ? Icons.medical_services : Icons.person,
                color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                size: 20,
              ),
            ),
            title: Text(user['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF0A2A44))),
            subtitle: Text(user['email'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDoctor && (user['approvedByAdmin'] == false))
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.blue),
                    tooltip: 'Approve Doctor',
                    onPressed: () => _approveDoctor(user['_id']),
                  ),
                Switch(
                  value: isActive,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) => _toggleAccess(user['_id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.poppins(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Future<void> _approveDoctor(String userId) async {
    try {
      await _apiService.approveDoctor(userId);
      _loadData(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor Approved Successfully')),
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
}
