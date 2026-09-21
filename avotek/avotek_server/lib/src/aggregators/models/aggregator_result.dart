enum AggregatorStatus {
  success,
  failed,
  pending,
  timeout,
}

class AggregatorResult {
  final AggregatorStatus status;
  final String? providerReference;
  final String? token; // e.g. 20-digit prepaid electricity token
  final String? units; // e.g. "45.2 kWh"
  final String? customerName;
  final String? rawResponse;
  final String? errorMessage;

  const AggregatorResult({
    required this.status,
    this.providerReference,
    this.token,
    this.units,
    this.customerName,
    this.rawResponse,
    this.errorMessage,
  });

  bool get isSuccess => status == AggregatorStatus.success;
  bool get isFailed => status == AggregatorStatus.failed || status == AggregatorStatus.timeout;
}

class ValidationResult {
  final bool isValid;
  final String? customerName;
  final String? rawDetails;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.customerName,
    this.rawDetails,
    this.errorMessage,
  });
}
