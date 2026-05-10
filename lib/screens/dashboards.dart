import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import 'admin/request_queue_screen.dart';
import 'admin/active_tokens_screen.dart';

class StudentDashboard extends StatelessWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context, 'Student Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(user.name),
            const SizedBox(height: 32),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard('Request Token', Icons.confirmation_number_outlined, Colors.blue),
                _buildActionCard('Track Request', Icons.track_changes_outlined, Colors.orange),
                _buildActionCard('Office Times', Icons.access_time_outlined, Colors.green),
                _buildActionCard('My Profile', Icons.person_outline, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FacultyDashboard extends StatelessWidget {
  final UserModel user;
  const FacultyDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context, 'Faculty Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(user.name),
            const SizedBox(height: 32),
            _buildSectionTitle('Faculty Portal'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard('VC Availability', Icons.event_available_outlined, Colors.teal),
                _buildActionCard('My Meetings', Icons.groups_outlined, Colors.indigo),
                _buildActionCard('Dept. Status', Icons.business_outlined, Colors.deepOrange),
                _buildActionCard('Notifications', Icons.notifications_none_outlined, Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context, 'Admin Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(widget.user.name),
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('Office Management'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  'Manage Requests', 
                  Icons.queue_outlined, 
                  Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RequestQueueScreen(officer: widget.user)),
                  ),
                ),
                _buildActionCard(
                  'Active Tokens', 
                  Icons.confirmation_number_outlined, 
                  Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActiveTokensScreen(officerId: widget.user.uid)),
                  ),
                ),
                _buildActionCard('Office Stats', Icons.bar_chart_outlined, Colors.cyan),
                _buildActionCard('Settings', Icons.settings_outlined, Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                Text(
                  _getStatusText(widget.user.availabilityStatus),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          PopupMenuButton<AvailabilityStatus>(
            initialValue: widget.user.availabilityStatus,
            onSelected: (status) {
              _adminService.updateAvailability(widget.user.uid, widget.user.officerId ?? widget.user.uid, status);
            },
            itemBuilder: (context) => AvailabilityStatus.values.map((status) {
              return PopupMenuEntry<AvailabilityStatus>(
                value: status,
                child: Row(
                  children: [
                    _getStatusIcon(status),
                    const SizedBox(width: 8),
                    Text(_getStatusText(status)),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text('Change', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.inOffice: return 'In Office';
      case AvailabilityStatus.busy: return 'Busy';
      case AvailabilityStatus.away: return 'Away';
      case AvailabilityStatus.offDuty: return 'Off Duty';
    }
  }

  Widget _getStatusIcon(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.inOffice: return const Icon(Icons.check_circle, color: Colors.green);
      case AvailabilityStatus.busy: return const Icon(Icons.remove_circle, color: Colors.orange);
      case AvailabilityStatus.away: return const Icon(Icons.access_time_filled, color: Colors.amber);
      case AvailabilityStatus.offDuty: return const Icon(Icons.do_not_disturb_on, color: Colors.red);
    }
  }
}

class VCDashboard extends StatelessWidget {
  final UserModel user;
  const VCDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context, 'VC Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(user.name),
            const SizedBox(height: 32),
            _buildSectionTitle('University Oversight'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard('Global Status', Icons.public_outlined, Colors.indigo),
                _buildActionCard('Office Performance', Icons.speed_outlined, Colors.purple),
                _buildActionCard('Meeting Requests', Icons.mail_outline, Colors.green),
                _buildActionCard('Directives', Icons.assignment_outlined, Colors.brown),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Components
PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => AuthService().signOut(),
      ),
      const SizedBox(width: 8),
    ],
  );
}

Widget _buildWelcomeHeader(String name) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Hello,',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
      ),
      Text(
        name,
        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E)),
      ),
    ],
  );
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E)),
  );
}

Widget _buildActionCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
  return Card(
    elevation: 2,
    shadowColor: color.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
