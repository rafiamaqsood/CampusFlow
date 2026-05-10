import 'package:firebase_database/firebase_database.dart';
import '../models/appointment_request_model.dart';
import '../models/user_model.dart';
import '../models/office_model.dart';

class AdminService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // --- Admin/Officer Operations ---

  // Get stream of pending requests for a specific officer
  Stream<List<AppointmentRequestModel>> getPendingRequests(String officerId) {
    return _db.ref('appointment_requests')
        .orderByChild('officerId')
        .equalTo(officerId)
        .onValue
        .map((event) {
      final List<AppointmentRequestModel> requests = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final request = AppointmentRequestModel.fromMap(
            Map<String, dynamic>.from(value),
          );
          if (request.status == RequestStatus.pending) {
            requests.add(request);
          }
        });
      }
      // Sort by creation time (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Accept request and generate token
  Future<void> acceptRequest({
    required String requestId,
    required DateTime timeSlot,
    required String tokenNumber,
  }) async {
    final expiryTime = timeSlot.add(const Duration(minutes: 30)); // 30 min validity
    await _db.ref('appointment_requests/$requestId').update({
      'status': RequestStatus.accepted.name,
      'timeSlot': timeSlot.toIso8601String(),
      'tokenNumber': tokenNumber,
      'expiryTime': expiryTime.toIso8601String(),
    });
  }

  // Reject request with reason
  Future<void> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    await _db.ref('appointment_requests/$requestId').update({
      'status': RequestStatus.rejected.name,
      'rejectionReason': reason,
    });
  }

  // Update officer availability
  Future<void> updateAvailability(String officerId, String profileKey, AvailabilityStatus status) async {
    // Update in both users node and role-specific node
    await _db.ref('users/$officerId').update({
      'availabilityStatus': status.name,
    });
    
    await _db.ref('admins/$profileKey').update({
      'availabilityStatus': status.name,
      'lastStatusUpdate': DateTime.now().toIso8601String(),
    });
  }

  // --- Office Discovery (For Students) ---

  // Fetch all offices
  Future<List<OfficeModel>> getAllOffices() async {
    final snapshot = await _db.ref('offices').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((v) => OfficeModel.fromMap(Map<String, dynamic>.from(v))).toList();
    }
    return [];
  }

  // Fetch officers in an office
  Future<List<UserModel>> getOfficersByOffice(String officeName) async {
    // This is a bit tricky with RTDB flat structure, but we can query admins by office field
    final snapshot = await _db.ref('admins')
        .orderByChild('office')
        .equalTo(officeName)
        .get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((v) => UserModel.fromMap(Map<String, dynamic>.from(v))).toList();
    }
    return [];
  }
}
