import 'package:intl/intl.dart';

class DateUtils {
  // Format date as yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Parse date from string in yyyy-MM-dd format
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
  
  // Get the first day of the month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get the last day of the month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  // Format month and year
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  // Get a list of months between two dates
  static List<DateTime> getMonthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    
    var current = getFirstDayOfMonth(start);
    final lastMonth = getFirstDayOfMonth(end);
    
    while (current.compareTo(lastMonth) <= 0) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    
    return months;
  }
}