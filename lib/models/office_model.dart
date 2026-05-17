class OfficeModel {
  final String id;
  final String name;
  final String block; // e.g., "Admin Block"
  final String floor;
  final List<String> officerIds; // UIDs of officers assigned to this office
  final String? announcement;
  final DateTime? announcementUpdatedAt;

  OfficeModel({
    required this.id,
    required this.name,
    required this.block,
    required this.floor,
    required this.officerIds,
    this.announcement,
    this.announcementUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'block': block,
      'floor': floor,
      'officerIds': officerIds,
      'announcement': announcement,
      'announcementUpdatedAt': announcementUpdatedAt?.toIso8601String(),
    };
  }

  factory OfficeModel.fromMap(Map<String, dynamic> map) {
    final officerIdsData = map['officerIds'];
    List<String> officerIds = [];
    
    if (officerIdsData is List) {
      officerIds = List<String>.from(officerIdsData.where((e) => e != null));
    } else if (officerIdsData is Map) {
      officerIds = officerIdsData.values.map((v) => v.toString()).toList();
    }

    return OfficeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      block: map['block'] ?? '',
      floor: map['floor'] ?? '',
      officerIds: officerIds,
      announcement: map['announcement'],
      announcementUpdatedAt: map['announcementUpdatedAt'] != null 
        ? DateTime.tryParse(map['announcementUpdatedAt']) 
        : null,
    );
  }
}
