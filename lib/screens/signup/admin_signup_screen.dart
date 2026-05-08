import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../main.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _officerIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedOffice;
  String? _selectedDesignation;

  final List<String> _offices = [
    'Examination Centre',
    'PR Office',
    'Registrar Office',
    'Transport Office',
  ];

  final List<String> _designations = [
    'Admin Officer',
    'Coordinator',
    'Office Assistant',
    'Supervisor',
  ];

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final officerId = _officerIdController.text.trim();

      // Extra check for numbers in ID
      if (!officerId.contains(RegExp(r'[0-9]'))) {
        throw 'Officer ID must contain at least one number.';
      }

      // Check if Officer ID is already taken
      print('Checking if Officer ID is unique...');
      bool isUnique = await db.isOfficerIdUnique(officerId);
      if (!isUnique) {
        throw 'This Officer ID is already registered.';
      }

      final userModel = UserModel(
        uid: '',
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: UserRole.admin,
        officerId: officerId,
        office: _selectedOffice,
        designation: _selectedDesignation,
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
      appBar: AppBar(title: Text('Admin Registration', style: GoogleFonts.outfit())),
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
                _officerIdController, 
                'Officer ID', 
                Icons.badge_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your Officer ID';
                  if (!val.contains(RegExp(r'[0-9]'))) return 'Must contain at least one number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
  
              // Office Dropdown
              DropdownButtonFormField<String>(
                value: _selectedOffice,
                decoration: InputDecoration(
                  labelText: 'Office Name',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _offices.map((office) {
                  return DropdownMenuItem(value: office, child: Text(office));
                }).toList(),
                onChanged: (val) => setState(() => _selectedOffice = val),
                validator: (val) => val == null ? 'Please select an office' : null,
              ),
              const SizedBox(height: 16),
  
              // Designation Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                decoration: InputDecoration(
                  labelText: 'Designation',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _designations.map((desig) {
                  return DropdownMenuItem(value: desig, child: Text(desig));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDesignation = val),
                validator: (val) => val == null ? 'Please select a designation' : null,
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
