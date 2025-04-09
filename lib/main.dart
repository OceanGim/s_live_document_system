import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/screens/auth/login_screen.dart';
import 'package:s_live_document_system/screens/home_screen.dart';
import 'package:s_live_document_system/screens/supabase_test_screen.dart';
import 'package:s_live_document_system/screens/supabase_connection_test.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/utils/supabase_test.dart';

// Supabase 연결 정보 - 웹에서 .env 파일 로드 문제 해결을 위한 하드코딩
const String supabaseUrl = 'https://jdtvghbafmwguwbbujxx.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkdHZnaGJhZm13Z3V3YmJ1anh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5MzU4MDEsImV4cCI6MjA1NzUxMTgwMX0.VOUAiN_YB1VJZl85rnM85fA5L54vvxocEmmZYVnzLiQ';

// Supabase 초기화 상태 Provider
final supabaseInitializedProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 로깅 설정
  Logger.setLogLevel('debug');

  // 앱을 ProviderScope으로 감싸고 실행
  runApp(const ProviderScope(child: MyApp()));
}

/// Supabase 초기화 Provider
final supabaseInitProvider = FutureProvider<bool>((ref) async {
  try {
    // Supabase가 이미 초기화되었는지 확인
    try {
      final _ = Supabase.instance;
      Logger.info('Supabase가 이미 초기화되어 있습니다', tag: 'Main');
      ref.read(supabaseInitializedProvider.notifier).state = true;
      return true;
    } catch (e) {
      // 아직 초기화되지 않음, 계속 진행
      Logger.info('Supabase 초기화 시작', tag: 'Main');
    }

    // 환경 변수 로드 시도 (웹에서는 불가능할 수 있음)
    String url = supabaseUrl;
    String anonKey = supabaseAnonKey;

    try {
      await dotenv.load(fileName: ".env");
      url = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
      anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
      Logger.info('환경 변수 로드 성공', tag: 'Main');
    } catch (e) {
      Logger.warning('환경 변수 로드 실패, 하드코딩된 기본값 사용', tag: 'Main');
      // 웹에서는 .env 로드가 실패할 수 있으므로 하드코딩된 값만 사용
    }

    // 로그로 확인
    Logger.info('Supabase URL: $url', tag: 'Main');
    Logger.info(
      'Supabase Anon Key: ${anonKey.substring(0, 20)}...',
      tag: 'Main',
    );

    // Supabase 초기화 시도
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true, // 프로덕션에서는 false로 설정
    );

    Logger.info('Supabase 초기화 성공', tag: 'Main');
    ref.read(supabaseInitializedProvider.notifier).state = true;
    return true;
  } catch (e, stack) {
    Logger.error(
      'Supabase 초기화 오류 발생',
      error: e,
      stackTrace: stack,
      tag: 'Main',
    );
    return false;
  }
});

/// Supabase 테스트 화면 관련 Provider
final showSupabaseTestProvider = StateProvider<bool>((ref) => false);
final showConnectionTestProvider = StateProvider<bool>((ref) => true);

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 Supabase 초기화 진행
    ref.read(supabaseInitProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Supabase 초기화 상태 확인
    final isSupabaseInitialized = ref.watch(supabaseInitializedProvider);
    final initProgress = ref.watch(supabaseInitProvider);

    return MaterialApp(
      title: '라이브 문서 시스템',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
      home:
          isSupabaseInitialized
              ? _buildMainScreen()
              : _buildLoadingScreen(initProgress),
    );
  }

  // 로딩 화면
  Widget _buildLoadingScreen(AsyncValue<bool> initProgress) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              '서버 연결 중...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            if (initProgress.hasError)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      '연결 오류: ${initProgress.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(supabaseInitProvider);
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 메인 화면 (초기화 완료 후)
  Widget _buildMainScreen() {
    // 인증 상태 감시
    final authState = ref.watch(authProvider);
    final showConnectionTest = ref.watch(showConnectionTestProvider);

    // 연결 테스트 화면 우선 표시
    if (showConnectionTest) {
      return const SupabaseConnectionTestScreen();
    }

    // 일반 테스트 화면 또는 메인 화면 표시
    return ref.watch(showSupabaseTestProvider)
        ? const SupabaseTestScreen()
        : (authState.isLoggedIn ? const HomeScreen() : const LoginScreen());
  }
}

// PDF 기능은 document_service.dart로 이동됨
