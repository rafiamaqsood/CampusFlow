enum RequestStatus { pending, accepted, rejected, completed, expired }

class AppointmentRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String officerId;
  final String officerName;
  final String requestType;
  final RequestStatus status;
  final String? rejectionReason;
  final String? tokenNumber;
  final DateTime? timeSlot;
  final DateTime? expiryTime;
  final DateTime createdAt;

  AppointmentRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.officerId,
    required this.officerName,
    required this.requestType,
    required this.status,
    this.rejectionReason,
    this.tokenNumber,
    this.timeSlot,
    this.expiryTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'officerId': officerId,
      'officerName': officerName,
      'requestType': requestType,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'tokenNumber': tokenNumber,
      'timeSlot': timeSlot?.toIso8601String(),
      'expiryTime': expiryTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppointmentRequestModel.fromMap(Map<String, dynamic> map) {
    return AppointmentRequestModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      officerId: map['officerId'] ?? '',
      officerName: map['officerName'] ?? '',
      requestType: map['requestType'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      tokenNumber: map['tokenNumber'],
      timeSlot: map['timeSlot'] != null ? DateTime.tryParse(map['timeSlot']) : null,
      expiryTime: map['expiryTime'] != null ? DateTime.tryParse(map['expiryTime']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }
}
