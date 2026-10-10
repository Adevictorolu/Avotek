class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String kycStatus;
  final String referralCode;
  final String? referredBy;
  final String? transactionPinHash;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.avatarUrl,
    this.kycStatus = 'tier1',
    this.referralCode = '',
    this.referredBy,
    this.transactionPinHash,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    String? kycStatus,
    String? referralCode,
    String? referredBy,
    String? transactionPinHash,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      kycStatus: kycStatus ?? this.kycStatus,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      transactionPinHash: transactionPinHash ?? this.transactionPinHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'kyc_status': kycStatus,
        'referral_code': referralCode,
        'referred_by': referredBy,
        'transaction_pin_hash': transactionPinHash,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? json['full_name'] as String? ?? 'Avotek User',
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        kycStatus: json['kyc_status'] as String? ?? 'tier1',
        referralCode: json['referral_code'] as String? ?? '',
        referredBy: json['referred_by'] as String?,
        transactionPinHash: json['transaction_pin_hash'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
