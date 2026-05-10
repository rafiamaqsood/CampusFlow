import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_request_model.dart';

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
          }

          if (activeTokens.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeTokens.length,
            itemBuilder: (context, index) {
              final token = activeTokens[index];
              return _buildTokenCard(token);
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

  Widget _buildTokenCard(AppointmentRequestModel token) {
    final isExpired = token.isExpired;
    final color = isExpired ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                token.tokenNumber ?? 'N/A',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token.studentName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Slot: ${token.timeSlot != null ? DateFormat('hh:mm a').format(token.timeSlot!) : 'N/A'}',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isExpired)
              const Icon(Icons.timer_off_outlined, color: Colors.red)
            else
              const Icon(Icons.timer_outlined, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
