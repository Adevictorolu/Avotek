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

import 'package:serverpod/serverpod.dart' as _i1;

abstract class WalletSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WalletSummary._({
    required this.balance,
    required this.currency,
    this.virtualAccountNumber,
    this.virtualAccountBank,
    this.virtualAccountName,
    required this.totalFunded,
    required this.totalSpent,
  });

  factory WalletSummary({
    required double balance,
    required String currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    required double totalFunded,
    required double totalSpent,
  }) = _WalletSummaryImpl;

  factory WalletSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return WalletSummary(
      balance: (jsonSerialization['balance'] as num).toDouble(),
      currency: jsonSerialization['currency'] as String,
      virtualAccountNumber:
          jsonSerialization['virtualAccountNumber'] as String?,
      virtualAccountBank: jsonSerialization['virtualAccountBank'] as String?,
      virtualAccountName: jsonSerialization['virtualAccountName'] as String?,
      totalFunded: (jsonSerialization['totalFunded'] as num).toDouble(),
      totalSpent: (jsonSerialization['totalSpent'] as num).toDouble(),
    );
  }

  double balance;

  String currency;

  String? virtualAccountNumber;

  String? virtualAccountBank;

  String? virtualAccountName;

  double totalFunded;

  double totalSpent;

  /// Returns a shallow copy of this [WalletSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WalletSummary copyWith({
    double? balance,
    String? currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    double? totalFunded,
    double? totalSpent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WalletSummary',
      'balance': balance,
      'currency': currency,
      if (virtualAccountNumber != null)
        'virtualAccountNumber': virtualAccountNumber,
      if (virtualAccountBank != null) 'virtualAccountBank': virtualAccountBank,
      if (virtualAccountName != null) 'virtualAccountName': virtualAccountName,
      'totalFunded': totalFunded,
      'totalSpent': totalSpent,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WalletSummary',
      'balance': balance,
      'currency': currency,
      if (virtualAccountNumber != null)
        'virtualAccountNumber': virtualAccountNumber,
      if (virtualAccountBank != null) 'virtualAccountBank': virtualAccountBank,
      if (virtualAccountName != null) 'virtualAccountName': virtualAccountName,
      'totalFunded': totalFunded,
      'totalSpent': totalSpent,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WalletSummaryImpl extends WalletSummary {
  _WalletSummaryImpl({
    required double balance,
    required String currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    required double totalFunded,
    required double totalSpent,
  }) : super._(
         balance: balance,
         currency: currency,
         virtualAccountNumber: virtualAccountNumber,
         virtualAccountBank: virtualAccountBank,
         virtualAccountName: virtualAccountName,
         totalFunded: totalFunded,
         totalSpent: totalSpent,
       );

  /// Returns a shallow copy of this [WalletSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WalletSummary copyWith({
    double? balance,
    String? currency,
    Object? virtualAccountNumber = _Undefined,
    Object? virtualAccountBank = _Undefined,
    Object? virtualAccountName = _Undefined,
    double? totalFunded,
    double? totalSpent,
  }) {
    return WalletSummary(
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
      totalFunded: totalFunded ?? this.totalFunded,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}
