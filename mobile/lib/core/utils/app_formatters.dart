class AppFormatters {
  static const List<String> _months = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _weekDays = <String>[
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static String monthYear(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  static String weekDayShort(DateTime date) {
    return _weekDays[date.weekday - 1];
  }

  static String compactCurrency(num value) {
    final double absValue = value.abs().toDouble();
    final String sign = value < 0 ? '-' : '';

    if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(1)}jt';
    }
    if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(0)}rb';
    }
    return '$sign${absValue.toStringAsFixed(0)}';
  }

  static String currency(num value) {
    final int rounded = value.round();
    final String sign = rounded < 0 ? '-' : '';
    final String grouped = _groupThousands(rounded.abs().toString());
    return '${sign}Rp $grouped';
  }

  static String _groupThousands(String digits) {
    if (digits.length <= 3) {
      return digits;
    }

    final List<String> chars = digits.split('').reversed.toList();
    final List<String> groups = <String>[];

    for (int i = 0; i < chars.length; i += 3) {
      final int end = i + 3 > chars.length ? chars.length : i + 3;
      groups.add(chars.sublist(i, end).reversed.join());
    }

    return groups.reversed.join('.');
  }
}
