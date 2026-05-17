import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/office_model.dart';
import '../../models/user_model.dart';
import '../../models/appointment_request_model.dart';
import '../../services/student_service.dart';
import '../../services/database_service.dart';

class RequestTokenScreen extends StatefulWidget {
  final UserModel officer;
  final OfficeModel office;
  const RequestTokenScreen({super.key, required this.officer, required this.office});

  @override
  State<RequestTokenScreen> createState() => _RequestTokenScreenState();
}

class _RequestTokenScreenState extends State<RequestTokenScreen> {
  final _studentService = StudentService();
  final _dbService = DatabaseService();
  final _typeController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _typeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_typeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify request type'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch student data for name/id and additional info
      final masterData = await _dbService.getUserInfo(user.uid);
      final profileKey = masterData?['profileKey'] ?? user.uid;
      
      // Get role-specific data (department, semester)
      final studentModel = await _dbService.getUserData(profileKey, UserRole.student);

      final request = AppointmentRequestModel(
        id: _studentService.generateRequestId(),
        studentId: profileKey,
        studentName: studentModel?.name ?? 'Student',
        studentDept: studentModel?.department,
        studentSemester: studentModel?.semester,
        officerId: widget.officer.officerId ?? widget.officer.uid,
        officerName: widget.officer.name,
        requestType: _typeController.text.trim(),
        studentReason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _studentService.submitRequest(request);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text(
              'Your request has been submitted. You will be notified once the officer assigns a slot.'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to OfficerList
                  Navigator.pop(context); // Back to OfficeList
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('New Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 32),
                Text(
                  'REQUEST DETAILS', 
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey
                  )
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Request Type', 
                  'e.g., Fee Installment, Document Signing', 
                  _typeController
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Reason (Optional)', 
                  'Provide a brief reason for your visit', 
                  _reasonController, 
                  maxLines: 3
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Submit Request', 
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.officer.name, 
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                Text(
                  widget.office.name, 
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ],
    );
  }
}
