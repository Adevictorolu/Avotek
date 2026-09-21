import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class CatalogEndpoint extends Endpoint {
  Future<List<ServiceCatalog>> getCatalog(
    Session session, {
    String? serviceType,
    String? provider,
  }) async {
    var items = await ServiceCatalog.db.find(
      session,
      where: (c) =>
          (serviceType != null && serviceType.isNotEmpty ? c.serviceType.equals(serviceType) : Constant.bool(true)) &
          (provider != null && provider.isNotEmpty ? c.provider.equals(provider) : Constant.bool(true)),
    );

    if (items.isEmpty) {
      await _seedDefaultCatalog(session);
      items = await ServiceCatalog.db.find(
        session,
        where: (c) =>
            (serviceType != null && serviceType.isNotEmpty ? c.serviceType.equals(serviceType) : Constant.bool(true)) &
            (provider != null && provider.isNotEmpty ? c.provider.equals(provider) : Constant.bool(true)),
      );
    }

    return items;
  }

  Future<List<Beneficiary>> getBeneficiaries(
    Session session,
    int userId, {
    String? serviceType,
  }) async {
    return await Beneficiary.db.find(
      session,
      where: (b) =>
          b.userId.equals(userId) &
          (serviceType != null && serviceType.isNotEmpty ? b.serviceType.equals(serviceType) : Constant.bool(true)),
      orderBy: (b) => b.createdAt,
      orderDescending: true,
    );
  }

  Future<Beneficiary> saveBeneficiary(
    Session session,
    int userId,
    String serviceType,
    String networkProvider,
    String recipientIdentifier,
    String name,
  ) async {
    final existing = await Beneficiary.db.findFirstRow(
      session,
      where: (b) =>
          b.userId.equals(userId) &
          b.serviceType.equals(serviceType) &
          b.recipientIdentifier.equals(recipientIdentifier),
    );

    if (existing != null) {
      existing.name = name;
      return await Beneficiary.db.updateRow(session, existing);
    }

    return await Beneficiary.db.insertRow(
      session,
      Beneficiary(
        userId: userId,
        serviceType: serviceType,
        networkProvider: networkProvider,
        recipientIdentifier: recipientIdentifier,
        name: name,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<bool> deleteBeneficiary(Session session, int beneficiaryId, int userId) async {
    final b = await Beneficiary.db.findById(session, beneficiaryId);
    if (b != null && b.userId == userId) {
      await Beneficiary.db.deleteRow(session, b);
      return true;
    }
    return false;
  }

  Future<void> _seedDefaultCatalog(Session session) async {
    final seedItems = [
      // MTN Data
      ServiceCatalog(serviceType: 'data', provider: 'MTN', variationCode: 'mtn-1gb', name: 'MTN 1GB SME (30 Days)', costPrice: 240, defaultMarkup: 40, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'MTN', variationCode: 'mtn-2gb', name: 'MTN 2GB SME (30 Days)', costPrice: 480, defaultMarkup: 80, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'MTN', variationCode: 'mtn-5gb', name: 'MTN 5GB SME (30 Days)', costPrice: 1200, defaultMarkup: 150, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'MTN', variationCode: 'mtn-10gb', name: 'MTN 10GB SME (30 Days)', costPrice: 2400, defaultMarkup: 300, active: true),
      // Airtel Data
      ServiceCatalog(serviceType: 'data', provider: 'AIRTEL', variationCode: 'airtel-1gb', name: 'Airtel 1GB Corporate (30 Days)', costPrice: 235, defaultMarkup: 45, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'AIRTEL', variationCode: 'airtel-2gb', name: 'Airtel 2GB Corporate (30 Days)', costPrice: 470, defaultMarkup: 90, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'AIRTEL', variationCode: 'airtel-5gb', name: 'Airtel 5GB Corporate (30 Days)', costPrice: 1175, defaultMarkup: 175, active: true),
      // Glo Data
      ServiceCatalog(serviceType: 'data', provider: 'GLO', variationCode: 'glo-1gb', name: 'Glo 1GB Gift (30 Days)', costPrice: 230, defaultMarkup: 50, active: true),
      ServiceCatalog(serviceType: 'data', provider: 'GLO', variationCode: 'glo-3gb', name: 'Glo 3GB Gift (30 Days)', costPrice: 690, defaultMarkup: 110, active: true),
      // 9mobile Data
      ServiceCatalog(serviceType: 'data', provider: '9MOBILE', variationCode: '9mob-1gb', name: '9mobile 1GB Corporate', costPrice: 210, defaultMarkup: 60, active: true),
      // Cable TV
      ServiceCatalog(serviceType: 'tv', provider: 'DSTV', variationCode: 'dstv-padi', name: 'DStv Padi', costPrice: 3500, defaultMarkup: 100, active: true),
      ServiceCatalog(serviceType: 'tv', provider: 'DSTV', variationCode: 'dstv-yanga', name: 'DStv Yanga', costPrice: 5000, defaultMarkup: 100, active: true),
      ServiceCatalog(serviceType: 'tv', provider: 'GOTV', variationCode: 'gotv-jinja', name: 'GOtv Jinja', costPrice: 3200, defaultMarkup: 100, active: true),
      ServiceCatalog(serviceType: 'tv', provider: 'GOTV', variationCode: 'gotv-jolli', name: 'GOtv Jolli', costPrice: 4750, defaultMarkup: 100, active: true),
      // Exam Pins
      ServiceCatalog(serviceType: 'exam_pin', provider: 'WAEC', variationCode: 'waec-direct', name: 'WAEC Result Checker', costPrice: 3600, defaultMarkup: 300, active: true),
      ServiceCatalog(serviceType: 'exam_pin', provider: 'JAMB', variationCode: 'jamb-utme', name: 'JAMB Profile Code / PIN', costPrice: 4600, defaultMarkup: 400, active: true),
    ];

    for (final item in seedItems) {
      await ServiceCatalog.db.insertRow(session, item);
    }
  }
}
