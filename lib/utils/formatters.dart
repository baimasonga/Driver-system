import 'package:intl/intl.dart';

String formatDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('MMM d, y  h:mm a').format(dt);
  } catch (_) {
    return iso;
  }
}

String formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('MMM d, y').format(dt);
  } catch (_) {
    return iso;
  }
}

String formatCurrency(num value) => '\$${value.toStringAsFixed(2)}';

String formatKm(num value) => '${NumberFormat('#,##0').format(value)} km';

String formatLiters(num value) => '${value.toStringAsFixed(1)} L';

bool isExpired(String iso) {
  try {
    return DateTime.parse(iso).isBefore(DateTime.now());
  } catch (_) {
    return false;
  }
}

bool isExpiringSoon(String iso, {int withinDays = 30}) {
  try {
    final d = DateTime.parse(iso);
    final now = DateTime.now();
    return d.isAfter(now) && d.difference(now).inDays <= withinDays;
  } catch (_) {
    return false;
  }
}
