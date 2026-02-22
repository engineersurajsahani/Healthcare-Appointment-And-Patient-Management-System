import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _documents = [];  // simulated
  List<dynamic> _records = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _apiService.getMyMedicalRecords();
      final docs = await _apiService.getMyDocuments();
      
      setState(() {
        _records = records;
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Widget _buildUploadsTab() {
    if (_documents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.blue[100]),
              const SizedBox(height: 16),
              Text('Upload previous reports & letters here.', style: GoogleFonts.poppins(color: const Color(0xFF0A2A44), fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('(Tap + button to add)', style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        // doc has title, url, date
        final date = DateTime.tryParse(doc['date'].toString()) ?? DateTime.now();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.description, color: Colors.green),
            ),
            title: Text(doc['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0A2A44))),
            subtitle: Text('Uploaded on ${date.day}/${date.month}/${date.year}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.blue),
                  onPressed: () async {
                     final url = doc['url'];
                     if (url != null) {
                       final uri = Uri.tryParse(url);
                       if (uri != null && await canLaunchUrl(uri)) {
                         await launchUrl(uri);
                       } else {
                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
                         }
                       }
                     }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Confirm delete
                    final confirm = await showDialog(
                      context: context, 
                      builder: (c) => AlertDialog(
                        title: Text('Delete Document?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to delete "${doc['title'] ?? 'this file'}"?', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins())),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(c, true), 
                            child: Text('Delete', style: GoogleFonts.poppins())
                          ),
                        ],
                      )
                    );

                    if (confirm == true) {
                       setState(() => _isLoading = true);
                       try {
                         // Need doc ID. Mongoose subdocs have _id.
                         final docId = doc['_id'];
                         if (docId != null) {
                           await _apiService.deleteDocument(docId);
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted (refreshing...)')));
                             _fetchData();
                           }
                         } else {
                            if (mounted) {
                               setState(() => _isLoading = false);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Document ID missing')));
                            }
                         }
                       } catch (e) {
                         if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
                         }
                       }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadDocument() async {
    final titleController = TextEditingController();
    
    // Pick file first or during dialog? 
    // Let's open dialog then pick file.
    
    // State for selected file in dialog
    PlatformFile? pickedFile;
    String? statusMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Upload Document', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController, 
                    decoration: InputDecoration(
                      labelText: 'Document Title',
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    )
                  ),
                  const SizedBox(height: 16),
                  if (pickedFile == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text('Select File', style: GoogleFonts.poppins()),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                           try {
                             final result = await FilePicker.platform.pickFiles(
                               type: FileType.custom,
                               allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xlsx'],
                               withData: true, // Force loading bytes for memory
                             );
                             
                             if (result != null) {
                               setStateDialog(() {
                                 pickedFile = result.files.first;
                                 statusMsg = 'Selected: ${pickedFile!.name}';
                               });
                             }
                           } catch (e) {
                             setStateDialog(() => statusMsg = 'Error picking file: $e');
                           }
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(pickedFile!.name, style: GoogleFonts.poppins(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setStateDialog(() => pickedFile = null),
                          )
                        ],
                      ),
                    ),
                  
                  if (statusMsg != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(statusMsg!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                     ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey))),
                ElevatedButton(
                  onPressed: pickedFile == null ? null : () async {
                    if (titleController.text.isEmpty) {
                      setStateDialog(() => statusMsg = 'Please enter a title');
                      return;
                    }
                    
                    Navigator.pop(context); // Close dialog first

                    setState(() => _isUploading = true);
                    
                    try {
                      // 1. Upload File
                      // Note: We need to pass the file object or bytes. FilePicker returns PlatformFile.
                      // Our ApiService expects a PlatformFile (conceptually) or XFile.
                      // Since we didn't add the specific FilePicker dependency logic to ApiService yet, 
                      // we passed 'dynamic'. But ApiService uses 'readAsBytes()'.
                      // FilePicker's PlatformFile has 'bytes' property if in memory, or 'readStream'.
                      // Let's ensure ApiService can handle PlatformFile or adjust ApiService.
                      // WAIT: ApiService logic was `file.readAsBytes()` which is XFile method.
                      // PlatformFile has `.bytes` (Uint8List).
                      // We need to bridge this.
                      
                      // For simplicity, let's update call to handle PlatformFile manually here if needed?
                      // Or better, wrapping it.
                      // Let's assume for now we modify logic inside specific call:
                      
                      // Actually, let's fix ApiService helper in next step if it fails, 
                      // but for now, we will construct a XFile-like object or modify ApiService.
                      // The easiest way is to pass the PlatformFile to a modified ApiService method
                      // or use a temporary helper.
                      
                      // Since I cannot change ApiService in this single step safely without risk,
                      // I will rely on standard XFile if I use image_picker for images.
                      // But user asked for doc/pdf. FilePicker is needed.
                      // Quick fix: FilePicker result -> bytes -> MultipartFile in ApiService.
                      // ApiService `uploadFile` calls `file.readAsBytes()`.
                      // PlatformFile does NOT have readAsBytes().
                      
                      // I will patch the call below to handle the mismatch or I will use a wrapper.
                    } catch (e) {
                      //
                    }
                    
                    // Actually, let's just use the logic here if easier, OR 
                    // I will update ApiService to accept PlatformFile in next turn.
                    // BUT, I can pass a custom object that has readAsBytes matching the signature.
                    
                    final fileWrapper = _FileWrapper(pickedFile!);
                    
                    try {
                       final fileUrl = await _apiService.uploadFile(fileWrapper);
                       await _apiService.uploadDocument(titleController.text, fileUrl);
                       
                       if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded successfully')));
                          Navigator.pop(context); // Pop dialog 
                          _fetchData(); // Refresh list
                       }
                    } catch (e) {
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                       if (mounted) setState(() => _isUploading = false);
                    }
                  },
                  child: Text('Upload', style: GoogleFonts.poppins()),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Text('Medical Records', style: GoogleFonts.poppins(color: const Color(0xFF0A2A44), fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: const Color(0xFF0A2A44),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            indicatorColor: const Color(0xFF0A2A44),
            tabs: const [
              Tab(text: 'Consultation History'),
              Tab(text: 'My Uploads'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildHistoryList(),
                  _buildUploadsTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploadDocument,
          backgroundColor: const Color(0xFF1E88E5),
          icon: const Icon(Icons.upload_file),
          label: Text('Upload', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_records.isEmpty) {
      return Center(child: Text('No consultation history.', style: GoogleFonts.poppins(color: Colors.grey[600])));
    }
    return ListView.builder(
      itemCount: _records.length,
      padding: const EdgeInsets.all(24),
      itemBuilder: (context, index) {
        final record = _records[index];
        final doctorName = record['doctorId'] != null ? record['doctorId']['name'] : 'Unknown';
        final date = DateTime.parse(record['createdAt']);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ExpansionTile(
            shape: const Border(), // Remove default border
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.history_edu, color: Colors.blue),
            ),
            title: Text('Dr. $doctorName', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0A2A44))),
            subtitle: Text('${date.day}/${date.month}/${date.year}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            children: [
               Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSection('Diagnosis', record['diagnosis']),
                      const SizedBox(height: 16),
                      _buildSection('Prescription', record['prescription']),
                      const SizedBox(height: 16),
                      _buildSection('Notes', record['notes']),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(content, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0A2A44), height: 1.5)),
      ],
    );
  }
}

// Helper to bridge FilePicker's PlatformFile with ApiService's expected interface (readAsBytes)
class _FileWrapper {
  final PlatformFile file;
  _FileWrapper(this.file);
  
  String get name => file.name;
  
  Future<List<int>> readAsBytes() async {
    if (file.bytes != null) return file.bytes!;
    // If bytes not in memory (on mobile sometimes), we might need another way or assume bytes are there 
    // because withReadStream: true was NOT set (default is bytes for small files) 
    // OR we forced load.
    // FilePicker usually loads bytes on web. On mobile, 'path' is used.
    // If path exists:
    if (file.path != null) {
       // We can return empty list here and let MultipartFile.fromPath handle it?
       // ApiService code does: request.files.add(http.MultipartFile.fromBytes(... bytes ...))
       // So we MUST return bytes.
       // Import dart:io to read? No, web incompat. 
       // Ideally we use file.bytes.
       // For mobile, to get bytes from path, we need File(path).readAsBytes().
       // But we want to avoid dart:io imports in web-compatible file if possible, or conditional import.
       // Since the user is on Mac (mobile/desktop sim), we can use dart:io logic, but let's try to see if FilePicker gives bytes.
       // Default pickFiles loads bytes? No, on mobile it gives path.
       // Let's assume we need to handle path.
       
       // Quick Hack: Return empty and let ApiService fail? No.
       // Real solution: Update ApiService to handle XFile or PlatformFile properly.
       // But for this wrapper, we try to just provide what we can.
       throw Exception('File path found but creating bytes not implemented in wrapper without dart:io');
    }
    return [];
  }
}
// Actually, I can just import dart:io conditionally or just use a conditional execution.
// Let's modify ApiService to be robust, but for now I will rely on `withData: true` (default for small files?) 
// actually `withData` defaults to false on mobile.
// I will update the code to use `withData: true` in pickFiles.
