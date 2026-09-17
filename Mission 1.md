
// Mission 1. 개발 환경 인증

im-yejin@im-yejins-MacBook-Air movielog % flutter doctor -v
[✓] Flutter (Channel stable, 3.47.3, on macOS 26.6.2 25G83 darwin-arm64, // 플루터 버전, 운영체제
    locale ko-KR) [411ms]
    • Flutter version 3.47.3 on channel stable at
      /opt/homebrew/share/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision e8113bf456 (12 days ago), 2026-09-04 13:20:08
      -0700
    • Engine revision 06a2e2a110
    • Dart version 3.13.3
    • DevTools version 2.60.0
    • Feature flags: enable-web, enable-linux-desktop,
      enable-macos-desktop, enable-windows-desktop, enable-android,
      enable-ios, cli-animations, enable-native-assets, enable-record-use,
      enable-swift-package-manager, omit-legacy-version-file,
      enable-lldb-debugging, enable-uiscene-migration

[✓] Android toolchain - develop for Android devices (Android SDK version
    37.0.0) [689ms]
    • Android SDK at /Users/im-yejin/Library/Android/sdk
    • Emulator version 37.1.11.0 (build_id 15917651) (CL:N/A)
    • Platform android-37.0, build-tools 37.0.0
    • Java binary at: /Applications/Android
      Studio.app/Contents/jbr/Contents/Home/bin/java
      This is the JDK bundled with the latest Android Studio installation
      on this machine.
      To manually set the JDK path, use: `flutter config
      --jdk-dir="path/to/jdk"`.
    • Java version OpenJDK Runtime Environment (build
      25.0.3+-15898627-b508.16)
    • All Android licenses accepted.

[✓] Xcode - develop for iOS and macOS (Xcode 26.6) [968ms]
    • Xcode at /Applications/Xcode.app/Contents/Developer
    • Build 17F113
    • CocoaPods version 1.17.0

[✓] Chrome - develop for the web [4ms]
    • Chrome at /Applications/Google Chrome.app/Contents/MacOS/Google
      Chrome

[✓] Connected device (3 available) [6.2s] // 실행기기
    • sdk gphone16k arm64 (mobile) • emulator-5554 • android-arm64  • // Pixel 에뮬레이터
      Android 17 (API 37) (emulator)
    • macOS (desktop)              • macos         • darwin-arm64   • macOS
      26.6.2 25G83 darwin-arm64
    • Chrome (web)                 • chrome        • web-javascript •
      Google Chrome 153.0.8010.48

[✓] Network resources [337ms]
    • All expected network resources are available.

• No issues found!

// Dart --version

Dart SDK version: 3.13.3 (stable) (Tue Sep 1 01:07:17 2026 -0700) on "macos_arm64"

// IDE 

1.137.0
645f29cc3176500b4b5762ba887cf2a7f0ffdf2c
arm64

// 설치 중 발생한 오류 한 가지를 해결 과정과 함께 기록

1. Homebrew — command not found: brew

원인: Homebrew 설치는 됐지만, 터미널이 brew의 위치(PATH)를 몰라서 인식하지 못함
해결: eval "$(/opt/homebrew/bin/brew shellenv zsh)" 실행해 PATH에 등록

2. Flutter — CocoaPods not installed

원인: iOS 플러그인 의존성 관리 도구인 CocoaPods가 설치되어 있지 않아 flutter doctor에서 경고 발생
해결: brew install cocoapods로 Homebrew를 통해 설치