# S-Live Document System

S-Live Document System은 방송 스튜디오 관리를 위한 종합적인 문서 관리 및 대여 시스템입니다.

## 주요 기능

- 사용자 인증 및 관리 (일반 사용자/관리자)
- 문서 관리 (생성, 조회, 수정, 삭제)
- 장비 대여 시스템
- 전자 서명 및 동의서 관리
- 방송/영상 정보 관리
- 통계 및 보고서 생성

## 기술 스택

- Frontend: Flutter (Web, Android, iOS 지원)
- Backend: Supabase
- 데이터베이스: PostgreSQL (Supabase)
- 인증: Supabase Auth
- 스토리지: Supabase Storage
- 상태 관리: Riverpod

## 개발 환경 설정

### 필수 요구사항

- Flutter SDK (최신 버전)
- Dart SDK (최신 버전)
- IDE: Visual Studio Code 또는 Android Studio

### 설치 방법

1. Flutter SDK 설치:
   ```
   https://flutter.dev/docs/get-started/install
   ```

2. 프로젝트 클론:
   ```
   git clone https://github.com/yourusername/s-live_document_system.git
   cd s-live_document_system
   ```

3. 의존성 패키지 설치:
   ```
   flutter pub get
   ```

4. `.env` 파일 생성 (루트 디렉토리에):
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

5. 앱 실행:
   ```
   flutter run -d chrome  # 웹에서 실행
   flutter run            # 연결된 디바이스에서 실행
   ```

## 프로젝트 구조

```
lib/
├── constants/         # 앱 상수 및 설정
├── models/            # 데이터 모델
├── providers/         # Riverpod 프로바이더
├── screens/           # UI 화면
│   ├── admin/         # 관리자 화면
│   ├── auth/          # 인증 관련 화면
│   └── user/          # 사용자 화면
├── services/          # 비즈니스 로직 및 API 연동
├── utils/             # 유틸리티 기능
└── widgets/           # 재사용 가능한 위젯
```

## 기여 방법

1. 이 레포지토리를 포크합니다.
2. 새 브랜치를 생성합니다: `git checkout -b feature/amazing-feature`
3. 변경 사항을 커밋합니다: `git commit -m 'feat: 새로운 기능 추가'`
4. 브랜치를 푸시합니다: `git push origin feature/amazing-feature`
5. Pull Request를 제출합니다.

## 커밋 메시지 컨벤션

```
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 변경
style: 코드 스타일 변경 (포맷팅, 세미콜론 누락 등)
refactor: 코드 리팩토링
test: 테스트 코드 추가/수정
chore: 빌드 프로세스 또는 보조 도구 변경
```

## 라이센스

이 프로젝트는 [MIT 라이센스](LICENSE)를 따릅니다.

## 연락처

프로젝트 관리자 - your-email@example.com
