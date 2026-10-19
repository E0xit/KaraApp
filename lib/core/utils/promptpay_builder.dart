String _tlv(String tag, String value) =>
    '$tag${value.length.toString().padLeft(2, '0')}$value';

int _crc16(String s) {
  var crc = 0xFFFF;
  for (final unit in s.codeUnits) {
    crc ^= unit << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc;
}

String buildPromptPayPayload(String phone, double amount) {
  final target = '0066${phone.substring(1)}';
  final merchant = _tlv(
    '29',
    _tlv('00', 'A000000677010111') + _tlv('01', target),
  );
  final data = _tlv('00', '01') +
      _tlv('01', '12') +
      merchant +
      _tlv('58', 'TH') +
      _tlv('53', '764') +
      _tlv('54', amount.toStringAsFixed(2)) +
      '6304';
  final crc = _crc16(data).toRadixString(16).toUpperCase().padLeft(4, '0');
  return data + crc;
}