enum UserRole { student, faculty, admin, viceChancellor }

enum AvailabilityStatus { inOffice, busy, away, offDuty }

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
  final String? office; // e.g., "Accounts Office"
  final String? designation;
  final List<String>? handledRequestTypes; // e.g., ["Fee Installments", "Fine Waiver"]
  final AvailabilityStatus availabilityStatus;
  final DateTime? lastStatusUpdate;

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
    this.handledRequestTypes,
    this.availabilityStatus = AvailabilityStatus.offDuty,
    this.lastStatusUpdate,
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
      'handledRequestTypes': handledRequestTypes,
      'availabilityStatus': availabilityStatus.name,
      'lastStatusUpdate': lastStatusUpdate?.toIso8601String(),
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
      handledRequestTypes: map['handledRequestTypes'] != null 
          ? List<String>.from(map['handledRequestTypes']) 
          : null,
      availabilityStatus: AvailabilityStatus.values.firstWhere(
        (e) => e.name == map['availabilityStatus']?.toString(),
        orElse: () => AvailabilityStatus.offDuty,
      ),
      lastStatusUpdate: map['lastStatusUpdate'] != null 
          ? DateTime.tryParse(map['lastStatusUpdate'].toString()) 
          : null,
    );
  }
}
