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

abstract class WebhookLog implements _i1.SerializableModel {
  WebhookLog._({
    this.id,
    required this.source,
    required this.payload,
    required this.processed,
    required this.createdAt,
  });

  factory WebhookLog({
    int? id,
    required String source,
    required String payload,
    required bool processed,
    required DateTime createdAt,
  }) = _WebhookLogImpl;

  factory WebhookLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookLog(
      id: jsonSerialization['id'] as int?,
      source: jsonSerialization['source'] as String,
      payload: jsonSerialization['payload'] as String,
      processed: _i1.BoolJsonExtension.fromJson(jsonSerialization['processed']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String source;

  String payload;

  bool processed;

  DateTime createdAt;

  /// Returns a shallow copy of this [WebhookLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookLog copyWith({
    int? id,
    String? source,
    String? payload,
    bool? processed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookLog',
      if (id != null) 'id': id,
      'source': source,
      'payload': payload,
      'processed': processed,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebhookLogImpl extends WebhookLog {
  _WebhookLogImpl({
    int? id,
    required String source,
    required String payload,
    required bool processed,
    required DateTime createdAt,
  }) : super._(
         id: id,
         source: source,
         payload: payload,
         processed: processed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WebhookLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookLog copyWith({
    Object? id = _Undefined,
    String? source,
    String? payload,
    bool? processed,
    DateTime? createdAt,
  }) {
    return WebhookLog(
      id: id is int? ? id : this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
