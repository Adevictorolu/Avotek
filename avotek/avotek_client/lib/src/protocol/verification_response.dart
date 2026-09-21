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

abstract class VerificationResponse implements _i1.SerializableModel {
  VerificationResponse._({
    required this.isValid,
    this.customerName,
    required this.identifier,
    this.details,
  });

  factory VerificationResponse({
    required bool isValid,
    String? customerName,
    required String identifier,
    String? details,
  }) = _VerificationResponseImpl;

  factory VerificationResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerificationResponse(
      isValid: _i1.BoolJsonExtension.fromJson(jsonSerialization['isValid']),
      customerName: jsonSerialization['customerName'] as String?,
      identifier: jsonSerialization['identifier'] as String,
      details: jsonSerialization['details'] as String?,
    );
  }

  bool isValid;

  String? customerName;

  String identifier;

  String? details;

  /// Returns a shallow copy of this [VerificationResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  VerificationResponse copyWith({
    bool? isValid,
    String? customerName,
    String? identifier,
    String? details,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerificationResponse',
      'isValid': isValid,
      if (customerName != null) 'customerName': customerName,
      'identifier': identifier,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerificationResponseImpl extends VerificationResponse {
  _VerificationResponseImpl({
    required bool isValid,
    String? customerName,
    required String identifier,
    String? details,
  }) : super._(
         isValid: isValid,
         customerName: customerName,
         identifier: identifier,
         details: details,
       );

  /// Returns a shallow copy of this [VerificationResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  VerificationResponse copyWith({
    bool? isValid,
    Object? customerName = _Undefined,
    String? identifier,
    Object? details = _Undefined,
  }) {
    return VerificationResponse(
      isValid: isValid ?? this.isValid,
      customerName: customerName is String? ? customerName : this.customerName,
      identifier: identifier ?? this.identifier,
      details: details is String? ? details : this.details,
    );
  }
}
