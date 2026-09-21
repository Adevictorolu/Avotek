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

abstract class Beneficiary implements _i1.SerializableModel {
  Beneficiary._({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.networkProvider,
    required this.recipientIdentifier,
    required this.name,
    required this.createdAt,
  });

  factory Beneficiary({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
    required DateTime createdAt,
  }) = _BeneficiaryImpl;

  factory Beneficiary.fromJson(Map<String, dynamic> jsonSerialization) {
    return Beneficiary(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      serviceType: jsonSerialization['serviceType'] as String,
      networkProvider: jsonSerialization['networkProvider'] as String,
      recipientIdentifier: jsonSerialization['recipientIdentifier'] as String,
      name: jsonSerialization['name'] as String,
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

  String name;

  DateTime createdAt;

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Beneficiary copyWith({
    int? id,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Beneficiary',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BeneficiaryImpl extends Beneficiary {
  _BeneficiaryImpl({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         serviceType: serviceType,
         networkProvider: networkProvider,
         recipientIdentifier: recipientIdentifier,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Beneficiary copyWith({
    Object? id = _Undefined,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    String? name,
    DateTime? createdAt,
  }) {
    return Beneficiary(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      networkProvider: networkProvider ?? this.networkProvider,
      recipientIdentifier: recipientIdentifier ?? this.recipientIdentifier,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
