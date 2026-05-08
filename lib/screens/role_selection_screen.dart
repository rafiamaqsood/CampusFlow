import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'signup/student_signup_screen.dart';
import 'signup/faculty_signup_screen.dart';
import 'signup/admin_signup_screen.dart';
import 'signup/vc_signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _dbService = DatabaseService();
  bool _vcExists = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVCStatus();
  }

  Future<void> _checkVCStatus() async {
    try {
      bool exists = await _dbService.doesVCExist();
      if (mounted) {
        setState(() {
          _vcExists = exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Your Role', style: GoogleFonts.outfit())),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Join CampusFlow',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select your role to continue',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              _buildRoleCard(
                context,
                'Student',
                'Register as a university student',
                Icons.school_outlined,
                const Color(0xFF6750A4),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSignupScreen())),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                'Faculty',
                'For professors and department heads',
                Icons.person_search_outlined,
                const Color(0xFF006B5B),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultySignupScreen())),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                'Admin',
                'Office administrators and staff',
                Icons.admin_panel_settings_outlined,
                const Color(0xFF904A41),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSignupScreen())),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                'Vice Chancellor',
                _vcExists ? 'VC is already registered' : 'University management access',
                Icons.account_balance_outlined,
                _vcExists ? Colors.grey : const Color(0xFF4A635D),
                _vcExists ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VCSignupScreen())),
                isDisabled: _vcExists,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isDisabled = false,
  }) {
    return Card(
      elevation: isDisabled ? 0 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDisabled ? Colors.grey[200] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(isDisabled ? 0.1 : 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: isDisabled ? Colors.grey : Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDisabled ? Colors.grey : Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}
