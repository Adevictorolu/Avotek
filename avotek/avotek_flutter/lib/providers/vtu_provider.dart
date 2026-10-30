import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/vtu_api_service.dart';
import '../core/supabase/supabase_service.dart';
import '../core/utils/nigerian_network_detector.dart';
import '../models/vtu_models.dart';

class VtuProvider extends ChangeNotifier {
  List<ServiceCatalog> _catalog = [];
  final List<Beneficiary> _beneficiaries = [];
  bool _isLoading = false;
  String? _lastError;

  // Cached live plans from the configured provider.
  final Map<int, List<Map<String, dynamic>>> _liveDataPlansCache = {};
  final Map<String, List<Map<String, dynamic>>> _cablePlansCache = {};
  List<Map<String, dynamic>> _electricityProviders = [];

  VtuProvider() {
    _initDefaultCatalog();
  }

  List<ServiceCatalog> get catalog => _catalog;
  List<Beneficiary> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  List<Map<String, dynamic>> get electricityProviders => _electricityProviders;

  void _initDefaultCatalog() {
    _catalog = [
      // MTN Data
      const ServiceCatalog(
        id: 135,
        serviceType: 'data',
        name: 'MTN SME 1.0GB (30 Days)',
        variationCode: 'MTN-DATA-1GB',
        provider: 'MTN',
        costPrice: 260.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      const ServiceCatalog(
        id: 136,
        serviceType: 'data',
        name: 'MTN SME 2.0GB (30 Days)',
        variationCode: 'MTN-DATA-2GB',
        provider: 'MTN',
        costPrice: 520.0,
        defaultMarkup: 20.0,
        active: true,
      ),
      const ServiceCatalog(
        id: 137,
        serviceType: 'data',
        name: 'MTN Corporate 5.0GB (30 Days)',
        variationCode: 'MTN-DATA-5GB',
        provider: 'MTN',
        costPrice: 1300.0,
        defaultMarkup: 50.0,
        active: true,
      ),
      const ServiceCatalog(
        id: 138,
        serviceType: 'data',
        name: 'MTN Gifting 10.0GB (30 Days)',
        variationCode: 'MTN-DATA-10GB',
        provider: 'MTN',
        costPrice: 2600.0,
        defaultMarkup: 100.0,
        active: true,
      ),
      // Airtel Data
      const ServiceCatalog(
        id: 201,
        serviceType: 'data',
        name: 'Airtel CG 1.0GB (30 Days)',
        variationCode: 'AIRTEL-DATA-1GB',
        provider: 'AIRTEL',
        costPrice: 265.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      const ServiceCatalog(
        id: 202,
        serviceType: 'data',
        name: 'Airtel CG 2.0GB (30 Days)',
        variationCode: 'AIRTEL-DATA-2GB',
        provider: 'AIRTEL',
        costPrice: 530.0,
        defaultMarkup: 20.0,
        active: true,
      ),
      // Glo Data
      const ServiceCatalog(
        id: 301,
        serviceType: 'data',
        name: 'Glo SME 1.0GB (30 Days)',
        variationCode: 'GLO-DATA-1GB',
        provider: 'GLO',
        costPrice: 240.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      // 9mobile Data
      const ServiceCatalog(
        id: 401,
        serviceType: 'data',
        name: '9mobile SME 1.5GB (30 Days)',
        variationCode: '9MOB-DATA-1.5GB',
        provider: '9MOBILE',
        costPrice: 250.0,
        defaultMarkup: 10.0,
        active: true,
      ),
    ];
  }

  // Auto-detect Nigerian Telecom network from phone prefix
  static String detectNetwork(String phone) =>
      NigerianNetworkDetector.detect(phone) ?? 'MTN';

  /// Fetch live data plans through the server-side provider proxy.
  Future<List<Map<String, dynamic>>> fetchLiveDataPlans(
    dynamic network, {
    String? planType,
  }) async {
    final networkId = network is int
        ? network
        : VtuApiService.mapNetworkNameToId(network.toString());

    // Check in-memory cache
    if (_liveDataPlansCache.containsKey(networkId) &&
        (planType == null || planType.isEmpty || planType == 'ALL')) {
      return _liveDataPlansCache[networkId]!;
    }

    try {
      final plans = await VtuApiService.instance.getDataPlans(
        network: networkId,
        planType: planType,
      );
      if (plans.isNotEmpty) {
        _liveDataPlansCache[networkId] = plans;
      }
      return plans;
    } catch (e) {
      debugPrint('Error fetching live data plans: $e');
      return _liveDataPlansCache[networkId] ?? [];
    }
  }

  /// Fetch Live Cable Packages
  Future<List<Map<String, dynamic>>> fetchCablePackages(String provider) async {
    final key = provider.toLowerCase();
    if (_cablePlansCache.containsKey(key)) {
      return _cablePlansCache[key]!;
    }

    try {
      final packages = await VtuApiService.instance.getCablePlans(
        cableName: provider,
      );
      if (packages.isNotEmpty) {
        _cablePlansCache[key] = packages;
      }
      return packages;
    } catch (e) {
      debugPrint('Error fetching live cable packages: $e');
      return _cablePlansCache[key] ?? [];
    }
  }

  /// Fetch Live Electricity Providers
  Future<List<Map<String, dynamic>>> fetchElectricityProviders() async {
    if (_electricityProviders.isNotEmpty) return _electricityProviders;
    try {
      final providers = await VtuApiService.instance.getElectricityProviders();
      if (providers.isNotEmpty) {
        _electricityProviders = providers;
        notifyListeners();
      }
      return providers;
    } catch (e) {
      debugPrint('Error fetching electricity providers: $e');
      return [];
    }
  }

  Future<void> fetchCatalog({String? serviceType}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    if (_catalog.isEmpty) {
      _initDefaultCatalog();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBeneficiaries(dynamic userId, {String? serviceType}) async {
    notifyListeners();
  }

  Future<void> saveBeneficiary({
    required dynamic userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
  }) async {
    final b = Beneficiary(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      userId: userId.toString(),
      name: name,
      phone: recipientIdentifier,
      network: networkProvider,
      serviceType: serviceType,
    );
    _beneficiaries.add(b);
    notifyListeners();
  }

  Future<OrderResult> _purchase({
    required dynamic userId,
    required String serviceType,
    required String network,
    required String recipient,
    required String plan,
    required double amount,
    required Future<Map<String, dynamic>> Function() dispatch,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    var status = 'failed';
    var message = 'The purchase could not be completed.';
    var chargedAmount = amount;
    String? providerReference;
    String? token;
    String? units;
    String? localReference;
    var issuedPins = const <String>[];
    try {
      final response = await dispatch();
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final providerStatus = (response['status'] ?? data['status'] ?? '')
          .toString()
          .toLowerCase();
      status = switch (providerStatus) {
        'success' ||
        'successful' ||
        'completed' ||
        'complete' ||
        'delivered' ||
        'approved' ||
        'ok' ||
        'paid' ||
        'sent' => 'successful',
        'pending' ||
        'processing' ||
        'submitted' ||
        'in_progress' ||
        'queued' ||
        'initiated' => 'pending',
        'failed' ||
        'fail' ||
        'failure' ||
        'error' ||
        'rejected' ||
        'cancelled' ||
        'canceled' ||
        'refunded' ||
        'partial' ||
        'declined' => 'failed',
        _ => response['success'] == true ? 'successful' : 'failed',
      };
      if (response['success'] == false) status = 'failed';
      final providerAmount = response['charged_amount'] ??
          data['total_amount'] ??
          data['total_cost'];
      if (providerAmount is num && providerAmount > 0) {
        chargedAmount = providerAmount.toDouble();
      }
      providerReference =
          (data['transaction_id'] ??
                  data['tran_id'] ??
                  data['tranx_id'] ??
                  data['job_id'] ??
                  response['provider_reference'])
              ?.toString();
      localReference =
          response['local_reference']?.toString() ??
          response['reference']?.toString();
      token =
          data['token']?.toString() ??
          data['meter_token']?.toString() ??
          response['token']?.toString();
      units = data['units']?.toString();
      issuedPins = _extractPinList(
        data['pins'] ?? data['cards'] ?? response['pins'] ?? response['cards'],
      );
      if (issuedPins.isNotEmpty) {
        token = issuedPins.join('\n');
      }
      message = response['message']?.toString() ?? message;

      // If still pending and we have a reference, try an immediate requery
      final lookupRef = (providerReference != null && providerReference.isNotEmpty)
          ? providerReference
          : localReference;
      if (status == 'pending' &&
          serviceType != 'bulk_sms' &&
          lookupRef != null &&
          lookupRef.isNotEmpty) {
        try {
          final reqRes = await VtuApiService.instance.requeryTransaction(
            lookupRef,
          );
          final reqStatus = (reqRes['status'] ?? '').toString().toLowerCase();
          if (reqStatus == 'completed' ||
              reqStatus == 'successful' ||
              reqStatus == 'success') {
            status = 'successful';
            message = reqRes['message']?.toString() ?? message;
            final reqData = reqRes['data'] is Map
                ? Map<String, dynamic>.from(reqRes['data'] as Map)
                : const <String, dynamic>{};
            token ??=
                reqData['token']?.toString() ??
                reqData['meter_token']?.toString();
            units ??= reqData['units']?.toString();
            if (issuedPins.isEmpty) {
              issuedPins = _extractPinList(reqData['pins'] ?? reqData['cards']);
              if (issuedPins.isNotEmpty) {
                token = issuedPins.join('\n');
              }
            }
          } else if (reqStatus == 'failed') {
            status = 'failed';
            message = reqRes['message']?.toString() ?? message;
          }
        } catch (_) {}
      }
    } on VtuProviderRequestException catch (error) {
      localReference = error.reference;
      // HTTP 4xx, 502, 503 mean the request was rejected or not configured;
      // only statusCode == 0 (connection dropped mid-flight) is ambiguous.
      status = error.statusCode == 0 ? 'pending' : 'failed';
      message = error.message != null && error.message!.trim().isNotEmpty
          ? error.message!.trim()
          : (status == 'pending'
                ? 'The purchase status could not be confirmed. Check your order history before retrying.'
                : error.toString());
      _lastError = message;
    } on TimeoutException {
      status = 'pending';
      message =
          'The VTU provider did not respond in time. Check your order history before retrying.';
      _lastError = message;
    } catch (error) {
      status = 'failed';
      message = error.toString().replaceFirst('Exception: ', '').trim();
      if (message.isEmpty) {
        message = 'The purchase could not be completed.';
      }
      _lastError = message;
      debugPrint('VTU provider purchase error: $error');
    }

    final order = await SupabaseService.instance.recordOrder(
      userId: userId.toString(),
      serviceType: serviceType,
      network: network,
      phone: recipient,
      plan: plan,
      amount: chargedAmount,
      status: status,
      id: localReference,
      providerReference: providerReference,
      token: token,
    );
    _isLoading = false;
    notifyListeners();

    return OrderResult(
      order: order,
      success: status != 'failed',
      message: message,
      token: token,
      units: units,
      issuedPins: issuedPins,
    );
  }

  List<String> _extractPinList(Object? rawPins) {
    if (rawPins is String && rawPins.trim().isNotEmpty) {
      return [rawPins.trim()];
    }
    if (rawPins is! List || rawPins.isEmpty) return const [];
    final items = <String>[];
    for (final entry in rawPins) {
      if (entry is Map) {
        final pin =
            entry['pin']?.toString() ??
            entry['token']?.toString() ??
            entry['pin_code']?.toString() ??
            '';
        final serial =
            entry['serial']?.toString() ??
            entry['serial_number']?.toString() ??
            entry['serial_no']?.toString() ??
            '';
        if (pin.isNotEmpty && serial.isNotEmpty) {
          items.add('PIN: $pin (Serial: $serial)');
        } else if (pin.isNotEmpty) {
          items.add(pin);
        }
      } else if (entry != null && entry.toString().trim().isNotEmpty) {
        items.add(entry.toString().trim());
      }
    }
    return items;
  }

  // ============================================================================
  // LIVE PURCHASES & SUPABASE SYNCHRONIZATION
  // ============================================================================

  /// Airtime purchase through the provider proxy and Supabase persistence.
  Future<OrderResult> buyAirtime({
    required dynamic userId,
    required String network,
    required String phone,
    required double amount,
    String? userPin,
    String airtimeType = 'vtu',
  }) {
    return _purchase(
      userId: userId,
      serviceType: 'airtime',
      network: network,
      recipient: phone,
      plan: '₦${amount.toStringAsFixed(0)} Airtime',
      amount: amount,
      dispatch: () => VtuApiService.instance.purchaseAirtime(
        network: network,
        phone: phone,
        amount: amount,
        pin: userPin,
        airtimeType: airtimeType,
      ),
    );
  }

  /// Data bundle purchase through the provider proxy and Supabase persistence.
  Future<OrderResult> buyData({
    required dynamic userId,
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required double sellPrice,
    int? planId,
    String? userPin,
  }) async {
    // Resolve plan ID
    var resolvedPlanId = planId;
    if (planId == null) {
      final netId = VtuApiService.mapNetworkNameToId(network);
      final cached = _liveDataPlansCache[netId];
      Map<String, dynamic>? match;
      for (final candidate in cached ?? const <Map<String, dynamic>>[]) {
        final candidateId = (candidate['id'] as num?)?.toInt();
        final candidateAmount = (candidate['amount'] as num?)?.toDouble();
        final size = candidate['size']?.toString() ?? '';
        if (candidateId != null &&
            (candidateAmount == amount ||
                (size.isNotEmpty && variationCode.contains(size)))) {
          match = candidate;
          break;
        }
      }
      resolvedPlanId ??= (match?['id'] as num?)?.toInt();
    }
    if (resolvedPlanId == null) {
      throw Exception('Refresh plans and select an available data plan.');
    }
    return _purchase(
      userId: userId,
      serviceType: 'data',
      network: network,
      recipient: phone,
      plan: variationCode,
      amount: sellPrice,
      dispatch: () => VtuApiService.instance.purchaseData(
        network: network,
        planId: resolvedPlanId!,
        phone: phone,
        sellPrice: sellPrice,
        pin: userPin,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchExamPinPrices() =>
      VtuApiService.instance.getExamPinPrices();

  Future<OrderResult> buyExamPins({
    required dynamic userId,
    required String examCode,
    required String examName,
    required int quantity,
    required double unitPrice,
    String? userPin,
  }) {
    final amount = unitPrice * quantity;
    return _purchase(
      userId: userId,
      serviceType: 'education',
      network: examCode.toUpperCase(),
      recipient: 'exam pins',
      plan: '$examName x$quantity',
      amount: amount,
      dispatch: () => VtuApiService.instance.purchaseExamPins(
        examCode: examCode,
        quantity: quantity,
        pin: userPin,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchSmsPricing() =>
      VtuApiService.instance.getSmsPricing();

  Future<OrderResult> sendBulkSms({
    required dynamic userId,
    required List<String> recipients,
    required String message,
    required String senderName,
    required String userPin,
  }) async {
    final pricing = await fetchSmsPricing();
    final data = pricing['data'];
    final costPerPage = data is Map<String, dynamic>
        ? (data['cost_per_page'] as num?)?.toDouble()
        : null;
    if (costPerPage == null || costPerPage <= 0) {
      throw StateError('The SMS provider returned invalid pricing.');
    }
    final pages = VtuApiService.estimateSmsPages(message);
    final amount = costPerPage * pages * recipients.length;

    return _purchase(
      userId: userId,
      serviceType: 'bulk_sms',
      network: 'SMS',
      recipient: 'Bulk SMS (${recipients.length} recipients)',
      plan: senderName,
      amount: amount,
      dispatch: () => VtuApiService.instance.sendBulkSms(
        recipients: recipients,
        message: message,
        senderName: senderName,
        pin: userPin,
      ),
    );
  }

  /// Smartcard / IUC verification through the provider proxy.
  Future<VerificationResponse> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    try {
      final res = await VtuApiService.instance.verifySmartcard(
        cableName: provider,
        smartcardNumber: smartcardNumber,
      );

      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : res;
      final name =
          data['customer_name']?.toString() ??
          data['name']?.toString() ??
          '';
      final bouquet = data['current_bouquet']?.toString() ?? provider;

      return VerificationResponse(
        isValid:
            res['success'] == true ||
            data['valid'] == true ||
            name.trim().isNotEmpty,
        customerName: name.isNotEmpty ? name : 'Verified Subscriber',
        identifier: smartcardNumber,
        details: '$bouquet • $provider',
      );
    } catch (e) {
      debugPrint('Smartcard verify fallback: $e');
      return VerificationResponse(
        isValid: false,
        customerName: '',
        identifier: smartcardNumber,
        details:
            'Could not verify this smartcard. Check the details and retry.',
      );
    }
  }

  /// Cable TV subscription through the provider proxy.
  Future<OrderResult> payCableTV({
    required dynamic userId,
    required String provider,
    required String smartcardNumber,
    String? packageCode,
    String? variationCode,
    required double amount,
    String? customerName,
    String? userPin,
    String? phone,
  }) {
    final planCode = packageCode ?? variationCode ?? 'Package';
    return _purchase(
      userId: userId,
      serviceType: 'cable',
      network: provider,
      recipient: smartcardNumber,
      plan: planCode,
      amount: amount,
      dispatch: () => VtuApiService.instance.purchaseCableTv(
        cableType: provider,
        smartcardNumber: smartcardNumber,
        variationCode: planCode,
        phone: (phone != null && phone.isNotEmpty) ? phone : '08000000000',
        amount: amount,
        customerName: customerName ?? 'Avotek Subscriber',
        pin: userPin,
      ),
    );
  }

  /// Electricity meter verification through the provider proxy.
  Future<VerificationResponse> verifyMeter({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    try {
      final res = await VtuApiService.instance.verifyMeter(
        company: disco,
        meterNumber: meterNumber,
        meterType: meterType,
      );

      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : res;
      final name =
          data['customer_name']?.toString() ??
          data['name']?.toString() ??
          '';
      final address =
          data['customer_address']?.toString() ??
          data['address']?.toString() ??
          '';
      final discoName = data['disco']?.toString() ?? disco;

      return VerificationResponse(
        isValid:
            res['success'] == true ||
            data['valid'] == true ||
            name.trim().isNotEmpty,
        customerName: name.isNotEmpty ? name : 'Verified Customer',
        identifier: meterNumber,
        details: '$discoName ($meterType) • $address',
      );
    } catch (e) {
      debugPrint('Meter verify fallback: $e');
      return VerificationResponse(
        isValid: false,
        customerName: '',
        identifier: meterNumber,
        details: 'Could not verify this meter. Check the details and retry.',
      );
    }
  }

  /// Electricity bill payment / prepaid token through the provider proxy.
  Future<OrderResult> payElectricity({
    required dynamic userId,
    required String disco,
    required String meterNumber,
    required String meterType,
    required double amount,
    String? customerName,
    String? customerAddress,
    String? phone,
    String? userPin,
  }) {
    return _purchase(
      userId: userId,
      serviceType: 'electricity',
      network: disco,
      recipient: meterNumber,
      plan: '$disco $meterType',
      amount: amount,
      dispatch: () => VtuApiService.instance.purchaseElectricity(
        company: disco,
        meterNumber: meterNumber,
        meterType: meterType,
        phone: (phone != null && phone.isNotEmpty) ? phone : '08000000000',
        amount: amount,
        customerName: customerName ?? 'Avotek Customer',
        customerAddress: customerAddress,
        pin: userPin,
      ),
    );
  }
}
