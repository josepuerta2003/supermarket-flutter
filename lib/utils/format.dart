/// Utilidades de formato (estilo Venezuela: 1.234,56).

String _group(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return (n < 0 ? '-' : '') + buf.toString();
}

String formatNumber(double value) {
  final cents = (value * 100).round();
  final intPart = cents ~/ 100;
  final dec = (cents.abs() % 100).toString().padLeft(2, '0');
  return '${_group(intPart)},$dec';
}

String usd(double value) => '\$${formatNumber(value)}';

String bs(double value) => 'Bs ${formatNumber(value)}';

String two(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'am' : 'pm';
  return '$h:${two(d.minute)} $ampm';
}

String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String formatDateTime(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  final prefix = diff == 0
      ? 'Hoy'
      : diff == 1
          ? 'Ayer'
          : formatDate(d);
  return '$prefix, ${formatTime(d)}';
}

/// Minúsculas y sin acentos, para búsquedas.
String normalize(String s) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  var r = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    r = r.replaceAll(from[i], to[i]);
  }
  return r;
}

const List<String> weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
