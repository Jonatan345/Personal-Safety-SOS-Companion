class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  final String id;
  final String name;
  final String phoneNumber;
}

class EmergencyContactDraft {
  const EmergencyContactDraft({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;
}
