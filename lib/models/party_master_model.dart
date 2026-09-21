class PartyMasterModel {
  final String name;
  final String gstin;
  final String group;
  final String country;
  final String state;
  final String pincode;
  final String address;
  final String aadhaar;
  final String mobile;

  String get displayName => name;
  
  const PartyMasterModel({
    this.name = '',
    this.gstin = '',
    this.group = '',
    this.country = 'India',
    this.state = '',
    this.pincode = '',
    this.address = '',
    this.aadhaar = '',
    this.mobile = '',
  });

  factory PartyMasterModel.fromJson(Map<String, dynamic> json) {
    return PartyMasterModel(
      name: json['name'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      group: json['group'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      address: json['address'] as String? ?? '',
      aadhaar: json['aadhaar'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gstin': gstin,
      'group': group,
      'country': country,
      'state': state,
      'pincode': pincode,
      'address': address,
      'aadhaar': aadhaar,
      'mobile': mobile,
    };
  }

  PartyMasterModel copyWith({
    String? name,
    String? gstin,
    String? group,
    String? country,
    String? state,
    String? pincode,
    String? address,
    String? aadhaar,
    String? mobile,
  }) {
    return PartyMasterModel(
      name: name ?? this.name,
      gstin: gstin ?? this.gstin,
      group: group ?? this.group,
      country: country ?? this.country,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      address: address ?? this.address,
      aadhaar: aadhaar ?? this.aadhaar,
      mobile: mobile ?? this.mobile,
    );
  }
}