import 'package:firebase_database/firebase_database.dart';
import '../models/office_model.dart';

class SeedData {
  static Future<void> seedOffices() async {
    final List<OfficeModel> offices = [
      OfficeModel(
        id: 'off_001',
        name: 'Accounts Office',
        block: 'Admin Block',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_002',
        name: 'Registrar Office',
        block: 'Admin Block',
        floor: '1st Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_003',
        name: 'IT Helpdesk',
        block: 'CS Block',
        floor: '2nd Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_004',
        name: 'Student Affairs',
        block: 'Academic Block',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_005',
        name: 'Transport Office',
        block: 'Main Gate',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_006',
        name: 'Library Office',
        block: 'Library Block',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_007',
        name: 'Examination Dept',
        block: 'Admin Block',
        floor: '2nd Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_008',
        name: 'Admissions Office',
        block: 'Admin Block',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_009',
        name: 'Sports Department',
        block: 'Sports Complex',
        floor: 'Ground Floor',
        officerIds: [],
      ),
      OfficeModel(
        id: 'off_010',
        name: 'Security Office',
        block: 'Main Gate',
        floor: 'Ground Floor',
        officerIds: [],
      ),
    ];

    final DatabaseReference ref = FirebaseDatabase.instance.ref('offices');
    for (var office in offices) {
      await ref.child(office.id).set(office.toMap());
    }
    print('Sample offices seeded successfully!');
  }
}
