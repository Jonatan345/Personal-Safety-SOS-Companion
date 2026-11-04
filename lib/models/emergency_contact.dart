class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final phoneNumber = json['phoneNumber'];
    if (id is! String || name is! String || phoneNumber is! String) {
      throw const FormatException('Stored emergency contact is incomplete.');
    }
    return EmergencyContact(id: id, name: name, phoneNumber: phoneNumber);
  }

  final String id;
  final String name;
  final String phoneNumber;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
      };
}

class EmergencyContactDraft {
  const EmergencyContactDraft({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;
}
