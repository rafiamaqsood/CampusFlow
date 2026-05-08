import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // --- User Profile Operations ---

  // Check if a Vice Chancellor already exists
  Future<bool> doesVCExist() async {
    final snapshot = await _db.ref('viceChancellors').get();
    return snapshot.exists && snapshot.children.isNotEmpty;
  }

  // Check if a Student ID is already taken
  Future<bool> isStudentIdUnique(String studentId) async {
    final snapshot = await _db.ref('students/$studentId').get();
    return !snapshot.exists;
  }

  // Check if a Faculty ID is already taken
  Future<bool> isFacultyIdUnique(String facultyId) async {
    final snapshot = await _db.ref('faculty/$facultyId').get();
    return !snapshot.exists;
  }

  // Check if an Officer ID is already taken
  Future<bool> isOfficerIdUnique(String officerId) async {
    final snapshot = await _db.ref('admins/$officerId').get();
    return !snapshot.exists;
  }

  // Save user profile in Realtime Database
  Future<void> saveUserProfile(UserModel user) async {
    try {
      // 1. Determine the primary key to use for the detailed record
      String primaryKey;
      if (user.role == UserRole.student && user.studentId != null) {
        primaryKey = user.studentId!;
      } else if (user.role == UserRole.faculty && user.facultyId != null) {
        primaryKey = user.facultyId!;
      } else if (user.role == UserRole.admin && user.officerId != null) {
        primaryKey = user.officerId!;
      } else {
        primaryKey = user.uid;
      }

      // 2. Store a master record for role lookup and PK reference
      await _db.ref('users/${user.uid}').set({
        'role': user.role.name,
        'email': user.email,
        'name': user.name,
        'profileKey': primaryKey, // Points to the ID used in the role-specific node
      });

      // 3. Store detailed info in separate role-specific node using the PK
      String rolePath = _getRolePath(user.role);
      await _db.ref('$rolePath/$primaryKey').set(user.toMap());
      
      print('User profile saved to Realtime DB at path: $rolePath/$primaryKey');
    } catch (e) {
      print('Error saving user profile to Realtime DB: $e');
      rethrow;
    }
  }

  // Get user profile info from master node
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final snapshot = await _db.ref('users/$uid').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Get user profile from role-specific node
  Future<UserModel?> getUserData(String profileKey, UserRole role) async {
    String rolePath = _getRolePath(role);
    final snapshot = await _db.ref('$rolePath/$profileKey').get();
    if (snapshot.exists) {
      return UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  String _getRolePath(UserRole role) {
    switch (role) {
      case UserRole.student: return 'students';
      case UserRole.faculty: return 'faculty';
      case UserRole.admin: return 'admins';
      case UserRole.viceChancellor: return 'viceChancellors';
    }
  }

  // --- Future Workflow Operations (Placeholders) ---
  // (Updated to use Realtime DB refs)
  
  Future<void> requestToken({required String studentUid, required String officeName}) async {
    await _db.ref('tokens').push().set({
      'studentUid': studentUid,
      'officeName': officeName,
      'timestamp': ServerValue.timestamp,
      'status': 'pending',
    });
  }
}
