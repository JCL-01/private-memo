# 프라이빗 메모

옆 사람이 보면 안 되는 내용을 적는 메모 앱. Flutter로 만들며 Android와 Windows를 먼저 지원한다.

제품 요구사항(PRD): [docs/PRD.md](docs/PRD.md)

## 기술 스택
- Flutter (Dart), Material
- 상태 관리: Riverpod
- 로컬 저장: Drift (SQLite)

## 개발 환경 준비 (Windows)
1. [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 설치 (버전 3.50.0)
2. Windows 앱 빌드: Visual Studio 2022의 "C++를 사용한 데스크톱 개발" 워크로드
3. Android 빌드: Android Studio (Android SDK, 에뮬레이터)
4. VS Code에 Flutter 확장 설치

## 실행
```bash
flutter pub get
```
```bash
flutter run -d windows
```
```bash
flutter run -d android
```

## 테스트
```bash
flutter analyze
```
```bash
flutter test
```

## DB 스키마를 바꿨을 때
`lib/data/database.dart`를 고친 뒤 생성 코드를 다시 만든다.
```bash
dart run build_runner build
```

## 빌드 결과물
GitHub에 푸시하면 Actions가 테스트 후 Android APK와 Windows 실행 파일을 만든다.
Actions 실행 화면의 Artifacts에서 내려받을 수 있다.

## 폴더 구조
```
lib/
  main.dart                 앱 시작
  app/app.dart              테마(라이트/다크), 첫 화면
  data/                     DB, 저장소, Riverpod provider
  features/notes/           메모 목록·편집 화면
test/                       단위·위젯 테스트
docs/PRD.md                 제품 요구사항(PRD)
```
