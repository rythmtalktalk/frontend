# RythmTalk 보안 설정 가이드

이 프로젝트는 민감한 API 키와 설정 파일들이 Git에서 제외되어 있습니다.
개발을 위해서는 다음 파일들을 직접 설정해야 합니다.

## 필요한 파일들

### 1. Firebase 설정 파일들

#### Android
```
android/app/google-services.json
```
Firebase Console에서 Android 앱용 google-services.json 파일을 다운로드하여 위치에 복사하세요.

#### iOS
```
ios/Runner/GoogleService-Info.plist
```
Firebase Console에서 iOS 앱용 GoogleService-Info.plist 파일을 다운로드하여 위치에 복사하세요.

#### macOS
```
macos/Runner/GoogleService-Info.plist
```
Firebase Console에서 macOS 앱용 GoogleService-Info.plist 파일을 다운로드하여 위치에 복사하세요.

### 2. Firebase Options 파일
```
lib/firebase_options.dart
```
`lib/firebase_options.dart.template` 파일을 복사하여 `lib/firebase_options.dart`로 이름을 변경하고, 실제 Firebase 프로젝트 정보로 값들을 교체하세요.

또는 FlutterFire CLI를 사용하여 자동 생성할 수 있습니다:
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

### 3. 환경 변수 설정

#### Google Speech-to-Text API 키
앱 실행 시 다음과 같이 환경 변수를 설정하세요:

```bash
flutter run --dart-define=GOOGLE_API_KEY=your_actual_api_key_here
```

또는 IDE에서 실행 설정에 다음을 추가:
```
--dart-define=GOOGLE_API_KEY=your_actual_api_key_here
```

## 보안 주의사항

1. **절대로 실제 API 키나 설정 파일을 Git에 커밋하지 마세요**
2. 환경 변수나 별도의 설정 파일을 사용하세요
3. 프로덕션 환경에서는 더 안전한 키 관리 시스템을 사용하세요

## 개발 환경 설정 체크리스트

- [ ] Firebase 프로젝트 생성
- [ ] google-services.json 파일 추가 (Android)
- [ ] GoogleService-Info.plist 파일 추가 (iOS/macOS)
- [ ] firebase_options.dart 파일 설정
- [ ] Google Cloud Console에서 Speech-to-Text API 활성화
- [ ] API 키 생성 및 환경 변수 설정
- [ ] 앱 실행 테스트

## 문제 해결

### Firebase 초기화 오류
- Firebase 설정 파일들이 올바른 위치에 있는지 확인
- firebase_options.dart의 값들이 정확한지 확인

### STT 서비스 오류
- GOOGLE_API_KEY 환경 변수가 설정되었는지 확인
- Google Cloud Console에서 Speech-to-Text API가 활성화되었는지 확인
- API 키에 필요한 권한이 있는지 확인 