enum UserRole { student, faculty, admin, viceChancellor }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  
  // Role-specific fields
  final String? department;
  final String? semester;
  final String? studentId;
  final String? facultyId;
  final String? officerId;
  final String? office;
  final String? designation;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.department,
    this.semester,
    this.studentId,
    this.facultyId,
    this.officerId,
    this.office,
    this.designation,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'department': department,
      'semester': semester,
      'studentId': studentId,
      'facultyId': facultyId,
      'officerId': officerId,
      'office': office,
      'designation': designation,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role']?.toString(),
        orElse: () => UserRole.student,
      ),
      department: map['department']?.toString(),
      semester: map['semester']?.toString(),
      studentId: map['studentId']?.toString(),
      facultyId: map['facultyId']?.toString(),
      officerId: map['officerId']?.toString(),
      office: map['office']?.toString(),
      designation: map['designation']?.toString(),
    );
  }
}
