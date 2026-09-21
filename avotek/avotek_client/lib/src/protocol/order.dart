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

abstract class Order implements _i1.SerializableModel {
  Order._({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.networkProvider,
    required this.recipientIdentifier,
    required this.amount,
    required this.costPrice,
    required this.sellPrice,
    this.providerReference,
    required this.status,
    required this.channel,
    required this.idempotencyKey,
    this.metadata,
    required this.createdAt,
  });

  factory Order({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required double amount,
    required double costPrice,
    required double sellPrice,
    String? providerReference,
    required String status,
    required String channel,
    required String idempotencyKey,
    String? metadata,
    required DateTime createdAt,
  }) = _OrderImpl;

  factory Order.fromJson(Map<String, dynamic> jsonSerialization) {
    return Order(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      serviceType: jsonSerialization['serviceType'] as String,
      networkProvider: jsonSerialization['networkProvider'] as String,
      recipientIdentifier: jsonSerialization['recipientIdentifier'] as String,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      costPrice: (jsonSerialization['costPrice'] as num).toDouble(),
      sellPrice: (jsonSerialization['sellPrice'] as num).toDouble(),
      providerReference: jsonSerialization['providerReference'] as String?,
      status: jsonSerialization['status'] as String,
      channel: jsonSerialization['channel'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      metadata: jsonSerialization['metadata'] as String?,
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

  String serviceType;

  String networkProvider;

  String recipientIdentifier;

  double amount;

  double costPrice;

  double sellPrice;

  String? providerReference;

  String status;

  String channel;

  String idempotencyKey;

  String? metadata;

  DateTime createdAt;

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Order copyWith({
    int? id,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    double? amount,
    double? costPrice,
    double? sellPrice,
    String? providerReference,
    String? status,
    String? channel,
    String? idempotencyKey,
    String? metadata,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'amount': amount,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      if (providerReference != null) 'providerReference': providerReference,
      'status': status,
      'channel': channel,
      'idempotencyKey': idempotencyKey,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderImpl extends Order {
  _OrderImpl({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required double amount,
    required double costPrice,
    required double sellPrice,
    String? providerReference,
    required String status,
    required String channel,
    required String idempotencyKey,
    String? metadata,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         serviceType: serviceType,
         networkProvider: networkProvider,
         recipientIdentifier: recipientIdentifier,
         amount: amount,
         costPrice: costPrice,
         sellPrice: sellPrice,
         providerReference: providerReference,
         status: status,
         channel: channel,
         idempotencyKey: idempotencyKey,
         metadata: metadata,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Order copyWith({
    Object? id = _Undefined,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    double? amount,
    double? costPrice,
    double? sellPrice,
    Object? providerReference = _Undefined,
    String? status,
    String? channel,
    String? idempotencyKey,
    Object? metadata = _Undefined,
    DateTime? createdAt,
  }) {
    return Order(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      networkProvider: networkProvider ?? this.networkProvider,
      recipientIdentifier: recipientIdentifier ?? this.recipientIdentifier,
      amount: amount ?? this.amount,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      providerReference: providerReference is String?
          ? providerReference
          : this.providerReference,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      metadata: metadata is String? ? metadata : this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
