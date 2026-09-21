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
import 'order.dart' as _i2;
import 'package:avotek_client/src/protocol/protocol.dart' as _i3;

abstract class OrderResult implements _i1.SerializableModel {
  OrderResult._({
    required this.order,
    required this.success,
    required this.message,
    this.token,
    this.units,
  });

  factory OrderResult({
    required _i2.Order order,
    required bool success,
    required String message,
    String? token,
    String? units,
  }) = _OrderResultImpl;

  factory OrderResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderResult(
      order: _i3.Protocol().deserialize<_i2.Order>(jsonSerialization['order']),
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      message: jsonSerialization['message'] as String,
      token: jsonSerialization['token'] as String?,
      units: jsonSerialization['units'] as String?,
    );
  }

  _i2.Order order;

  bool success;

  String message;

  String? token;

  String? units;

  /// Returns a shallow copy of this [OrderResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OrderResult copyWith({
    _i2.Order? order,
    bool? success,
    String? message,
    String? token,
    String? units,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrderResult',
      'order': order.toJson(),
      'success': success,
      'message': message,
      if (token != null) 'token': token,
      if (units != null) 'units': units,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderResultImpl extends OrderResult {
  _OrderResultImpl({
    required _i2.Order order,
    required bool success,
    required String message,
    String? token,
    String? units,
  }) : super._(
         order: order,
         success: success,
         message: message,
         token: token,
         units: units,
       );

  /// Returns a shallow copy of this [OrderResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OrderResult copyWith({
    _i2.Order? order,
    bool? success,
    String? message,
    Object? token = _Undefined,
    Object? units = _Undefined,
  }) {
    return OrderResult(
      order: order ?? this.order.copyWith(),
      success: success ?? this.success,
      message: message ?? this.message,
      token: token is String? ? token : this.token,
      units: units is String? ? units : this.units,
    );
  }
}
