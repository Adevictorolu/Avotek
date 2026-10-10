class ServiceCatalog {
  final int id;
  final String serviceType;
  final String name;
  final String variationCode;
  final String provider;
  final double costPrice;
  final double defaultMarkup;
  final bool active;

  const ServiceCatalog({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.variationCode,
    required this.provider,
    required this.costPrice,
    required this.defaultMarkup,
    this.active = true,
  });

  double get sellingPrice => costPrice + defaultMarkup;

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_type': serviceType,
        'name': name,
        'variation_code': variationCode,
        'provider': provider,
        'cost_price': costPrice,
        'default_markup': defaultMarkup,
        'active': active,
      };

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) => ServiceCatalog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        serviceType: json['service_type'] as String? ?? 'data',
        name: json['name'] as String? ?? '',
        variationCode: json['variation_code'] as String? ?? '',
        provider: json['provider'] as String? ?? '',
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
        defaultMarkup: (json['default_markup'] as num?)?.toDouble() ?? 0.0,
        active: json['active'] as bool? ?? true,
      );
}

class VtuOrder {
  final dynamic id;
  final String userId;
  final String serviceType;
  final String network;
  final String phone;
  final String plan;
  final double amount;
  final String status; // 'successful' | 'pending' | 'failed'
  final String? providerReference;
  final String? token; // For electricity tokens
  final DateTime createdAt;

  const VtuOrder({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.network,
    required this.phone,
    required this.plan,
    required this.amount,
    this.status = 'successful',
    this.providerReference,
    this.token,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'service_type': serviceType,
        'network': network,
        'phone': phone,
        'plan': plan,
        'amount': amount,
        'status': status,
        'provider_reference': providerReference,
        'token': token,
        'created_at': createdAt.toIso8601String(),
      };

  factory VtuOrder.fromJson(Map<String, dynamic> json) => VtuOrder(
        id: json['id'],
        userId: json['user_id']?.toString() ?? '',
        serviceType: json['service_type'] as String? ?? 'data',
        network: json['network'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        plan: json['plan'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'successful',
        providerReference: json['provider_reference'] as String?,
        token: json['token'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// Aliases for compatibility with existing service screens
typedef Order = VtuOrder;

class OrderResult {
  final bool success;
  final String message;
  final VtuOrder order;
  final double balanceRemaining;
  final String? token;
  final String? units;

  const OrderResult({
    required this.success,
    required this.message,
    required this.order,
    this.balanceRemaining = 0.0,
    this.token,
    this.units,
  });
}

class VerificationResponse {
  final bool isValid;
  final String customerName;
  final String identifier;
  final String? details;

  const VerificationResponse({
    required this.isValid,
    required this.customerName,
    required this.identifier,
    this.details,
  });
}

class Beneficiary {
  final int id;
  final String userId;
  final String name;
  final String phone;
  final String network;
  final String serviceType;

  const Beneficiary({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.network,
    required this.serviceType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'network': network,
        'service_type': serviceType,
      };

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: json['user_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        network: json['network'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? '',
      );
}
