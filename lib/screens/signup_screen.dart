import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/office_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Role-specific controllers
  final _deptController = TextEditingController();
  final _semesterController = TextEditingController();
  final _designationController = TextEditingController();
  
  UserRole _selectedRole = UserRole.student;
  List<OfficeModel> _offices = [];
  OfficeModel? _selectedOffice;
  
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    final offices = await AdminService().getAllOffices();
    if (mounted) setState(() => _offices = offices);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deptController.dispose();
    _semesterController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      // 1. Create the user model with all collected data
      final userModel = UserModel(
        uid: '', // Will be set by AuthService
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        department: _deptController.text.trim(),
        semester: _semesterController.text.trim(),
        designation: _designationController.text.trim(),
        office: _selectedOffice?.name,
      );

      // 2. Perform signup
      final result = await _authService.signUp(
        password: _passwordController.text.trim(),
        userModel: userModel,
      );

      // 3. If Admin, link them to the selected office
      if (result?.user != null && _selectedRole == UserRole.admin && _selectedOffice != null) {
        await DatabaseService().linkOfficerToOffice(result!.user!.uid, _selectedOffice!.id);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black45,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                    const SizedBox(height: 24),
                    Text(
                      'Select Your Role',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _roleButton('Student', UserRole.student),
                        const SizedBox(width: 8),
                        _roleButton('Faculty', UserRole.faculty),
                        const SizedBox(width: 8),
                        _roleButton('Admin', UserRole.admin),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRoleSpecificFields(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('SIGN UP', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Already have an account? Login',
                        style: GoogleFonts.inter(color: const Color(0xFF6750A4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificFields() {
    if (_selectedRole == UserRole.student) {
      return Column(
        children: [
          _buildTextField(_deptController, 'Department', Icons.school_outlined),
          const SizedBox(height: 16),
          _buildTextField(_semesterController, 'Semester', Icons.calendar_month_outlined),
        ],
      );
    } else if (_selectedRole == UserRole.admin) {
      return Column(
        children: [
          _buildTextField(_designationController, 'Designation', Icons.badge_outlined),
          const SizedBox(height: 16),
          DropdownButtonFormField<OfficeModel>(
            value: _selectedOffice,
            decoration: InputDecoration(
              labelText: 'Assigned Office',
              prefixIcon: const Icon(Icons.business_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _offices.map((office) {
              return DropdownMenuItem(value: office, child: Text(office.name));
            }).toList(),
            onChanged: (val) => setState(() => _selectedOffice = val),
          ),
        ],
      );
    } else if (_selectedRole == UserRole.faculty) {
      return Column(
        children: [
          _buildTextField(_deptController, 'Department', Icons.school_outlined),
          const SizedBox(height: 16),
          _buildTextField(_designationController, 'Designation', Icons.badge_outlined),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _roleButton(String label, UserRole role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6750A4) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
