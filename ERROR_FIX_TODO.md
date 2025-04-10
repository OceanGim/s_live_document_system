# 오류 수정 TODO 리스트

이 문서는 S-Live 스튜디오 통합 문서 및 장비 관리 시스템에서 발견된 오류와 수정 계획을 정리합니다.

## 문서 워크플로우 관련 오류

### lib/providers/document_workflow_provider.dart
- [x] `userInfoProvider`로 사용자 정보 접근하도록 수정

### 문서 양식 화면 오류
다음 파일에서 동일한 패턴의 오류가 발생하고 있습니다:

#### lib/screens/document/facility_agreement_form.dart
- [ ] 함수로 평가되지 않는 표현식 호출 오류 (Line 60, 487, 630)
- [ ] DocumentWorkflowStatus 관련 오류 (loading, reviewing 상태 구현 필요)

#### lib/screens/document/portrait_rights_form.dart
- [ ] 함수로 평가되지 않는 표현식 호출 오류 (Line 58, 397, 492)
- [ ] DocumentWorkflowStatus 관련 오류 (loading, reviewing 상태 구현 필요)

#### lib/screens/document/privacy_agreement_form.dart
- [ ] 함수로 평가되지 않는 표현식 호출 오류 (Line 46, 336, 381)
- [ ] DocumentWorkflowStatus 관련 오류 (loading, reviewing 상태 구현 필요)

#### lib/screens/document/satisfaction_survey_form.dart
- [ ] 함수로 평가되지 않는 표현식 호출 오류 (Line 100, 694)
- [ ] DocumentWorkflowStatus.reviewing 사용 관련 오류

### lib/screens/document/document_workflow_screen.dart
- [ ] DocumentWorkflowProviderParams 메서드 관련 오류 (Line 199, 252, 386, 404, 428)

## 공통 수정 방법

### 문서 화면 오류 해결 방법

1. **함수로 평가되지 않는 표현식 호출 오류**:
   - DocumentWorkflowProviderParams를 사용하는 방식을 검토하고 수정
   - 객체 생성 후 메서드 호출이 아닌 적절한 방식으로 파라미터 전달

2. **DocumentWorkflowStatus 상태 관련 오류**:
   - DocumentWorkflowStatus enum에 추가된 loading과 reviewing 상태를 각 화면에서 올바르게 사용
   - 상태 전환 로직 일관성 있게 구현

3. **Provider 사용 방식 통일**:
   - 모든 화면에서 documentWorkflowProvider 접근 방식 일관성 있게 수정
   - ref.read와 ref.watch 사용 규칙 통일

## 구현 계획

### 1단계: 문서 워크플로우 관련 수정
- [x] DocumentWorkflowStatus enum에 필요한 상태 추가 (loading, reviewing)
- [x] DocumentWorkflowProviderParams 클래스 구현 및 사용 방법 정의
- [ ] 문서 워크플로우 화면에서 파라미터 전달 방식 수정

### 2단계: 개별 문서 화면 수정
- [ ] facility_agreement_form.dart 수정
- [ ] portrait_rights_form.dart 수정
- [ ] privacy_agreement_form.dart 수정
- [ ] satisfaction_survey_form.dart 수정
- [ ] 공통 패턴 오류 한 번에 해결

### 3단계: 테스트 및 검증
- [ ] 문서 워크플로우 전체 흐름 테스트
- [ ] 서명 자동 반영 기능 검증
- [ ] 문서 스킵 기능 검증
- [ ] 관리자 확인 기능 검증

## 참고 사항

- DocumentWorkflowProviderParams는 문서 유형과 렌탈 ID를 전달하기 위한 클래스로, 함수가 아닌 데이터 객체임
- DocumentWorkflowStatus enum은 문서 작성 상태를 표현하는 열거형으로, 워크플로우 진행 상태를 추적함
- 관련 파일들은 서로 의존성이 있으므로 일관된 방식으로 수정 필요
