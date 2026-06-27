class DateUtils {
  /// Parse date string in DD/M format to DateTime (assuming current year)
  static DateTime? parseShortDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 2) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = DateTime.now().year;
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse date string in DD/MM/YYYY format
  static DateTime? parseFullDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate months between two dates
  static int monthsBetween(DateTime from, DateTime to) {
    int months = (to.year - from.year) * 12 + (to.month - from.month);
    if (to.day < from.day) months--;
    return months;
  }
}
