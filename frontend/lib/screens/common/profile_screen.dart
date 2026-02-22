import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile; // Pass current user details
  const ProfileScreen({super.key, required this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _phoneController = TextEditingController();
  
  String? _currentImageUrl; // Stores the URL of the current profile image (from backend)
  XFile? _previewImage; // Stores the newly picked image file for preview
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if available (this logic depends on what is passed)
    // For now, assume userProfile usually has name/email/id.
    // We might need to fetch full profile again or just let user input.
    _currentImageUrl = widget.userProfile['profileImage'];
    _phoneController.text = widget.userProfile['phone'] ?? '';
    // _fetchProfile(); // No longer needed as we pre-fill from widget.userProfile
  }

  // Removed _fetchProfile as it's not used with the new logic

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _previewImage = image;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    
    try {
      String? finalImageUrl = _currentImageUrl;

      // 1. Upload new image if selected
      if (_previewImage != null) {
        // Upload logic using our new endpoint
        finalImageUrl = await _apiService.uploadFile(_previewImage!);
      }

      // 2. Update Profile with new URL and/or phone
      await _apiService.updateProfile(
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        profileImage: finalImageUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!')),
        );
        Navigator.pop(context); // Go back
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
    ImageProvider? avatarImage;
    if (_previewImage != null) {
      if (kIsWeb) {
        avatarImage = NetworkImage(_previewImage!.path); // XFile.path is a blob URL on web
      } else {
        avatarImage = FileImage(File(_previewImage!.path)); // XFile.path is a file path on mobile
      }
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_currentImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Picker
            Center(
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
             const SizedBox(height: 16),
             Text(
               'To update Name, Email or Specialization, please contact Admin.',
               style: GoogleFonts.poppins(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _isLoading ? null : _updateProfile,
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   backgroundColor: const Color(0xFF1E88E5)
                  ),
                 child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
             )
          ],
        ),
      ),
    );
  }
}
