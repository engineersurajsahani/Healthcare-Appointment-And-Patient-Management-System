import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://localhost:5001/api'; 
  // NOTE: For Android Emulator use 'http://10.0.2.2:5001/api'
  // NOTE: For iOS Simulator use 'http://127.0.0.1:5001/api' or 'http://localhost:5001/api'

  static String? _token;

  // Set token after login
  void setToken(String token) {
    _token = token;
  }

  // Headers
  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['msg'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      );

      print('Register Response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = error['msg'] ?? 'Registration failed';
        
        if (error['errors'] != null && (error['errors'] as List).isNotEmpty) {
          errorMessage = error['errors'][0]['msg'];
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Doctors
  Future<List<dynamic>> getDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Book Appointment
  Future<void> bookAppointment({
    required String doctorId,
    required String date,
    required String timeSlot,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
        body: jsonEncode({
          'doctorId': doctorId,
          'date': date,
          'timeSlot': timeSlot,
          'reason': reason,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to book appointment');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Appointments
  Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  
  /// Update Appointment Status
  Future<void> updateAppointmentStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Add Medical Record (Completes the appointment)
  Future<void> addMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String prescription,
    required String notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medical-records'),
        headers: headers,
        body: jsonEncode({
          'appointmentId': appointmentId,
          'diagnosis': diagnosis,
          'prescription': prescription,
          'notes': notes,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to save record');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get My Medical Records (Patient)
  Future<List<dynamic>> getMyMedicalRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medical-records/my-records'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load records');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get My Documents (Patient)
  Future<List<dynamic>> getMyDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medical-records/documents'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Delete Document (Patient)
  Future<void> deleteDocument(String documentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/medical-records/documents/$documentId'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  
  /// Get System Stats (Admin)
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Users by Role (Admin)
  Future<List<dynamic>> getUsersByRole(String role) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users?role=$role'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Toggle User Access (Admin)
  Future<void> toggleUserAccess(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/toggle-access'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Doctor Profile
  Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctors/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Update Availability
  Future<void> updateAvailability(List<Map<String, dynamic>> availability) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/doctors/availability'),
        headers: headers,
        body: jsonEncode({'availability': availability}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update availability');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Audit Logs (Admin)
  Future<List<dynamic>> getAuditLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/audit-logs'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get Notifications
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Mark Notification Read
  Future<void> markNotificationRead(String id) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: headers,
      );
    } catch (e) {
      // Ignore error for read receipt
    }
  }

  /// Update Profile
  Future<void> updateProfile({String? profileImage, String? phone}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: jsonEncode({
          if (profileImage != null) 'profileImage': profileImage,
          if (phone != null) 'phone': phone,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Upload File
  Future<String> uploadFile(dynamic file) async {
    // NOTE: 'file' should be a XFile (from image_picker) or File (dart:io) depending on platform.
    // For web compatibility we often use XFile but MultipartRequest needs bytes or path.
    // Assuming file is XFile for cross-platform support.
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      
      // If web, we might need to read bytes
      // if (!kIsWeb) request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      // Generic approach for XFile
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: file.name
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['filePath']; // Returns full URL
      } else {
        throw Exception('File upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Approve Doctor (Admin)
  Future<void> approveDoctor(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/doctors/$userId/approve'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to approve doctor');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  /// Upload Document (Patient)
  Future<void> uploadDocument(String title, String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medical-records/upload'),
        headers: headers,
        body: jsonEncode({'title': title, 'url': url}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to upload document');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  /// Send Reminder
  Future<void> sendReminder(String appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/$appointmentId/remind'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to send reminder');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
