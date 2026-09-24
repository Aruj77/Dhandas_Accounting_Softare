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
  final String email;
  final String contactPerson;
  final String accountNumber;
  final String ifsc;

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
    this.email = '',
    this.contactPerson = '',
    this.accountNumber = '',
    this.ifsc = '',
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
      email: json['email'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      ifsc: json['ifsc'] as String? ?? '',
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
      'email': email,
      'contactPerson': contactPerson,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
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
    String? email,
    String? contactPerson,
    String? accountNumber,
    String? ifsc,
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
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
    );
  }
}