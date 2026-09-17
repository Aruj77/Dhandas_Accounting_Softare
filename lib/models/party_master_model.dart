class PartyMasterModel {
  final String name;
  final String gstin;
  final String group;

  const PartyMasterModel({
    required this.name,
    required this.gstin,
    required this.group,
  });

  String get displayName => gstin.isNotEmpty ? '$name [$gstin]' : name;
}