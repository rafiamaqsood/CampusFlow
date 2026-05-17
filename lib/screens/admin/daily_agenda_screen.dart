import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_request_model.dart';
import '../../services/admin_service.dart';

class DailyAgendaScreen extends StatelessWidget {
  final String officerId;
  const DailyAgendaScreen({super.key, required this.officerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Today\'s Schedule', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppointmentRequestModel>>(
        stream: AdminService().getOfficeSchedule(officerId, DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final schedule = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final request = schedule[index];
              return _buildScheduleItem(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildScheduleItem(AppointmentRequestModel request) {
    final timeStr = DateFormat('hh:mm a').format(request.timeSlot!);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Text(
                timeStr,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.blue[100],
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.studentName,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.requestType,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 14, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${request.studentDept} • Sem ${request.studentSemester}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.blue[300]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No appointments for today',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
