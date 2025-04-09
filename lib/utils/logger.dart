/// 로깅을 위한 유틸리티 클래스
class Logger {
  /// 로그 레벨 정의
  static const int _logLevelInfo = 0;
  static const int _logLevelDebug = 1;
  static const int _logLevelWarning = 2;
  static const int _logLevelError = 3;

  /// 현재 로그 레벨 (기본값: INFO)
  static int _currentLogLevel = _logLevelInfo;

  /// 로그 출력 활성화 여부 (기본값: true)
  static bool _isEnabled = true;

  /// 로그 활성화/비활성화 설정
  static void setEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
  }

  /// 로그 레벨 설정
  /// [level]: "info", "debug", "warning", "error" 중 하나
  static void setLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'info':
        _currentLogLevel = _logLevelInfo;
        break;
      case 'debug':
        _currentLogLevel = _logLevelDebug;
        break;
      case 'warning':
        _currentLogLevel = _logLevelWarning;
        break;
      case 'error':
        _currentLogLevel = _logLevelError;
        break;
      default:
        _currentLogLevel = _logLevelInfo; // 기본값
    }
  }

  /// 정보 로그 출력
  static void info(String message, {String? tag}) {
    if (!_isEnabled || _currentLogLevel > _logLevelInfo) return;
    _log('INFO', message, tag: tag);
  }

  /// 디버그 로그 출력
  static void debug(String message, {String? tag}) {
    if (!_isEnabled || _currentLogLevel > _logLevelDebug) return;
    _log('DEBUG', message, tag: tag);
  }

  /// 경고 로그 출력
  static void warning(String message, {String? tag}) {
    if (!_isEnabled || _currentLogLevel > _logLevelWarning) return;
    _log('WARNING', message, tag: tag);
  }

  /// 에러 로그 출력
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || _currentLogLevel > _logLevelError) return;

    _log('ERROR', message, tag: tag);

    if (error != null) {
      print('ERROR: $error');
    }

    if (stackTrace != null) {
      print('STACKTRACE: $stackTrace');
    }
  }

  /// 내부 로그 출력 구현
  static void _log(String level, String message, {String? tag}) {
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final tagStr = tag != null ? '[$tag] ' : '';

    print('$timestamp | $level | ${tagStr}$message');
  }

  /// API 요청 로깅
  static void logApiRequest(
    String url, {
    String? method,
    Map<String, dynamic>? params,
  }) {
    if (!_isEnabled || _currentLogLevel > _logLevelDebug) return;

    final methodStr = method != null ? '[$method] ' : '';
    debug('${methodStr}API 요청: $url');

    if (params != null) {
      debug('파라미터: $params');
    }
  }

  /// API 응답 로깅
  static void logApiResponse(String url, {dynamic response, int? statusCode}) {
    if (!_isEnabled || _currentLogLevel > _logLevelDebug) return;

    final statusStr = statusCode != null ? '(상태코드: $statusCode) ' : '';
    debug('API 응답 ${statusStr}from $url:');

    if (response != null) {
      // 응답이 너무 큰 경우 잘라서 출력
      final responseStr = response.toString();
      if (responseStr.length > 500) {
        debug('${responseStr.substring(0, 500)}... (응답 잘림)');
      } else {
        debug(responseStr);
      }
    }
  }

  /// DB 쿼리 로깅
  static void logDbQuery(String query, {Map<String, dynamic>? params}) {
    if (!_isEnabled || _currentLogLevel > _logLevelDebug) return;

    debug('DB 쿼리: $query');

    if (params != null) {
      debug('DB 파라미터: $params');
    }
  }

  /// 페이지 이동 로깅
  static void logNavigation(String fromPage, String toPage) {
    if (!_isEnabled || _currentLogLevel > _logLevelInfo) return;

    info('화면 이동: $fromPage → $toPage');
  }

  /// 사용자 액션 로깅
  static void logUserAction(String action, {Map<String, dynamic>? details}) {
    if (!_isEnabled || _currentLogLevel > _logLevelInfo) return;

    info('사용자 액션: $action');

    if (details != null) {
      info('상세: $details');
    }
  }
}
