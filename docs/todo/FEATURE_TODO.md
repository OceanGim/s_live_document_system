# S-Live 스튜디오 통합 문서 및 장비 관리 시스템 개발 작업

## 회원가입 및 로그인
- [x] 이메일, 비밀번호, 이름, 연락처 필수 입력 구현
- [x] 서명 저장 기능 (PDF 서류 자동 반영용) 구현
- [x] 기업/인플루언서 체크박스 선택 기능 구현
- [x] 기업 정보 입력 화면 구현
  - [x] 기업명, 사업자등록번호, 대표자명, 회사연락처 입력 필드
- [x] 인플루언서 정보 입력 화면 구현
  - [x] 플랫폼(드롭다운), 플랫폼 ID, 활동명, 구독자수 입력 필드
- [x] 권한별 자동 라우팅 구현

## 서류 입력 흐름
- [x] 대관 시간 입력 (09:00 ~ 21:00 드롭다운) 구현
- [x] 스튜디오 선택 (메인/키친/소형) 구현
- [x] 개인정보 수집이용동의서 화면 구현
- [x] 초상권 및 저작권 이용 동의서 화면 구현
  - [x] 복수 작성 기능 추가
  - [x] 참가자별 서명 및 동의 체크박스 추가
  - [x] 각 참가자별 PDF 생성 기능 
- [x] 장비대여신청서 화면 구현
  - [ ] 관리자 확인 기능 추가
  - [x] 고정 장비 목록 구현 완료
- [x] 스튜디오 시설 이용자 준수사항 확인서 화면 구현
- [x] 만족도 조사서 화면 구현
- [x] 서명 자동 반영 기능 구현
- [x] 이미 입력된 서류 스킵 기능 구현

## 만족도 조사 구현
- [x] 항목별 1~5점 라디오 버튼 구현
  - [x] 시설 만족도, 직원 친절도, 장비 전문성, 예약 만족도, 청결 상태, 장비 품질
- [x] 이용 경로 선택 기능 구현
  - [x] 검색엔진, SNS, 지인추천, 기타 옵션
- [x] 스튜디오 이점 선택 기능 구현
  - [x] 판매증진, 제품홍보, 인지도상승, 비용절감
- [x] 기타 의견 입력 필드 구현
- [x] 작성자명, 연락처 자동 입력 기능 구현
- [x] 시청자수, 매출액 통계 입력 필드 구현

## 장비 대여 및 반납 관리
- [x] 장비 리스트 드롭다운 구현
  - [x] 카메라, 무선마이크, 릴선, HDMI, 조명, 스위처 등 장비 유형
- [x] 대여 수량 입력 필드 구현
- [x] 대여/반납 시간 드롭다운 구현 (09:00 ~ 21:00)
- [ ] 반납 상태 선택 기능 구현 (나중에)
  - [ ] 정상 / 파손 / 분실
- [x] 특이사항 입력 필드 구현
- [ ] 관리자 서명 입력 기능 구현

## 파일 저장 구조
- [ ] Supabase Storage 업로드 경로 구현 
  - [ ] 경로: `photo/yyyyMMdd/yyyyMMdd_시작시간_스튜디오_기업명`
  - [ ] 예시: `photo/20250410/20250410_1500_메인_S-Live스튜디오`
- [ ] 파일 저장명 규칙 적용
  - [ ] 형식: `서류명_고객명_날짜.pdf`
  - [ ] 예시: `장비대여신청서_홍길동_20250410.pdf`

## 구글 시트 연동
- [ ] 라이브커머스 시트 연동 구현
  - [ ] 방송날짜, 요일, 방송시작시간, 대여시작/종료 등 항목 매핑
- [ ] 일반대관 시트 연동 구현
  - [ ] 대관일자, 요일, 대여시작/종료, 스튜디오 등 항목 매핑
- [ ] 만족도 조사 시트 연동 구현
  - [ ] 기업명, 대관일자, 스튜디오, 이용목적 등 항목 매핑
- [ ] 자동 컬럼 매핑 구현

## 관리자 기능
- [x] 모든 서류 열람 기능 구현
- [x] 다운로드 기능 구현
- [ ] 인쇄 기능 구현
- [ ] 구글 시트 링크 버튼 구현
- [x] PDF 생성 시 사용자 정보 자동 포함 기능
- [x] PDF 내 서명 이미지 자동 삽입 기능

## UI/UX 개선
- [x] Material 3 디자인 가이드라인 적용
- [x] 반응형 레이아웃 구현
- [ ] 다크 모드 지원
- [x] 사용자 편의성 개선
  - [x] 폼 검증 및 오류 메시지
  - [x] 진행 상태 표시 (스텝 인디케이터)
  - [x] 서류 작성 가이드 및 도움말

## 성능 및 코드 품질
- [x] 앱 성능 최적화
- [x] Logger 함수 사용으로 디버깅 효율성 향상
- [x] 불필요한 dart 파일 및 함수 제거
- [ ] 코드 중복 최소화 및 재사용성 향상

## 오류 수정 작업

### 완료된 작업
- [x] PDF 생성 서비스 문법 오류 수정
- [x] UserModel의 DateTime 파싱 기능 개선
- [x] UserProvider 클래스를 새 UserModel 구조에 맞게 업데이트
- [x] DateTime 필드에 대한 null 처리 추가
- [x] admin_home_screen.dart 수정 - displayName 속성의 null 안전성 보장
- [x] user_list_screen.dart 수정 - 검색 및 필터링 로직 null 안전성 보장
- [x] user_detail_screen.dart 수정 - 사용자 정보 표시 시 null 안전성 보장
- [x] profile_screen.dart 수정 - 모든 null 안전성 문제 해결
- [x] 문서 워크플로우 관련 수정
  - [x] `userInfoProvider`로 사용자 정보 접근하도록 수정
  - [x] DocumentWorkflowStatus enum에 필요한 상태 추가 (loading, reviewing)
  - [x] DocumentWorkflowProviderParams 클래스 구현 및 사용 방법 정의
  - [x] 문서 워크플로우 화면에서 파라미터 전달 방식 수정
- [x] 문서 양식 화면 오류 수정
  - [x] facility_agreement_form.dart 수정 (표현식 호출 오류)
  - [x] portrait_rights_form.dart 수정 (표현식 호출 오류)
  - [x] privacy_agreement_form.dart 수정 (표현식 호출 오류)
  - [x] satisfaction_survey_form.dart 수정 (표현식 호출 오류)
  - [x] document_workflow_screen.dart 수정
- [x] FileUtils 클래스 이름 충돌 해결 (FileUtilsExt로 변경)

### 남은 테스트 및 검증 작업
- [ ] 문서 워크플로우 전체 흐름 테스트
- [ ] 서명 자동 반영 기능 검증
- [ ] 문서 스킵 기능 검증
- [ ] 관리자 확인 기능 검증
- [ ] 사용자 정보 변경 후 UI 업데이트 확인
- [ ] 인증 기능(로그인, 로그아웃, 회원가입) 테스트

## 코드 개선 지침

### Null 안전성 구현 방법
- Null-aware 연산자(`?.`) 사용하여 잠재적 null 객체에 대한 메소드 호출시 안전성 보장
- Null 병합 연산자(`??`)를 사용하여 대체값 제공
- 조건식을 사용하여 null 케이스 처리
- `if (value != null)` 체크를 사용하여 nullable 객체의 속성 접근 전 확인

### DocumentWorkflowProviderParams 사용 지침
- DocumentWorkflowProviderParams는 문서 유형과 렌탈 ID를 전달하기 위한 데이터 객체
- 함수처럼 호출하지 말고 객체로 사용해야 함
  ```dart
  // 올바른 사용법
  final params = DocumentWorkflowProviderParams(
    documentType: 'personal_info',
    rentalId: rentalId
  );
  
  // 잘못된 사용법 (함수로 호출)
  final params = DocumentWorkflowProviderParams()(
    documentType: 'personal_info',
    rentalId: rentalId
  );
  ```

### 코드 품질 향상 지침
- Material 3 디자인 가이드라인 준수
- print() 대신 Logger 함수 사용
  ```dart
  // 사용하지 말 것
  print('사용자 로드됨: $userId');
  
  // 권장 방법
  Logger.info('사용자 로드됨: $userId', tag: 'UserProvider');
  ```
- 불필요한 dart 파일 및 함수 제거
- 모든 UI 컴포넌트에서 null 안전성 확보
- 코드 중복 최소화 및 재사용성 향상
