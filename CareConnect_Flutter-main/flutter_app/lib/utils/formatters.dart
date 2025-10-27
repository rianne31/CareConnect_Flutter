import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format PHP currency
  static String formatPHP(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
      locale: 'en_PH',
    );
    return formatter.format(amount);
  }
}

class Formatters {
  // Currency formatter for Philippine Peso
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
      locale: 'en_PH',
    );
    return formatter.format(amount);
  }

  // Compact currency (e.g., ₱1.5K, ₱2.3M)
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '₱${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₱${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount);
    }
  }

  // Date formatter
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Date and time formatter
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  // Relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Duration formatter (for auction countdown)
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return 'Ended';

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Percentage formatter
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Blockchain address formatter (shortened)
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Transaction hash formatter
  static String formatTxHash(String hash) {
    if (hash.length < 10) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';
  }
}
