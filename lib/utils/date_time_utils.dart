import 'package:intl/intl.dart';

enum TimeIntervalType { oneMonth, halfYear, yearLong, multipleYears }

class DateTimeUtils {
  static TimeIntervalType getIntervalTypeFromDuration(int millisecondsDuration) {
    var duration = Duration(milliseconds: millisecondsDuration);

    if (duration.inDays <= 30) {
      return TimeIntervalType.oneMonth;
    } else if (duration.inDays <= (365 ~/ 2)) {
      return TimeIntervalType.halfYear;
    } else if (duration.inDays <= 365) {
      return TimeIntervalType.yearLong;
    } else {
      return TimeIntervalType.multipleYears;
    }
  }

  static String getMonthString(double x) {
    var date = DateTime.fromMillisecondsSinceEpoch(x.toInt());
    return DateFormat('MMM').format(date);
  }

  static String getMonthStringLong(double x) {
    var date = DateTime.fromMillisecondsSinceEpoch(x.toInt());
    return DateFormat('MMMM').format(date);
  }

  static String getYearString(double x) {
    var date = DateTime.fromMillisecondsSinceEpoch(x.toInt());
    return DateFormat('yyyy').format(date);
  }

  static String getDayString(double x) {
    var date = DateTime.fromMillisecondsSinceEpoch(x.toInt());
    return DateFormat('d').format(date);
  }
}
