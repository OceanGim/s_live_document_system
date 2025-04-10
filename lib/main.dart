import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/screens/auth/login_screen.dart';
import 'package:s_live_document_system/screens/home_screen.dart';
import 'package:s_live_document_system/screens/supabase_test_screen.dart';
import 'package:s_live_document_system/screens/supabase_connection_test.dart';
import 'package:s_live_document_system/screens/admin/admin_home_screen.dart';
import 'package:s_live_document_system/screens/user/user_home_screen.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/utils/supabase_test.dart';

// Supabase 연결 환경 변수 이름 정의
const String envSupabaseUrl = 'SUPABASE_URL';
const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';

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

    // 환경 변수 로드 시도
    String? url;
    String? anonKey;

    try {
      // 웹 환경인지 확인
      const bool isWeb = identical(0, 0.0);

      if (!isWeb) {
        // 네이티브 환경에서는 .env 파일에서 로드
        await dotenv.load(fileName: ".env");
        url = dotenv.env[envSupabaseUrl];
        anonKey = dotenv.env[envSupabaseAnonKey];
        Logger.info('네이티브용 .env 파일 로드 성공', tag: 'Main');
      } else {
        // 웹 환경에서는 assets에서 환경설정 로드 시도
        try {
          final envString = await rootBundle.loadString('assets/env.json');
          final envMap = json.decode(envString) as Map<String, dynamic>;
          url = envMap[envSupabaseUrl] as String?;
          anonKey = envMap[envSupabaseAnonKey] as String?;
          Logger.info('웹용 환경 설정 파일 로드 성공', tag: 'Main');
        } catch (webError) {
          Logger.warning('웹용 환경 설정 파일 로드 실패: $webError', tag: 'Main');
          // 하드코딩된 값을 사용 (개발 목적으로만)
          url = 'https://jdtvghbafmwguwbbujxx.supabase.co';
          anonKey =
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkdHZnaGJhZm13Z3V3YmJ1anh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5MzU4MDEsImV4cCI6MjA1NzUxMTgwMX0.VOUAiN_YB1VJZl85rnM85fA5L54vvxocEmmZYVnzLiQ';
          Logger.warning('개발용 하드코딩된 값 사용 중 (보안 주의)', tag: 'Main');
        }
      }

      if (url == null || anonKey == null) {
        throw Exception(
          '환경 변수가 로드되지 않았습니다: $envSupabaseUrl 또는 $envSupabaseAnonKey',
        );
      }

      Logger.info('환경 변수 로드 성공', tag: 'Main');
    } catch (e) {
      Logger.error('환경 변수 로드 실패: ${e.toString()}', tag: 'Main');
      rethrow; // Supabase 초기화 진행 불가
    }

    // 로그로 확인
    Logger.info('Supabase URL: $url', tag: 'Main');
    Logger.info(
      'Supabase Anon Key: ${anonKey.substring(0, 20)}...',
      tag: 'Main',
    );

    try {
      // Supabase 초기화 시도
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true, // 프로덕션에서는 false로 설정
      );

      Logger.info('Supabase 초기화 성공', tag: 'Main');
      ref.read(supabaseInitializedProvider.notifier).state = true;
      return true;
    } catch (initError) {
      Logger.error('Supabase 초기화 실패: $initError', tag: 'Main');

      // 연결 오류가 있어도 앱을 사용할 수 있도록 초기화 상태를 true로 설정
      // 이는 개발 중 또는 오프라인 환경에서 앱 테스트를 가능하게 합니다
      Logger.warning('연결 실패하였으나 앱 실행을 계속합니다', tag: 'Main');
      ref.read(supabaseInitializedProvider.notifier).state = true;
      return true;
    }
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
final showConnectionTestProvider = StateProvider<bool>((ref) => false);

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
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                isSupabaseInitialized
                    ? _buildMainScreen()
                    : _buildLoadingScreen(initProgress),
        '/admin': (context) => const AdminHomeScreen(),
        '/user': (context) => const UserHomeScreen(),
      },
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
                        final _ = ref.refresh(supabaseInitProvider);
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

    // 테스트 모드
    if (ref.watch(showSupabaseTestProvider)) {
      return const SupabaseTestScreen();
    }

    // 로그인 상태 확인
    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    // 로그인 상태라면 이메일로 판단하여 직접 화면 반환
    try {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      Logger.debug('메인 화면 결정 - 이메일: $userEmail', tag: 'Main');

      if (userEmail != null && userEmail.toLowerCase() == 'admin@slive.com') {
        Logger.debug('관리자 화면으로 이동', tag: 'Main');
        return const AdminHomeScreen();
      } else {
        Logger.debug('일반 사용자 화면으로 이동', tag: 'Main');
        return const UserHomeScreen();
      }
    } catch (e) {
      Logger.error('사용자 이메일 확인 실패: $e', tag: 'Main');
      // 오류 발생 시 기본적으로 사용자 화면으로 이동
      return const UserHomeScreen();
    }
  }
}

// PDF 기능은 document_service.dart로 이동됨
