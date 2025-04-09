import 'package:intl/intl.dart';

/// 날짜 및 시간 포맷팅을 위한 유틸리티 클래스
class DateFormatter {
  /// yyyy년 MM월 dd일 형식으로 변환 (예: 2025년 4월 8일)
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }

  /// yyyy-MM-dd 형식으로 변환 (예: 2025-04-08)
  static String formatDateYMD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// HH:mm 형식으로 시간 변환 (예: 14:30)
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// yyyy년 MM월 dd일 HH:mm 형식으로 변환 (예: 2025년 4월 8일 14:30)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 HH:mm').format(dateTime);
  }

  /// 전체 날짜/시간 표시 (예: 2025년 4월 8일 화요일 오후 2시 30분)
  static String formatFullDateTime(DateTime dateTime) {
    final String weekday = _getKoreanWeekday(dateTime.weekday);
    final String amPm = dateTime.hour < 12 ? '오전' : '오후';
    final int hour = dateTime.hour <= 12 ? dateTime.hour : dateTime.hour - 12;

    return DateFormat('yyyy년 M월 d일').format(dateTime) +
        ' $weekday $amPm ${hour}시 ${dateTime.minute}분';
  }

  /// N시간/일/월/년 전 형식으로 변환 (예: 3시간 전, 2일 전)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 요일을 한글로 변환
  static String _getKoreanWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월요일';
      case DateTime.tuesday:
        return '화요일';
      case DateTime.wednesday:
        return '수요일';
      case DateTime.thursday:
        return '목요일';
      case DateTime.friday:
        return '금요일';
      case DateTime.saturday:
        return '토요일';
      case DateTime.sunday:
        return '일요일';
      default:
        return '';
    }
  }

  /// 시간대 문자열을 DateTime으로 변환 (예: "14:30" -> DateTime)
  static DateTime timeStringToDateTime(
    String timeString, {
    DateTime? baseDate,
  }) {
    final base = baseDate ?? DateTime.now();
    final parts = timeString.split(':');

    if (parts.length != 2) {
      throw FormatException('Invalid time format. Expected "HH:MM"');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  /// 두 시간 문자열 사이의 차이를 분으로 계산 (예: "14:30", "16:00" -> 90)
  static int calculateMinutesBetween(String startTime, String endTime) {
    final start = timeStringToDateTime(startTime);
    final end = timeStringToDateTime(endTime);
    return end.difference(start).inMinutes;
  }

  /// 두 시간 문자열 사이의 차이를 시간:분 형식으로 반환 (예: "14:30", "16:45" -> "2시간 15분")
  static String calculateDuration(String startTime, String endTime) {
    final minutes = calculateMinutesBetween(startTime, endTime);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours시간 $mins분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$mins분';
    }
  }
}
