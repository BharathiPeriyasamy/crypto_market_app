String formatPrice(double value) {
  final decimals = value >= 1 ? 2 : (value >= 0.01 ? 4 : 6);
  return '\$${_addCommas(value.toStringAsFixed(decimals))}';
}

// Shortens large numbers: 1250000 -> 1.25M
String formatCompact(double value) {
  const units = [(1e12, 'T'), (1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
  for (final (size, suffix) in units) {
    if (value >= size) return '${(value / size).toStringAsFixed(2)}$suffix';
  }
  return value.toStringAsFixed(2);
}

String formatMoney(double value) => '\$${formatCompact(value)}';

String formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String formatDateTime(DateTime time) {
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.day}/${time.month}/${time.year} ${time.hour}:$minute';
}

String _addCommas(String number) {
  final parts = number.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}
