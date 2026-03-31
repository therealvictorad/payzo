import 'package:intl/intl.dart';

final _nairaFmt = NumberFormat('#,##0.00', 'en_NG');

/// Formats a number as Nigerian Naira, e.g. ₦1,000.00
String formatNaira(num amount) => '₦${_nairaFmt.format(amount)}';
