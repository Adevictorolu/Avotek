String avotekIdFor(String userId) {
  final clean = userId.trim();
  if (clean.isEmpty) return 'AVO10001';
  // Compute deterministic, memorable 5-digit number from user ID
  var hash = 0;
  for (var i = 0; i < clean.length; i++) {
    hash = (31 * hash + clean.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  final number = 10000 + (hash % 90000);
  return 'AVO$number';
}

String avotekReferralLinkFor(Uri baseUri, String referralCode) {
  final base = baseUri.host == 'localhost' || baseUri.host == '127.0.0.1'
      ? Uri.parse('https://adevictorolu.github.io/Avotek/')
      : baseUri;
  return Uri(
    scheme: base.scheme,
    userInfo: base.userInfo,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: base.path,
    fragment: '/register?ref=${Uri.encodeComponent(referralCode.trim())}',
  ).toString();
}

class UserModel {
  static const Set<String> adminEmails = {
    'ademolavictor869@gmail.com',
  };

  static bool isAdminEmail(String? email) {
    final normalized = (email ?? '').trim().toLowerCase();
    return normalized.isNotEmpty && adminEmails.contains(normalized);
  }

  static String avoIdFor(String userId) => avotekIdFor(userId);

  final String id;
  final String email;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String kycStatus;
  final String referralCode;
  final String? referredBy;
  final String? transactionPinHash;
  final String role;
  final DateTime createdAt;
  final String avoId;
  final String? username;
  final String? nin;
  final int kycTier;

  bool get isAdmin => isAdminEmail(email);
  bool get isTier2Verified =>
      kycStatus == 'verified' || kycStatus == 'tier2' || kycTier >= 2;
  bool get isTier1Verified =>
      isTier2Verified ||
      kycStatus == 'tier1' ||
      (phone.trim().isNotEmpty && phone != 'Not configured');

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
    this.role = 'user',
    required this.createdAt,
    this.avoId = '',
    this.username,
    this.nin,
    this.kycTier = 1,
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
    String? role,
    DateTime? createdAt,
    String? avoId,
    String? username,
    String? nin,
    int? kycTier,
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
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avoId: avoId ?? this.avoId,
      username: username ?? this.username,
      nin: nin ?? this.nin,
      kycTier: kycTier ?? this.kycTier,
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
    'role': role,
    'created_at': createdAt.toIso8601String(),
    'avo_id': avoId,
    'username': username,
    'nin': nin,
    'kyc_tier': kycTier,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawAvo = json['avo_id'] as String? ?? json['avoId'] as String?;
    final resolvedAvo = (rawAvo != null && rawAvo.trim().isNotEmpty)
        ? rawAvo.trim().toUpperCase()
        : (rawId.isNotEmpty ? avotekIdFor(rawId) : 'AVO10001');

    final rawEmail = json['email'] as String? ?? '';
    final rawUsername =
        json['username'] as String? ??
        (rawEmail.contains('@') ? rawEmail.split('@').first : null);
    final isPrivileged = isAdminEmail(rawEmail);
    final status = json['kyc_status'] as String? ?? 'tier1';
    final rawTier = (json['kyc_tier'] as num?)?.toInt();
    final phoneVal = json['phone'] as String? ?? '';
    final ninVal = json['nin'] as String?;
    final tier = rawTier ??
        (status == 'verified' || status == 'tier2'
            ? 2
            : (phoneVal.trim().isNotEmpty ? 1 : 0));

    return UserModel(
      id: rawId,
      email: rawEmail,
      name:
          json['name'] as String? ??
          json['full_name'] as String? ??
          'Avotek User',
      phone: phoneVal,
      avatarUrl: json['avatar_url'] as String?,
      kycStatus: status,
      referralCode: json['referral_code'] as String? ?? resolvedAvo,
      referredBy: json['referred_by'] as String?,
      transactionPinHash: json['transaction_pin_hash'] as String?,
      role: isPrivileged ? 'admin' : 'user',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      avoId: resolvedAvo,
      username: rawUsername,
      nin: ninVal,
      kycTier: tier,
    );
  }
}
