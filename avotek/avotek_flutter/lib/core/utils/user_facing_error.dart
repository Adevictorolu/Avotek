String userFacingError(
  Object error, {
  String fallback = 'We could not complete that request. Please try again.',
}) {
  final message = error.toString().trim();
  final normalized = message.toLowerCase();

  const technicalMarkers = [
    'postgrest',
    'postgres',
    'pgrst',
    'sqlstate',
    'sql error',
    'database error',
    'duplicate key',
    'constraint',
    'violates',
    'violates row-level security',
    'permission denied for table',
    '23502',
    '23503',
    '23505',
    '23514',
    '42p01',
    '42703',
    'relation ',
    'column ',
    'schema cache',
    'function public.',
    'stack trace',
  ];
  if (technicalMarkers.any(normalized.contains)) return fallback;

  if (normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('connection timed out') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('clientexception')) {
    return 'Connection problem. Check your internet and try again.';
  }

  final cleaned = message.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
  return cleaned.isEmpty ? fallback : cleaned;
}
