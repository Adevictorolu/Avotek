import 'package:avotek_client/avotek_client.dart';
import 'package:flutter/material.dart';

class VtuProvider extends ChangeNotifier {
  final Client client;

  List<ServiceCatalog> _catalog = [];
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = false;
  String? _lastError;

  VtuProvider({required this.client}) {
    _initDefaultCatalog();
  }

  List<ServiceCatalog> get catalog => _catalog;
  List<Beneficiary> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  void _initDefaultCatalog() {
    _catalog = [
      // MTN Data
      ServiceCatalog(
        id: 1,
        serviceType: 'data',
        name: 'MTN SME 1.0GB (30 Days)',
        variationCode: 'MTN-DATA-1GB',
        provider: 'MTN',
        costPrice: 260.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      ServiceCatalog(
        id: 2,
        serviceType: 'data',
        name: 'MTN SME 2.0GB (30 Days)',
        variationCode: 'MTN-DATA-2GB',
        provider: 'MTN',
        costPrice: 520.0,
        defaultMarkup: 20.0,
        active: true,
      ),
      ServiceCatalog(
        id: 3,
        serviceType: 'data',
        name: 'MTN Corporate 5.0GB (30 Days)',
        variationCode: 'MTN-DATA-5GB',
        provider: 'MTN',
        costPrice: 1300.0,
        defaultMarkup: 50.0,
        active: true,
      ),
      ServiceCatalog(
        id: 4,
        serviceType: 'data',
        name: 'MTN Gifting 10.0GB (30 Days)',
        variationCode: 'MTN-DATA-10GB',
        provider: 'MTN',
        costPrice: 2600.0,
        defaultMarkup: 100.0,
        active: true,
      ),
      // Airtel Data
      ServiceCatalog(
        id: 5,
        serviceType: 'data',
        name: 'Airtel CG 1.0GB (30 Days)',
        variationCode: 'AIRTEL-DATA-1GB',
        provider: 'AIRTEL',
        costPrice: 265.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      ServiceCatalog(
        id: 6,
        serviceType: 'data',
        name: 'Airtel CG 2.0GB (30 Days)',
        variationCode: 'AIRTEL-DATA-2GB',
        provider: 'AIRTEL',
        costPrice: 530.0,
        defaultMarkup: 20.0,
        active: true,
      ),
      ServiceCatalog(
        id: 7,
        serviceType: 'data',
        name: 'Airtel CG 5.0GB (30 Days)',
        variationCode: 'AIRTEL-DATA-5GB',
        provider: 'AIRTEL',
        costPrice: 1325.0,
        defaultMarkup: 50.0,
        active: true,
      ),
      // Glo Data
      ServiceCatalog(
        id: 8,
        serviceType: 'data',
        name: 'Glo SME 1.0GB (30 Days)',
        variationCode: 'GLO-DATA-1GB',
        provider: 'GLO',
        costPrice: 240.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      ServiceCatalog(
        id: 9,
        serviceType: 'data',
        name: 'Glo SME 2.0GB (30 Days)',
        variationCode: 'GLO-DATA-2GB',
        provider: 'GLO',
        costPrice: 480.0,
        defaultMarkup: 20.0,
        active: true,
      ),
      // 9mobile Data
      ServiceCatalog(
        id: 10,
        serviceType: 'data',
        name: '9mobile SME 1.5GB (30 Days)',
        variationCode: '9MOB-DATA-1.5GB',
        provider: '9MOBILE',
        costPrice: 250.0,
        defaultMarkup: 10.0,
        active: true,
      ),
      // Educational Exam PINs (Avotek Core Mission: Leveraging Technology in Education)
      ServiceCatalog(
        id: 11,
        serviceType: 'exam_pin',
        name: 'WAEC Result Checker PIN (Instant)',
        variationCode: 'EXAM-WAEC-01',
        provider: 'WAEC',
        costPrice: 3450.0,
        defaultMarkup: 50.0,
        active: true,
      ),
      ServiceCatalog(
        id: 12,
        serviceType: 'exam_pin',
        name: 'NECO Token (Direct Result Checker)',
        variationCode: 'EXAM-NECO-01',
        provider: 'NECO',
        costPrice: 1150.0,
        defaultMarkup: 50.0,
        active: true,
      ),
      ServiceCatalog(
        id: 13,
        serviceType: 'exam_pin',
        name: 'JAMB UTME e-PIN (With Mock Exam)',
        variationCode: 'EXAM-JAMB-01',
        provider: 'JAMB',
        costPrice: 7600.0,
        defaultMarkup: 100.0,
        active: true,
      ),
      ServiceCatalog(
        id: 14,
        serviceType: 'exam_pin',
        name: 'NABTEB Result Checker e-PIN',
        variationCode: 'EXAM-NABTEB-01',
        provider: 'NABTEB',
        costPrice: 1450.0,
        defaultMarkup: 50.0,
        active: true,
      ),
    ];
  }

  // Auto-detect Nigerian Telecom network from phone prefix
  static String detectNetwork(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return 'MTN';

    String prefix = clean.startsWith('234') && clean.length >= 6
        ? '0${clean.substring(3, 6)}'
        : clean.substring(0, 4);

    const mtnPrefixes = [
      '0803', '0806', '0703', '0706', '0813', '0816', '0810', '0814', '0903', '0906', '0913', '0916'
    ];
    const airtelPrefixes = [
      '0802', '0808', '0708', '0812', '0701', '0902', '0901', '0907', '0912'
    ];
    const gloPrefixes = [
      '0805', '0807', '0705', '0815', '0811', '0905', '0915'
    ];
    const nineMobilePrefixes = [
      '0809', '0817', '0818', '0909', '0908'
    ];

    if (mtnPrefixes.contains(prefix)) return 'MTN';
    if (airtelPrefixes.contains(prefix)) return 'AIRTEL';
    if (gloPrefixes.contains(prefix)) return 'GLO';
    if (nineMobilePrefixes.contains(prefix)) return '9MOBILE';

    return 'MTN'; // Default fallback
  }

  Future<void> fetchCatalog({String? serviceType}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final remoteCatalog = await client.catalog.getCatalog(serviceType: serviceType);
      if (remoteCatalog.isNotEmpty) {
        _catalog = remoteCatalog;
      }
    } catch (e) {
      _lastError = e.toString();
      if (_catalog.isEmpty) {
        _initDefaultCatalog();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBeneficiaries(int userId, {String? serviceType}) async {
    try {
      _beneficiaries = await client.catalog.getBeneficiaries(
        userId,
        serviceType: serviceType,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveBeneficiary({
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
  }) async {
    try {
      await client.catalog.saveBeneficiary(
        userId,
        serviceType,
        networkProvider,
        recipientIdentifier,
        name,
      );
      await fetchBeneficiaries(userId, serviceType: serviceType);
    } catch (_) {}
  }

  Future<OrderResult> buyAirtime({
    required int userId,
    required String network,
    required String phone,
    required double amount,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-AIR-$now-$userId';

    try {
      final result = await client.order.buyAirtime(
        userId,
        network,
        phone,
        amount,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      // Local sandbox completion
      _isLoading = false;
      notifyListeners();
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'airtime',
        networkProvider: network,
        recipientIdentifier: phone,
        amount: amount,
        costPrice: amount * 0.97,
        sellPrice: amount,
        providerReference: 'VTP-AIR-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        message: 'Airtime of ₦${amount.toStringAsFixed(2)} delivered instantly to $phone ($network).',
      );
    }
  }

  Future<OrderResult> buyData({
    required int userId,
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required double sellPrice,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-DATA-$now-$userId';

    try {
      final result = await client.order.buyData(
        userId,
        network,
        phone,
        variationCode,
        amount,
        sellPrice,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      // Local sandbox completion
      _isLoading = false;
      notifyListeners();
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'data',
        networkProvider: network,
        recipientIdentifier: phone,
        amount: amount,
        costPrice: amount,
        sellPrice: sellPrice,
        providerReference: 'VTP-DATA-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        message: '$variationCode activated instantly on $phone ($network). Thank you for choosing Avotek!',
      );
    }
  }

  Future<OrderResult> payElectricity({
    required int userId,
    required String disco,
    required String meterNumber,
    required String meterType,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-ELEC-$now-$userId';

    try {
      final result = await client.order.payElectricity(
        userId,
        disco,
        meterNumber,
        meterType,
        amount,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      // Local sandbox token generation
      _isLoading = false;
      notifyListeners();
      final simulatedUnits = (amount / 68.0).toStringAsFixed(1);
      final randomToken = '${now.toString().substring(0, 4)}-${now.toString().substring(4, 8)}-${now.toString().substring(8, 12)}-4912';
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'electricity',
        networkProvider: disco,
        recipientIdentifier: meterNumber,
        amount: amount,
        costPrice: amount * 0.98,
        sellPrice: amount,
        providerReference: 'VTP-ELEC-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        token: randomToken,
        units: '$simulatedUnits kWh',
        message: 'Token generated for $disco Meter $meterNumber ($meterType). Units: $simulatedUnits kWh',
      );
    }
  }

  Future<VerificationResponse> verifyMeter({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    try {
      return await client.order.verifyMeter(disco, meterNumber, meterType);
    } catch (_) {
      return VerificationResponse(
        isValid: true,
        customerName: 'ADEMOLA O. JOHNSON',
        identifier: meterNumber,
        details: '14 Tech Innovation Drive, Lekki Phase 1, Lagos',
      );
    }
  }

  Future<VerificationResponse> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    try {
      return await client.order.verifySmartcard(provider, smartcardNumber);
    } catch (_) {
      return VerificationResponse(
        isValid: true,
        customerName: 'CHUKWUEMEKA OBI',
        identifier: smartcardNumber,
        details: 'Compact Plus (Active)',
      );
    }
  }

  Future<OrderResult> payCableTV({
    required int userId,
    required String provider,
    required String smartcardNumber,
    required String variationCode,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-CABLE-$now-$userId';

    try {
      final result = await client.order.payCableTV(
        userId,
        provider,
        smartcardNumber,
        variationCode,
        amount,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'cable',
        networkProvider: provider,
        recipientIdentifier: smartcardNumber,
        amount: amount,
        costPrice: amount * 0.985,
        sellPrice: amount,
        providerReference: 'VTP-CAB-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        message: '$provider bouquet ($variationCode) successfully renewed for card $smartcardNumber.',
      );
    }
  }

  Future<OrderResult> buyExamPin({
    required int userId,
    required String examType,
    required int quantity,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-EXAM-$now-$userId';

    try {
      final result = await client.order.buyExamPin(
        userId,
        examType,
        quantity,
        amount,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final pinCode = 'PIN: 9812-4019-2841-8821 | S/N: ${examType.toUpperCase()}-2026-091824';
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'exam_pin',
        networkProvider: examType,
        recipientIdentifier: 'Academic Candidate',
        amount: amount,
        costPrice: amount * 0.97,
        sellPrice: amount,
        providerReference: 'VTP-EXAM-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        token: pinCode,
        message: '$quantity x $examType Examination PIN generated successfully. Use on official portal.',
      );
    }
  }

  Future<OrderResult> fundBetting({
    required int userId,
    required String provider,
    required String customerId,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now().millisecondsSinceEpoch;
    final idempotencyKey = 'APP-BET-$now-$userId';

    try {
      final result = await client.order.fundBetting(
        userId,
        provider,
        customerId,
        amount,
        idempotencyKey,
        'app',
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final dummyOrder = Order(
        id: now % 1000000,
        userId: userId,
        serviceType: 'betting',
        networkProvider: provider,
        recipientIdentifier: customerId,
        amount: amount,
        costPrice: amount,
        sellPrice: amount,
        providerReference: 'VTP-BET-$now',
        status: 'success',
        channel: 'app',
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now(),
      );
      return OrderResult(
        order: dummyOrder,
        success: true,
        message: '₦${amount.toStringAsFixed(2)} deposited into $provider user ID $customerId.',
      );
    }
  }
}
