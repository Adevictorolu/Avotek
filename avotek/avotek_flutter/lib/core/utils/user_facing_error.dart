/// Strips upstream provider names and database references from user-facing strings.
String sanitizeDisplayMessage(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(RegExp(r'bigisub(\.ng)?', caseSensitive: false), 'Avotek Gateway')
      .replaceAll(RegExp(r'bilalsadasub(\.com)?', caseSensitive: false), 'Avotek Gateway')
      .replaceAll(RegExp(r'bilal\s*sada\s*sub', caseSensitive: false), 'Avotek Gateway')
      .replaceAll(RegExp(r'bilal', caseSensitive: false), 'Avotek')
      .replaceAll(RegExp(r'postgrest(exception)?', caseSensitive: false), 'System Gateway')
      .replaceAll(RegExp(r'postgres(ql)?', caseSensitive: false), 'System Database')
      .replaceAll(RegExp(r'supabase', caseSensitive: false), 'Avotek Cloud');
}

String userFacingError(
  Object error, {
  String fallback = 'We could not complete that request. Please try again.',
}) {
  final message = error.toString().trim();
  final normalized = message.toLowerCase();

  // 1. Network / connectivity issues
  if (normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('failed to fetch') ||
      normalized.contains('connection timed out') ||
      normalized.contains('connection refused') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('handshakeexception') ||
      normalized.contains('httpexception') ||
      normalized.contains('timeoutexception') ||
      normalized.contains('timed out') ||
      normalized.contains('clientexception')) {
    return 'Connection problem. Check your internet and try again.';
  }

  // 2. Auth & credential specifics
  if (normalized.contains('invalid login credentials') ||
      normalized.contains('invalid_credentials') ||
      normalized.contains('invalid_grant')) {
    return 'Incorrect email or password. Please verify your login credentials.';
  }

  if (normalized.contains('email not confirmed')) {
    return 'Please verify your email address before signing in.';
  }

  if (normalized.contains('user already registered') ||
      (normalized.contains('23505') && (normalized.contains('email') || normalized.contains('user')))) {
    return 'An account with this email address already exists.';
  }

  if (normalized.contains('insufficient') && normalized.contains('balance')) {
    return 'Insufficient wallet balance. Please fund your wallet and try again.';
  }

  if (normalized.contains('jwt') && (normalized.contains('expired') || normalized.contains('invalid'))) {
    return 'Your session has expired. Please sign in again.';
  }

  if (normalized.contains('over_email_send_rate_limit') ||
      normalized.contains('too many requests') ||
      normalized.contains('rate limit')) {
    return 'Too many requests. Please wait a moment before trying again.';
  }

  // 3. Technical / Database / Postgrest markers
  const technicalMarkers = [
    'postgrest',
    'postgres',
    'pgrst',
    'sqlstate',
    'sql error',
    'syntax error',
    'database error',
    'databaseexception',
    'internal server error',
    'server error',
    'duplicate key',
    'constraint',
    'violates',
    'violates row-level security',
    'permission denied for table',
    'permission denied',
    '23502',
    '23503',
    '23505',
    '23514',
    '42p01',
    '42703',
    '42501',
    'relation ',
    'column ',
    'functionexception',
    'schema cache',
    'function public.',
    'stack trace',
    'format exception',
    'typeerror',
    'nosuchmethoderror',
    'null check operator',
    'unexpected null value',
    'supabase',
    'subase',
    'gotrue',
    'authexception',
    'authapi',
    'bigisub',
    'bilalsadasub',
  ];

  if (technicalMarkers.any(normalized.contains)) {
    return fallback;
  }

  var cleaned = message.replaceFirst(
    RegExp(r'^(Exception|Error|PostgrestException|AuthException):\s*', caseSensitive: false),
    '',
  );
  cleaned = sanitizeDisplayMessage(cleaned);
  return cleaned.isEmpty ? fallback : cleaned;
}
