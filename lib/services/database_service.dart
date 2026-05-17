import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/office_model.dart';

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
      // Use the Firebase Auth UID as the primary key for all records
      String primaryKey = user.uid;

      // 1. Store a master record for role lookup and PK reference
      await _db.ref('users/${user.uid}').set({
        'role': user.role.name,
        'email': user.email,
        'name': user.name,
        'profileKey': primaryKey, 
      });

      // 2. Store detailed info in separate role-specific node
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

  // Fetch office by ID
  Future<OfficeModel?> getOfficeById(String officeId) async {
    final snapshot = await _db.ref('offices/$officeId').get();
    if (snapshot.exists) {
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      if (map['id'] == null) map['id'] = officeId;
      return OfficeModel.fromMap(map);
    }
    return null;
  }

  // Fetch all offices
  Future<List<OfficeModel>> getAllOffices() async {
    final snapshot = await _db.ref('offices').get();
    if (snapshot.exists) {
      final value = snapshot.value;
      final List<OfficeModel> offices = [];
      if (value is Map) {
        value.forEach((key, val) {
          final map = Map<String, dynamic>.from(val);
          if (map['id'] == null) map['id'] = key.toString();
          offices.add(OfficeModel.fromMap(map));
        });
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] != null) {
            final map = Map<String, dynamic>.from(value[i]);
            if (map['id'] == null) map['id'] = i.toString();
            offices.add(OfficeModel.fromMap(map));
          }
        }
      }
      return offices;
    }
    return [];
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

  // --- Office Operations ---

  Future<void> linkOfficerToOffice(String officerUid, String officeId) async {
    try {
      final ref = _db.ref('offices/$officeId/officerIds');
      final snapshot = await ref.get();
      List<String> officerIds = [];
      
      if (snapshot.exists) {
        final value = snapshot.value;
        if (value is List) {
          officerIds = List<String>.from(value.where((e) => e != null));
        } else if (value is Map) {
          officerIds = value.values.map((v) => v.toString()).toList();
        }
      }
      
      if (!officerIds.contains(officerUid)) {
        officerIds.add(officerUid);
        await ref.set(officerIds);
      }
    } catch (e) {
      print('Error linking officer to office: $e');
    }
  }
}
