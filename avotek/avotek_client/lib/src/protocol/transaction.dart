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

abstract class Transaction implements _i1.SerializableModel {
  Transaction._({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reference,
    required this.status,
    required this.idempotencyKey,
    this.narration,
    required this.createdAt,
  });

  factory Transaction({
    int? id,
    required int userId,
    required String type,
    required double amount,
    required double balanceBefore,
    required double balanceAfter,
    required String reference,
    required String status,
    required String idempotencyKey,
    String? narration,
    required DateTime createdAt,
  }) = _TransactionImpl;

  factory Transaction.fromJson(Map<String, dynamic> jsonSerialization) {
    return Transaction(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      type: jsonSerialization['type'] as String,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      balanceBefore: (jsonSerialization['balanceBefore'] as num).toDouble(),
      balanceAfter: (jsonSerialization['balanceAfter'] as num).toDouble(),
      reference: jsonSerialization['reference'] as String,
      status: jsonSerialization['status'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      narration: jsonSerialization['narration'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String type;

  double amount;

  double balanceBefore;

  double balanceAfter;

  String reference;

  String status;

  String idempotencyKey;

  String? narration;

  DateTime createdAt;

  /// Returns a shallow copy of this [Transaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Transaction copyWith({
    int? id,
    int? userId,
    String? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    String? reference,
    String? status,
    String? idempotencyKey,
    String? narration,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Transaction',
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'reference': reference,
      'status': status,
      'idempotencyKey': idempotencyKey,
      if (narration != null) 'narration': narration,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TransactionImpl extends Transaction {
  _TransactionImpl({
    int? id,
    required int userId,
    required String type,
    required double amount,
    required double balanceBefore,
    required double balanceAfter,
    required String reference,
    required String status,
    required String idempotencyKey,
    String? narration,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         type: type,
         amount: amount,
         balanceBefore: balanceBefore,
         balanceAfter: balanceAfter,
         reference: reference,
         status: status,
         idempotencyKey: idempotencyKey,
         narration: narration,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Transaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Transaction copyWith({
    Object? id = _Undefined,
    int? userId,
    String? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    String? reference,
    String? status,
    String? idempotencyKey,
    Object? narration = _Undefined,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      narration: narration is String? ? narration : this.narration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
