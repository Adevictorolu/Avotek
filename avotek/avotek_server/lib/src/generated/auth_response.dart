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
import 'user.dart' as _i2;
import 'wallet.dart' as _i3;
import 'package:avotek_server/src/generated/protocol.dart' as _i4;

abstract class AuthResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AuthResponse._({
    required this.token,
    required this.user,
    this.wallet,
  });

  factory AuthResponse({
    required String token,
    required _i2.User user,
    _i3.Wallet? wallet,
  }) = _AuthResponseImpl;

  factory AuthResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthResponse(
      token: jsonSerialization['token'] as String,
      user: _i4.Protocol().deserialize<_i2.User>(jsonSerialization['user']),
      wallet: jsonSerialization['wallet'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.Wallet>(jsonSerialization['wallet']),
    );
  }

  String token;

  _i2.User user;

  _i3.Wallet? wallet;

  /// Returns a shallow copy of this [AuthResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthResponse copyWith({
    String? token,
    _i2.User? user,
    _i3.Wallet? wallet,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthResponse',
      'token': token,
      'user': user.toJson(),
      if (wallet != null) 'wallet': wallet?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthResponse',
      'token': token,
      'user': user.toJsonForProtocol(),
      if (wallet != null) 'wallet': wallet?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthResponseImpl extends AuthResponse {
  _AuthResponseImpl({
    required String token,
    required _i2.User user,
    _i3.Wallet? wallet,
  }) : super._(
         token: token,
         user: user,
         wallet: wallet,
       );

  /// Returns a shallow copy of this [AuthResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthResponse copyWith({
    String? token,
    _i2.User? user,
    Object? wallet = _Undefined,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      user: user ?? this.user.copyWith(),
      wallet: wallet is _i3.Wallet? ? wallet : this.wallet?.copyWith(),
    );
  }
}
