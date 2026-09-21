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

abstract class Agent implements _i1.SerializableModel {
  Agent._({
    this.id,
    required this.userId,
    required this.tier,
    required this.commissionRate,
    required this.updatedAt,
  });

  factory Agent({
    int? id,
    required int userId,
    required String tier,
    required double commissionRate,
    required DateTime updatedAt,
  }) = _AgentImpl;

  factory Agent.fromJson(Map<String, dynamic> jsonSerialization) {
    return Agent(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      tier: jsonSerialization['tier'] as String,
      commissionRate: (jsonSerialization['commissionRate'] as num).toDouble(),
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

  String tier;

  double commissionRate;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Agent copyWith({
    int? id,
    int? userId,
    String? tier,
    double? commissionRate,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Agent',
      if (id != null) 'id': id,
      'userId': userId,
      'tier': tier,
      'commissionRate': commissionRate,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentImpl extends Agent {
  _AgentImpl({
    int? id,
    required int userId,
    required String tier,
    required double commissionRate,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         tier: tier,
         commissionRate: commissionRate,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Agent copyWith({
    Object? id = _Undefined,
    int? userId,
    String? tier,
    double? commissionRate,
    DateTime? updatedAt,
  }) {
    return Agent(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      commissionRate: commissionRate ?? this.commissionRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
