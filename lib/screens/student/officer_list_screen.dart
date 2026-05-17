import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:campusflow/models/office_model.dart';
import 'package:campusflow/models/user_model.dart';
import 'package:campusflow/services/student_service.dart';
import 'package:campusflow/screens/student/request_token_screen.dart';

class OfficerListScreen extends StatelessWidget {
  final OfficeModel office;
  const OfficerListScreen({super.key, required this.office});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(office.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<OfficeModel?>(
        stream: StudentService().getOfficeStream(office.id),
        builder: (context, officeSnapshot) {
          final currentOffice = officeSnapshot.data ?? office;
          
          return Column(
            children: [
              if (currentOffice.announcement != null && currentOffice.announcement!.isNotEmpty)
                _buildAnnouncementBanner(currentOffice.announcement!, currentOffice.announcementUpdatedAt),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: StudentService().getOfficersByOfficeName(office.name),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final officers = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: officers.length,
                      itemBuilder: (context, index) {
                        final officer = officers[index];
                        return _buildOfficerCard(context, officer, currentOffice);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildAnnouncementBanner(String text, DateTime? updatedAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(bottom: BorderSide(color: Colors.red[100]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_rounded, color: Colors.red[700], size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OFFICE ALERT',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[900], letterSpacing: 1.2),
                    ),
                    if (updatedAt != null)
                      Text(
                        'Posted ${DateFormat('hh:mm a').format(updatedAt)}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.red[300]),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.red[800], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(BuildContext context, UserModel officer, OfficeModel currentOffice) {
    final statusColor = _getStatusColor(officer.availabilityStatus);
    final statusText = _getStatusText(officer.availabilityStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestTokenScreen(officer: officer, office: currentOffice)
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      officer.name[0],
                      style: GoogleFonts.outfit(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(officer.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      officer.designation ?? 'Officer', 
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: statusColor
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.inOffice: return Colors.green;
      case AvailabilityStatus.busy: return Colors.orange;
      case AvailabilityStatus.away: return Colors.amber;
      case AvailabilityStatus.offDuty: return Colors.red;
    }
  }

  String _getStatusText(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.inOffice: return 'Available';
      case AvailabilityStatus.busy: return 'Busy';
      case AvailabilityStatus.away: return 'Away';
      case AvailabilityStatus.offDuty: return 'Off Duty';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No officers assigned', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
