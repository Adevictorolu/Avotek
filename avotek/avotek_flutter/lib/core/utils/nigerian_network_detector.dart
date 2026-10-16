class NigerianNetworkDetector {
  static const Map<String, String> _prefixToNetwork = {
    '0701': 'AIRTEL',
    '07025': 'MTN',
    '07026': 'MTN',
    '0703': 'MTN',
    '0705': 'GLO',
    '0706': 'MTN',
    '0708': 'AIRTEL',
    '0802': 'AIRTEL',
    '0803': 'MTN',
    '0805': 'GLO',
    '0806': 'MTN',
    '0807': 'GLO',
    '0808': 'AIRTEL',
    '0809': '9MOBILE',
    '0810': 'MTN',
    '0811': 'GLO',
    '0812': 'AIRTEL',
    '0813': 'MTN',
    '0814': 'MTN',
    '0815': 'GLO',
    '0816': 'MTN',
    '0817': '9MOBILE',
    '0818': '9MOBILE',
    '0901': 'AIRTEL',
    '0902': 'AIRTEL',
    '0903': 'MTN',
    '0905': 'GLO',
    '0906': 'MTN',
    '0907': 'AIRTEL',
    '0908': '9MOBILE',
    '0909': '9MOBILE',
    '0911': 'AIRTEL',
    '0912': 'AIRTEL',
    '0913': 'MTN',
    '0915': 'GLO',
    '0916': 'MTN',
  };

  static String? detect(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final localNumber = digits.startsWith('234')
        ? '0${digits.substring(3)}'
        : digits;
    if (localNumber.length != 11 || !localNumber.startsWith('0')) return null;

    final fiveDigitPrefix = localNumber.substring(0, 5);
    return _prefixToNetwork[fiveDigitPrefix] ??
        _prefixToNetwork[localNumber.substring(0, 4)];
  }
}
