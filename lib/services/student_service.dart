import 'package:firebase_database/firebase_database.dart';
import '../models/office_model.dart';
import '../models/user_model.dart';
import '../models/appointment_request_model.dart';

class StudentService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream of a specific office's metadata
  Stream<OfficeModel?> getOfficeStream(String officeId) {
    return _db.ref('offices/$officeId').onValue.map((event) {
      if (event.snapshot.exists) {
        final map = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (map['id'] == null) map['id'] = officeId;
        return OfficeModel.fromMap(map);
      }
      return null;
    });
  }

  // Stream of offices that have at least one registered officer
  Stream<List<OfficeModel>> getOffices() {
    // We listen to the root to get both 'admins' and 'offices' efficiently in one stream
    // or we can use a CombineLatest approach. For simplicity and real-time updates:
    return _db.ref().onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final adminsSnapshot = snapshot.child('admins');
      final officesSnapshot = snapshot.child('offices');

      // 1. Identify all unique office names that have officers
      final Map<String, int> activeOfficeCounts = {};
      if (adminsSnapshot.exists) {
        final adminsData = adminsSnapshot.value;
        if (adminsData is Map) {
          adminsData.forEach((k, v) {
            final officeName = v['office']?.toString();
            if (officeName != null && officeName.isNotEmpty) {
              activeOfficeCounts[officeName] = (activeOfficeCounts[officeName] ?? 0) + 1;
            }
          });
        }
      }

      // 2. Get the predefined office metadata
      final Map<String, OfficeModel> predefinedOffices = {};
      if (officesSnapshot.exists) {
        final officesData = officesSnapshot.value;
        if (officesData is Map) {
          officesData.forEach((key, val) {
            final office = OfficeModel.fromMap(Map<String, dynamic>.from(val)..['id'] = key);
            predefinedOffices[office.name] = office;
          });
        }
      }

      // 3. Build the final list: Only offices with at least one officer
      final List<OfficeModel> finalOffices = [];
      activeOfficeCounts.forEach((officeName, count) {
        if (predefinedOffices.containsKey(officeName)) {
          finalOffices.add(predefinedOffices[officeName]!);
        } else {
          // If an admin registered for an office not in our 'offices' node, 
          // create a placeholder so students can still see it.
          finalOffices.add(OfficeModel(
            id: 'temp_${officeName.hashCode}',
            name: officeName,
            block: 'General Block',
            floor: 'Unknown',
            officerIds: [], 
          ));
        }
      });

      // Sort alphabetically by name
      finalOffices.sort((a, b) => a.name.compareTo(b.name));
      return finalOffices;
    });
  }

  // Get officers in an office by querying their office name
  Stream<List<UserModel>> getOfficersByOfficeName(String officeName) {
    return _db.ref('admins')
        .orderByChild('office')
        .equalTo(officeName)
        .onValue
        .map((event) {
      final List<UserModel> officers = [];
      if (event.snapshot.exists) {
        final value = event.snapshot.value;
        if (value is Map) {
          value.forEach((key, val) {
            officers.add(UserModel.fromMap(Map<String, dynamic>.from(val)));
          });
        } else if (value is List) {
          value.where((e) => e != null).forEach((val) {
            officers.add(UserModel.fromMap(Map<String, dynamic>.from(val)));
          });
        }
      }
      return officers;
    });
  }

  // Submit a new request
  Future<void> submitRequest(AppointmentRequestModel request) async {
    await _db.ref('appointment_requests/${request.id}').set(request.toMap());
  }

  // Get a unique key for a new request
  String generateRequestId() {
    return _db.ref('appointment_requests').push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
  }
}
