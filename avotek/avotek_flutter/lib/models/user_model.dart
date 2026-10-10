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
  final String avoId;
  final String? username;

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
    this.avoId = '',
    this.username,
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
    String? avoId,
    String? username,
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
      avoId: avoId ?? this.avoId,
      username: username ?? this.username,
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
        'avo_id': avoId,
        'username': username,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawAvo = json['avo_id'] as String? ?? json['avoId'] as String?;
    final resolvedAvo = (rawAvo != null && rawAvo.trim().isNotEmpty)
        ? rawAvo.trim().toUpperCase()
        : (rawId.isNotEmpty
            ? 'AVO-${(rawId.hashCode.abs() % 90000 + 10000)}'
            : 'AVO-10001');

    final rawEmail = json['email'] as String? ?? '';
    final rawUsername = json['username'] as String? ??
        (rawEmail.contains('@') ? rawEmail.split('@').first : null);

    return UserModel(
      id: rawId,
      email: rawEmail,
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'Avotek User',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      kycStatus: json['kyc_status'] as String? ?? 'tier1',
      referralCode: json['referral_code'] as String? ?? resolvedAvo,
      referredBy: json['referred_by'] as String?,
      transactionPinHash: json['transaction_pin_hash'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      avoId: resolvedAvo,
      username: rawUsername,
    );
  }
}
