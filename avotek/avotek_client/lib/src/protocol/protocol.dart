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
import 'admin_user.dart' as _i2;
import 'agent.dart' as _i3;
import 'audit_log.dart' as _i4;
import 'auth_response.dart' as _i5;
import 'beneficiary.dart' as _i6;
import 'greetings/greeting.dart' as _i7;
import 'order.dart' as _i8;
import 'order_result.dart' as _i9;
import 'service_catalog.dart' as _i10;
import 'transaction.dart' as _i11;
import 'user.dart' as _i12;
import 'verification_response.dart' as _i13;
import 'wallet.dart' as _i14;
import 'wallet_summary.dart' as _i15;
import 'webhook_log.dart' as _i16;
import 'package:avotek_client/src/protocol/order.dart' as _i17;
import 'package:avotek_client/src/protocol/transaction.dart' as _i18;
import 'package:avotek_client/src/protocol/user.dart' as _i19;
import 'package:avotek_client/src/protocol/audit_log.dart' as _i20;
import 'package:avotek_client/src/protocol/service_catalog.dart' as _i21;
import 'package:avotek_client/src/protocol/beneficiary.dart' as _i22;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i23;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i24;
export 'admin_user.dart';
export 'agent.dart';
export 'audit_log.dart';
export 'auth_response.dart';
export 'beneficiary.dart';
export 'greetings/greeting.dart';
export 'order.dart';
export 'order_result.dart';
export 'service_catalog.dart';
export 'transaction.dart';
export 'user.dart';
export 'verification_response.dart';
export 'wallet.dart';
export 'wallet_summary.dart';
export 'webhook_log.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AdminUser) {
      return _i2.AdminUser.fromJson(data) as T;
    }
    if (t == _i3.Agent) {
      return _i3.Agent.fromJson(data) as T;
    }
    if (t == _i4.AuditLog) {
      return _i4.AuditLog.fromJson(data) as T;
    }
    if (t == _i5.AuthResponse) {
      return _i5.AuthResponse.fromJson(data) as T;
    }
    if (t == _i6.Beneficiary) {
      return _i6.Beneficiary.fromJson(data) as T;
    }
    if (t == _i7.Greeting) {
      return _i7.Greeting.fromJson(data) as T;
    }
    if (t == _i8.Order) {
      return _i8.Order.fromJson(data) as T;
    }
    if (t == _i9.OrderResult) {
      return _i9.OrderResult.fromJson(data) as T;
    }
    if (t == _i10.ServiceCatalog) {
      return _i10.ServiceCatalog.fromJson(data) as T;
    }
    if (t == _i11.Transaction) {
      return _i11.Transaction.fromJson(data) as T;
    }
    if (t == _i12.User) {
      return _i12.User.fromJson(data) as T;
    }
    if (t == _i13.VerificationResponse) {
      return _i13.VerificationResponse.fromJson(data) as T;
    }
    if (t == _i14.Wallet) {
      return _i14.Wallet.fromJson(data) as T;
    }
    if (t == _i15.WalletSummary) {
      return _i15.WalletSummary.fromJson(data) as T;
    }
    if (t == _i16.WebhookLog) {
      return _i16.WebhookLog.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminUser?>()) {
      return (data != null ? _i2.AdminUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Agent?>()) {
      return (data != null ? _i3.Agent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuditLog?>()) {
      return (data != null ? _i4.AuditLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AuthResponse?>()) {
      return (data != null ? _i5.AuthResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Beneficiary?>()) {
      return (data != null ? _i6.Beneficiary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Greeting?>()) {
      return (data != null ? _i7.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Order?>()) {
      return (data != null ? _i8.Order.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.OrderResult?>()) {
      return (data != null ? _i9.OrderResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ServiceCatalog?>()) {
      return (data != null ? _i10.ServiceCatalog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Transaction?>()) {
      return (data != null ? _i11.Transaction.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.User?>()) {
      return (data != null ? _i12.User.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.VerificationResponse?>()) {
      return (data != null ? _i13.VerificationResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.Wallet?>()) {
      return (data != null ? _i14.Wallet.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WalletSummary?>()) {
      return (data != null ? _i15.WalletSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.WebhookLog?>()) {
      return (data != null ? _i16.WebhookLog.fromJson(data) : null) as T;
    }
    if (t == List<_i17.Order>) {
      return (data as List).map((e) => deserialize<_i17.Order>(e)).toList()
          as T;
    }
    if (t == List<_i18.Transaction>) {
      return (data as List)
              .map((e) => deserialize<_i18.Transaction>(e))
              .toList()
          as T;
    }
    if (t == List<_i19.User>) {
      return (data as List).map((e) => deserialize<_i19.User>(e)).toList() as T;
    }
    if (t == List<_i20.AuditLog>) {
      return (data as List).map((e) => deserialize<_i20.AuditLog>(e)).toList()
          as T;
    }
    if (t == List<_i21.ServiceCatalog>) {
      return (data as List)
              .map((e) => deserialize<_i21.ServiceCatalog>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.Beneficiary>) {
      return (data as List)
              .map((e) => deserialize<_i22.Beneficiary>(e))
              .toList()
          as T;
    }
    try {
      return _i23.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i24.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminUser => 'AdminUser',
      _i3.Agent => 'Agent',
      _i4.AuditLog => 'AuditLog',
      _i5.AuthResponse => 'AuthResponse',
      _i6.Beneficiary => 'Beneficiary',
      _i7.Greeting => 'Greeting',
      _i8.Order => 'Order',
      _i9.OrderResult => 'OrderResult',
      _i10.ServiceCatalog => 'ServiceCatalog',
      _i11.Transaction => 'Transaction',
      _i12.User => 'User',
      _i13.VerificationResponse => 'VerificationResponse',
      _i14.Wallet => 'Wallet',
      _i15.WalletSummary => 'WalletSummary',
      _i16.WebhookLog => 'WebhookLog',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('avotek.', '');
    }

    switch (data) {
      case _i2.AdminUser():
        return 'AdminUser';
      case _i3.Agent():
        return 'Agent';
      case _i4.AuditLog():
        return 'AuditLog';
      case _i5.AuthResponse():
        return 'AuthResponse';
      case _i6.Beneficiary():
        return 'Beneficiary';
      case _i7.Greeting():
        return 'Greeting';
      case _i8.Order():
        return 'Order';
      case _i9.OrderResult():
        return 'OrderResult';
      case _i10.ServiceCatalog():
        return 'ServiceCatalog';
      case _i11.Transaction():
        return 'Transaction';
      case _i12.User():
        return 'User';
      case _i13.VerificationResponse():
        return 'VerificationResponse';
      case _i14.Wallet():
        return 'Wallet';
      case _i15.WalletSummary():
        return 'WalletSummary';
      case _i16.WebhookLog():
        return 'WebhookLog';
    }
    className = _i23.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i24.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AdminUser') {
      return deserialize<_i2.AdminUser>(data['data']);
    }
    if (dataClassName == 'Agent') {
      return deserialize<_i3.Agent>(data['data']);
    }
    if (dataClassName == 'AuditLog') {
      return deserialize<_i4.AuditLog>(data['data']);
    }
    if (dataClassName == 'AuthResponse') {
      return deserialize<_i5.AuthResponse>(data['data']);
    }
    if (dataClassName == 'Beneficiary') {
      return deserialize<_i6.Beneficiary>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i7.Greeting>(data['data']);
    }
    if (dataClassName == 'Order') {
      return deserialize<_i8.Order>(data['data']);
    }
    if (dataClassName == 'OrderResult') {
      return deserialize<_i9.OrderResult>(data['data']);
    }
    if (dataClassName == 'ServiceCatalog') {
      return deserialize<_i10.ServiceCatalog>(data['data']);
    }
    if (dataClassName == 'Transaction') {
      return deserialize<_i11.Transaction>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_i12.User>(data['data']);
    }
    if (dataClassName == 'VerificationResponse') {
      return deserialize<_i13.VerificationResponse>(data['data']);
    }
    if (dataClassName == 'Wallet') {
      return deserialize<_i14.Wallet>(data['data']);
    }
    if (dataClassName == 'WalletSummary') {
      return deserialize<_i15.WalletSummary>(data['data']);
    }
    if (dataClassName == 'WebhookLog') {
      return deserialize<_i16.WebhookLog>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i23.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i24.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i23.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i24.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
