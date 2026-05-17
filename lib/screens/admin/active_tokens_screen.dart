import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_request_model.dart';
import '../../services/admin_service.dart';

class ActiveTokensScreen extends StatelessWidget {
  final String officerId;
  const ActiveTokensScreen({super.key, required this.officerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Active Tokens', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('appointment_requests')
            .orderByChild('officerId')
            .equalTo(officerId)
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<AppointmentRequestModel> activeTokens = [];
          if (snapshot.hasData && snapshot.data!.snapshot.exists) {
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              final request = AppointmentRequestModel.fromMap(Map<String, dynamic>.from(value));
              if (request.status == RequestStatus.accepted) {
                activeTokens.add(request);
              }
            });
            // Sort by time slot (earliest first)
            activeTokens.sort((a, b) => (a.timeSlot ?? DateTime.now()).compareTo(b.timeSlot ?? DateTime.now()));
          }

          if (activeTokens.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeTokens.length,
            itemBuilder: (context, index) {
              final token = activeTokens[index];
              return _buildTokenCard(context, token);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No active tokens',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(BuildContext context, AppointmentRequestModel token) {
    final isExpired = token.isExpired;
    final color = isExpired ? Colors.red : Colors.blue;
    final adminService = AdminService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    token.tokenNumber ?? 'N/A',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(token.studentName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        'Time Slot: ${token.timeSlot != null ? DateFormat('hh:mm a').format(token.timeSlot!) : 'N/A'}',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isExpired)
                  const Tooltip(message: 'Expired', child: Icon(Icons.timer_off_outlined, color: Colors.red))
                else
                  const Tooltip(message: 'Active', child: Icon(Icons.timer_outlined, color: Colors.green)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                if (isExpired)
                   Expanded(child: Text('This token has expired', style: GoogleFonts.inter(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600))),
                if (!isExpired && token.expiryTime != null)
                   Expanded(child: Text('Expires at ${DateFormat('hh:mm a').format(token.expiryTime!)}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12))),
                if (!isExpired && token.expiryTime == null)
                   const Spacer(),

                ElevatedButton(
                  onPressed: () => _showCompletionDialog(context, token, adminService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Complete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, AppointmentRequestModel token, AdminService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session?'),
        content: Text('Are you sure you want to mark the session for ${token.studentName} as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await service.completeRequest(token.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
