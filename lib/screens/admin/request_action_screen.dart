import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_request_model.dart';
import '../../services/admin_service.dart';

class RequestActionScreen extends StatefulWidget {
  final AppointmentRequestModel request;
  const RequestActionScreen({super.key, required this.request});

  @override
  State<RequestActionScreen> createState() => _RequestActionScreenState();
}

class _RequestActionScreenState extends State<RequestActionScreen> {
  final _adminService = AdminService();
  final _reasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<bool> _checkConflicts(DateTime slotTime) async {
    final schedule = await _adminService.getOfficeSchedule(widget.request.officerId, slotTime).first;
    for (var req in schedule) {
      if (req.timeSlot != null) {
        final diff = req.timeSlot!.difference(slotTime).inMinutes.abs();
        if (diff < 15) return true; // 15-minute buffer
      }
    }
    return false;
  }

  Future<void> _handleAccept() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final slotTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      
      setState(() => _isProcessing = true);
      
      try {
        final hasConflict = await _checkConflicts(slotTime);
        
        if (hasConflict) {
          setState(() => _isProcessing = false);
          final bool? proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Schedule Conflict'),
              content: const Text('This time slot is very close to another appointment. Do you want to proceed anyway?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go Back')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Proceed Anyway'),
                ),
              ],
            ),
          );
          
          if (proceed != true) return;
          setState(() => _isProcessing = true);
        }

        // Generate a simple token based on timestamp
        final token = "TK-${now.millisecondsSinceEpoch.toString().substring(9)}";

        await _adminService.acceptRequest(
          requestId: widget.request.id,
          timeSlot: slotTime,
          tokenNumber: token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request Accepted. Token: $token')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejection:', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Missing documents',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_reasonController.text.trim().isEmpty) return;
              
              final messenger = ScaffoldMessenger.of(this.context);
              final navigator = Navigator.of(this.context);
              
              Navigator.pop(context); // Close dialog
              setState(() => _isProcessing = true);
              
              try {
                await _adminService.rejectRequest(
                  requestId: widget.request.id,
                  reason: _reasonController.text.trim(),
                );
                if (mounted) navigator.pop();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Process Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleAccept,
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STUDENT INFORMATION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _infoRow(Icons.person_outline, 'Name', widget.request.studentName),
          if (widget.request.studentDept != null)
            _infoRow(Icons.school_outlined, 'Department', widget.request.studentDept!),
          if (widget.request.studentSemester != null)
            _infoRow(Icons.calendar_view_day_outlined, 'Semester', widget.request.studentSemester!),
          const Divider(height: 32),
          Text('REQUEST DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _infoRow(Icons.description_outlined, 'Type', widget.request.requestType),
          _infoRow(
            Icons.info_outline, 
            'Student Reason', 
            (widget.request.studentReason == null || widget.request.studentReason!.isEmpty) 
              ? 'Not provided' 
              : widget.request.studentReason!
          ),
          _infoRow(Icons.calendar_today_outlined, 'Submitted', DateFormat('MMM dd, yyyy - hh:mm a').format(widget.request.createdAt)),
          const Divider(height: 32),
          Text('SYSTEM REFERENCE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _infoRow(Icons.fingerprint, 'Student UID', widget.request.studentId),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
