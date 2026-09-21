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

abstract class Wallet implements _i1.SerializableModel {
  Wallet._({
    this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    this.virtualAccountNumber,
    this.virtualAccountBank,
    this.virtualAccountName,
    required this.updatedAt,
  });

  factory Wallet({
    int? id,
    required int userId,
    required double balance,
    required String currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    required DateTime updatedAt,
  }) = _WalletImpl;

  factory Wallet.fromJson(Map<String, dynamic> jsonSerialization) {
    return Wallet(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      balance: (jsonSerialization['balance'] as num).toDouble(),
      currency: jsonSerialization['currency'] as String,
      virtualAccountNumber:
          jsonSerialization['virtualAccountNumber'] as String?,
      virtualAccountBank: jsonSerialization['virtualAccountBank'] as String?,
      virtualAccountName: jsonSerialization['virtualAccountName'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  double balance;

  String currency;

  String? virtualAccountNumber;

  String? virtualAccountBank;

  String? virtualAccountName;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Wallet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Wallet copyWith({
    int? id,
    int? userId,
    double? balance,
    String? currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Wallet',
      if (id != null) 'id': id,
      'userId': userId,
      'balance': balance,
      'currency': currency,
      if (virtualAccountNumber != null)
        'virtualAccountNumber': virtualAccountNumber,
      if (virtualAccountBank != null) 'virtualAccountBank': virtualAccountBank,
      if (virtualAccountName != null) 'virtualAccountName': virtualAccountName,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WalletImpl extends Wallet {
  _WalletImpl({
    int? id,
    required int userId,
    required double balance,
    required String currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         balance: balance,
         currency: currency,
         virtualAccountNumber: virtualAccountNumber,
         virtualAccountBank: virtualAccountBank,
         virtualAccountName: virtualAccountName,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Wallet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Wallet copyWith({
    Object? id = _Undefined,
    int? userId,
    double? balance,
    String? currency,
    Object? virtualAccountNumber = _Undefined,
    Object? virtualAccountBank = _Undefined,
    Object? virtualAccountName = _Undefined,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      virtualAccountNumber: virtualAccountNumber is String?
          ? virtualAccountNumber
          : this.virtualAccountNumber,
      virtualAccountBank: virtualAccountBank is String?
          ? virtualAccountBank
          : this.virtualAccountBank,
      virtualAccountName: virtualAccountName is String?
          ? virtualAccountName
          : this.virtualAccountName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
