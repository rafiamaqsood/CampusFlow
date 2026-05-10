class OfficeModel {
  final String id;
  final String name;
  final String block; // e.g., "Admin Block"
  final String floor;
  final List<String> officerIds; // UIDs of officers assigned to this office

  OfficeModel({
    required this.id,
    required this.name,
    required this.block,
    required this.floor,
    required this.officerIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'block': block,
      'floor': floor,
      'officerIds': officerIds,
    };
  }

  factory OfficeModel.fromMap(Map<String, dynamic> map) {
    return OfficeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      block: map['block'] ?? '',
      floor: map['floor'] ?? '',
      officerIds: List<String>.from(map['officerIds'] ?? []),
    );
  }
}
