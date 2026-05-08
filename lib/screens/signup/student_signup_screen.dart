import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../main.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  
  String? _selectedDept;
  String? _selectedSemester;

  final List<String> _departments = [
    'Art and Design',
    'Computer Science',
    'English',
    'Fashion Design',
    'Food and Nutrition',
    'Information Management',
    'Interior Design',
    'Psychology',
  ];

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final studentId = _studentIdController.text.trim();

      // Check if Student ID contains at least one number (redundant with validator but kept for extra safety)
      if (!studentId.contains(RegExp(r'[0-9]'))) {
        throw 'Student ID must contain at least one number.';
      }
      
      // Check if Student ID is already taken
      print('Checking if Student ID is unique...');
      bool isUnique = await db.isStudentIdUnique(studentId);
      if (!isUnique) {
        throw 'This Student ID is already registered.';
      }

      final userModel = UserModel(
        uid: '',
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: UserRole.student,
        department: _selectedDept,
        semester: _selectedSemester,
        studentId: studentId,
      );
      
      await _authService.signUp(
        password: _passwordController.text.trim(),
        userModel: userModel,
      );
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthChecker()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains(']') ? e.toString().split(']').last.trim() : e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Registration', style: GoogleFonts.outfit())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _buildTextField(
                _nameController, 
                'Full Name', 
                Icons.person_outline,
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                _studentIdController, 
                'Student ID', 
                Icons.badge_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your Student ID';
                  if (!val.contains(RegExp(r'[0-9]'))) return 'Must contain at least one number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
  
              // Department Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDept,
                decoration: InputDecoration(
                  labelText: 'Department',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDept = val),
                validator: (val) => val == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 16),
  
              // Semester Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _semesters.map((sem) {
                  return DropdownMenuItem(value: sem, child: Text('Semester $sem'));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSemester = val),
                validator: (val) => val == null ? 'Please select a semester' : null,
              ),
              const SizedBox(height: 16),
  
              _buildTextField(
                _emailController, 
                'Email', 
                Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your email';
                  if (!val.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password field with toggle
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter a password';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('REGISTER', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool obscure = false, String? Function(String?)? validator}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}
