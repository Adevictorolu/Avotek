/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class User implements _i1.SerializableModel {
  User._({
    this.id,
    required this.phone,
    this.email,
    required this.name,
    this.passwordHash,
    this.otpState,
    this.transactionPinHash,
    required this.kycStatus,
    required this.referralCode,
    this.referredBy,
    required this.createdAt,
  });

  factory User({
    int? id,
    required String phone,
    String? email,
    required String name,
    String? passwordHash,
    String? otpState,
    String? transactionPinHash,
    required String kycStatus,
    required String referralCode,
    String? referredBy,
    required DateTime createdAt,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] as int?,
      phone: jsonSerialization['phone'] as String,
      email: jsonSerialization['email'] as String?,
      name: jsonSerialization['name'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String?,
      otpState: jsonSerialization['otpState'] as String?,
      transactionPinHash: jsonSerialization['transactionPinHash'] as String?,
      kycStatus: jsonSerialization['kycStatus'] as String,
      referralCode: jsonSerialization['referralCode'] as String,
      referredBy: jsonSerialization['referredBy'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String phone;

  String? email;

  String name;

  String? passwordHash;

  String? otpState;

  String? transactionPinHash;

  String kycStatus;

  String referralCode;

  String? referredBy;

  DateTime createdAt;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  User copyWith({
    int? id,
    String? phone,
    String? email,
    String? name,
    String? passwordHash,
    String? otpState,
    String? transactionPinHash,
    String? kycStatus,
    String? referralCode,
    String? referredBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id,
      'phone': phone,
      if (email != null) 'email': email,
      'name': name,
      if (passwordHash != null) 'passwordHash': passwordHash,
      if (otpState != null) 'otpState': otpState,
      if (transactionPinHash != null) 'transactionPinHash': transactionPinHash,
      'kycStatus': kycStatus,
      'referralCode': referralCode,
      if (referredBy != null) 'referredBy': referredBy,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    int? id,
    required String phone,
    String? email,
    required String name,
    String? passwordHash,
    String? otpState,
    String? transactionPinHash,
    required String kycStatus,
    required String referralCode,
    String? referredBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         phone: phone,
         email: email,
         name: name,
         passwordHash: passwordHash,
         otpState: otpState,
         transactionPinHash: transactionPinHash,
         kycStatus: kycStatus,
         referralCode: referralCode,
         referredBy: referredBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    String? phone,
    Object? email = _Undefined,
    String? name,
    Object? passwordHash = _Undefined,
    Object? otpState = _Undefined,
    Object? transactionPinHash = _Undefined,
    String? kycStatus,
    String? referralCode,
    Object? referredBy = _Undefined,
    DateTime? createdAt,
  }) {
    return User(
      id: id is int? ? id : this.id,
      phone: phone ?? this.phone,
      email: email is String? ? email : this.email,
      name: name ?? this.name,
      passwordHash: passwordHash is String? ? passwordHash : this.passwordHash,
      otpState: otpState is String? ? otpState : this.otpState,
      transactionPinHash: transactionPinHash is String?
          ? transactionPinHash
          : this.transactionPinHash,
      kycStatus: kycStatus ?? this.kycStatus,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy is String? ? referredBy : this.referredBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
