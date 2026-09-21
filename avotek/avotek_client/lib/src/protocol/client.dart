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

import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:avotek_client/src/protocol/order.dart' as _i5;
import 'package:avotek_client/src/protocol/transaction.dart' as _i6;
import 'package:avotek_client/src/protocol/user.dart' as _i7;
import 'package:avotek_client/src/protocol/audit_log.dart' as _i8;
import 'package:avotek_client/src/protocol/auth_response.dart' as _i9;
import 'package:avotek_client/src/protocol/service_catalog.dart' as _i10;
import 'package:avotek_client/src/protocol/beneficiary.dart' as _i11;
import 'package:avotek_client/src/protocol/order_result.dart' as _i12;
import 'package:avotek_client/src/protocol/verification_response.dart' as _i13;
import 'package:avotek_client/src/protocol/wallet_summary.dart' as _i14;
import 'package:avotek_client/src/protocol/greetings/greeting.dart' as _i15;
import 'protocol.dart' as _i16;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointAdmin extends _i2.EndpointRef {
  EndpointAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  _i3.Future<List<_i5.Order>> getAllOrders({
    required int limit,
    required int offset,
    String? status,
  }) => caller.callServerEndpoint<List<_i5.Order>>(
    'admin',
    'getAllOrders',
    {
      'limit': limit,
      'offset': offset,
      'status': status,
    },
  );

  _i3.Future<List<_i6.Transaction>> getAllTransactions({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i6.Transaction>>(
    'admin',
    'getAllTransactions',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  _i3.Future<List<_i7.User>> getAllUsers({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i7.User>>(
    'admin',
    'getAllUsers',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  _i3.Future<bool> updateCatalogItem(
    int id,
    double costPrice,
    double defaultMarkup,
    bool active,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'updateCatalogItem',
    {
      'id': id,
      'costPrice': costPrice,
      'defaultMarkup': defaultMarkup,
      'active': active,
    },
  );

  _i3.Future<bool> manualRefundOrder(
    int orderId,
    int adminId,
    String reason,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'manualRefundOrder',
    {
      'orderId': orderId,
      'adminId': adminId,
      'reason': reason,
    },
  );

  _i3.Future<bool> updateKycStatus(
    int userId,
    String kycStatus,
    int adminId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'updateKycStatus',
    {
      'userId': userId,
      'kycStatus': kycStatus,
      'adminId': adminId,
    },
  );

  _i3.Future<List<_i8.AuditLog>> getAuditLogs({required int limit}) =>
      caller.callServerEndpoint<List<_i8.AuditLog>>(
        'admin',
        'getAuditLogs',
        {'limit': limit},
      );
}

/// {@category Endpoint}
class EndpointAuth extends _i2.EndpointRef {
  EndpointAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  _i3.Future<bool> sendOtp(String phone) => caller.callServerEndpoint<bool>(
    'auth',
    'sendOtp',
    {'phone': phone},
  );

  _i3.Future<_i9.AuthResponse> verifyOtp(
    String phone,
    String otp, {
    String? name,
    String? referralCode,
  }) => caller.callServerEndpoint<_i9.AuthResponse>(
    'auth',
    'verifyOtp',
    {
      'phone': phone,
      'otp': otp,
      'name': name,
      'referralCode': referralCode,
    },
  );

  _i3.Future<bool> setTransactionPin(
    int userId,
    String pin,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'setTransactionPin',
    {
      'userId': userId,
      'pin': pin,
    },
  );

  _i3.Future<bool> verifyTransactionPin(
    int userId,
    String pin,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'verifyTransactionPin',
    {
      'userId': userId,
      'pin': pin,
    },
  );

  _i3.Future<_i7.User?> getUserProfile(int userId) =>
      caller.callServerEndpoint<_i7.User?>(
        'auth',
        'getUserProfile',
        {'userId': userId},
      );
}

/// {@category Endpoint}
class EndpointCatalog extends _i2.EndpointRef {
  EndpointCatalog(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'catalog';

  _i3.Future<List<_i10.ServiceCatalog>> getCatalog({
    String? serviceType,
    String? provider,
  }) => caller.callServerEndpoint<List<_i10.ServiceCatalog>>(
    'catalog',
    'getCatalog',
    {
      'serviceType': serviceType,
      'provider': provider,
    },
  );

  _i3.Future<List<_i11.Beneficiary>> getBeneficiaries(
    int userId, {
    String? serviceType,
  }) => caller.callServerEndpoint<List<_i11.Beneficiary>>(
    'catalog',
    'getBeneficiaries',
    {
      'userId': userId,
      'serviceType': serviceType,
    },
  );

  _i3.Future<_i11.Beneficiary> saveBeneficiary(
    int userId,
    String serviceType,
    String networkProvider,
    String recipientIdentifier,
    String name,
  ) => caller.callServerEndpoint<_i11.Beneficiary>(
    'catalog',
    'saveBeneficiary',
    {
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'name': name,
    },
  );

  _i3.Future<bool> deleteBeneficiary(
    int beneficiaryId,
    int userId,
  ) => caller.callServerEndpoint<bool>(
    'catalog',
    'deleteBeneficiary',
    {
      'beneficiaryId': beneficiaryId,
      'userId': userId,
    },
  );
}

/// {@category Endpoint}
class EndpointOrder extends _i2.EndpointRef {
  EndpointOrder(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'order';

  _i3.Future<_i12.OrderResult> buyAirtime(
    int userId,
    String network,
    String phone,
    double amount,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'buyAirtime',
    {
      'userId': userId,
      'network': network,
      'phone': phone,
      'amount': amount,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i12.OrderResult> buyData(
    int userId,
    String network,
    String phone,
    String variationCode,
    double amount,
    double sellPrice,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'buyData',
    {
      'userId': userId,
      'network': network,
      'phone': phone,
      'variationCode': variationCode,
      'amount': amount,
      'sellPrice': sellPrice,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i12.OrderResult> payElectricity(
    int userId,
    String disco,
    String meterNumber,
    String meterType,
    double amount,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'payElectricity',
    {
      'userId': userId,
      'disco': disco,
      'meterNumber': meterNumber,
      'meterType': meterType,
      'amount': amount,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i12.OrderResult> payCableTV(
    int userId,
    String provider,
    String smartcardNumber,
    String variationCode,
    double amount,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'payCableTV',
    {
      'userId': userId,
      'provider': provider,
      'smartcardNumber': smartcardNumber,
      'variationCode': variationCode,
      'amount': amount,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i12.OrderResult> buyExamPin(
    int userId,
    String examType,
    int quantity,
    double amount,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'buyExamPin',
    {
      'userId': userId,
      'examType': examType,
      'quantity': quantity,
      'amount': amount,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i12.OrderResult> fundBetting(
    int userId,
    String provider,
    String customerId,
    double amount,
    String idempotencyKey,
    String channel,
  ) => caller.callServerEndpoint<_i12.OrderResult>(
    'order',
    'fundBetting',
    {
      'userId': userId,
      'provider': provider,
      'customerId': customerId,
      'amount': amount,
      'idempotencyKey': idempotencyKey,
      'channel': channel,
    },
  );

  _i3.Future<_i13.VerificationResponse> verifyMeter(
    String disco,
    String meterNumber,
    String meterType,
  ) => caller.callServerEndpoint<_i13.VerificationResponse>(
    'order',
    'verifyMeter',
    {
      'disco': disco,
      'meterNumber': meterNumber,
      'meterType': meterType,
    },
  );

  _i3.Future<_i13.VerificationResponse> verifySmartcard(
    String provider,
    String smartcardNumber,
  ) => caller.callServerEndpoint<_i13.VerificationResponse>(
    'order',
    'verifySmartcard',
    {
      'provider': provider,
      'smartcardNumber': smartcardNumber,
    },
  );

  _i3.Future<List<_i5.Order>> getOrders(
    int userId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i5.Order>>(
    'order',
    'getOrders',
    {
      'userId': userId,
      'limit': limit,
      'offset': offset,
    },
  );
}

/// {@category Endpoint}
class EndpointWallet extends _i2.EndpointRef {
  EndpointWallet(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'wallet';

  _i3.Future<_i14.WalletSummary> getWallet(int userId) =>
      caller.callServerEndpoint<_i14.WalletSummary>(
        'wallet',
        'getWallet',
        {'userId': userId},
      );

  _i3.Future<List<_i6.Transaction>> getTransactions(
    int userId, {
    required int limit,
    required int offset,
    String? filterType,
  }) => caller.callServerEndpoint<List<_i6.Transaction>>(
    'wallet',
    'getTransactions',
    {
      'userId': userId,
      'limit': limit,
      'offset': offset,
      'filterType': filterType,
    },
  );

  _i3.Future<_i6.Transaction> fundWalletSimulate(
    int userId,
    double amount,
    String reference,
    String idempotencyKey,
  ) => caller.callServerEndpoint<_i6.Transaction>(
    'wallet',
    'fundWalletSimulate',
    {
      'userId': userId,
      'amount': amount,
      'reference': reference,
      'idempotencyKey': idempotencyKey,
    },
  );
}

/// {@category Endpoint}
class EndpointWebhook extends _i2.EndpointRef {
  EndpointWebhook(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'webhook';

  _i3.Future<bool> handlePaystackWebhook(
    String payload,
    String signature,
  ) => caller.callServerEndpoint<bool>(
    'webhook',
    'handlePaystackWebhook',
    {
      'payload': payload,
      'signature': signature,
    },
  );

  _i3.Future<bool> handleWhatsAppWebhook(String payload) =>
      caller.callServerEndpoint<bool>(
        'webhook',
        'handleWhatsAppWebhook',
        {'payload': payload},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i15.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i15.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i16.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    admin = EndpointAdmin(this);
    auth = EndpointAuth(this);
    catalog = EndpointCatalog(this);
    order = EndpointOrder(this);
    wallet = EndpointWallet(this);
    webhook = EndpointWebhook(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAdmin admin;

  late final EndpointAuth auth;

  late final EndpointCatalog catalog;

  late final EndpointOrder order;

  late final EndpointWallet wallet;

  late final EndpointWebhook webhook;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'admin': admin,
    'auth': auth,
    'catalog': catalog,
    'order': order,
    'wallet': wallet,
    'webhook': webhook,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
