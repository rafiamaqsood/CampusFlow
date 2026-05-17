import 'package:firebase_database/firebase_database.dart';
import '../models/appointment_request_model.dart';
import '../models/user_model.dart';
import '../models/office_model.dart';
import 'database_service.dart';

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

  // Stream a specific office by name
  Stream<OfficeModel?> getOfficeByName(String officeName) {
    return _db.ref('offices').onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        for (var entry in data.entries) {
          if (entry.value['name'] == officeName) {
            final map = Map<String, dynamic>.from(entry.value);
            if (map['id'] == null) map['id'] = entry.key;
            return OfficeModel.fromMap(map);
          }
        }
      }
      return null;
    });
  }

  // Get historical requests (completed, rejected)
  Stream<List<AppointmentRequestModel>> getRequestHistory(String officerId) {
    return _db.ref('appointment_requests')
        .orderByChild('officerId')
        .equalTo(officerId)
        .onValue
        .map((event) {
      final List<AppointmentRequestModel> requests = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        data.forEach((key, value) {
          final request = AppointmentRequestModel.fromMap(Map<String, dynamic>.from(value));
          if (request.status == RequestStatus.completed || 
              request.status == RequestStatus.rejected ||
              request.status == RequestStatus.expired) {
            requests.add(request);
          }
        });
      }
      // Sort by latest first
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  // Get accepted requests for a specific day (Schedule)
  Stream<List<AppointmentRequestModel>> getOfficeSchedule(String officerId, DateTime date) {
    return _db.ref('appointment_requests')
        .orderByChild('officerId')
        .equalTo(officerId)
        .onValue
        .map((event) {
      final List<AppointmentRequestModel> schedule = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        data.forEach((key, value) {
          final request = AppointmentRequestModel.fromMap(Map<String, dynamic>.from(value));
          if (request.status == RequestStatus.accepted && request.timeSlot != null) {
            // Check if it's the same day
            if (request.timeSlot!.year == date.year && 
                request.timeSlot!.month == date.month && 
                request.timeSlot!.day == date.day) {
              schedule.add(request);
            }
          }
        });
      }
      // Sort by time
      schedule.sort((a, b) => a.timeSlot!.compareTo(b.timeSlot!));
      return schedule;
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

  // Update office announcement
  Future<void> updateOfficeAnnouncement(String officeName, String? announcement) async {
    // 1. Find the office(s) with this name
    final snapshot = await _db.ref('offices').get();
    if (snapshot.exists) {
      final value = snapshot.value;
      if (value is Map) {
        for (var entry in value.entries) {
          if (entry.value['name'] == officeName) {
            await _db.ref('offices/${entry.key}').update({
              'announcement': announcement,
              'announcementUpdatedAt': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    }
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
    return DatabaseService().getAllOffices();
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

  // Fetch office by ID
  Future<OfficeModel?> getOfficeById(String officeId) async {
    return DatabaseService().getOfficeById(officeId);
  }

  // Mark request as completed
  Future<void> completeRequest(String requestId) async {
    await _db.ref('appointment_requests/$requestId').update({
      'status': RequestStatus.completed.name,
    });
  }
}
