#!/bin/bash
set -ex

cd /tmp
flutter create --org com.yann --project-name trophyroom trophyroom

# Copy custom Android Kotlin files, preserving Flutter's MainActivity.kt
cp -r "$1/trophyroom-app/android/app/src/main/kotlin/"* trophyroom/android/app/src/main/kotlin/com/yann/trophyroom/

# Copy custom AndroidManifest.xml
cp "$1/trophyroom-app/android/app/src/main/AndroidManifest.xml" trophyroom/android/app/src/main/AndroidManifest.xml

# Copy custom res/ (icons, network_security_config)
cp -r "$1/trophyroom-app/android/app/src/main/res/"* trophyroom/android/app/src/main/res/

# Copy lib files
rm -rf trophyroom/lib/*
cp -r "$1/trophyroom-app/lib/"* trophyroom/lib/

# Copy pubspec
cp "$1/trophyroom-app/pubspec.yaml" trophyroom/pubspec.yaml
cd /tmp/trophyroom
flutter pub get

cd /tmp/trophyroom/android

# --- Build InstallHelper APK ---
cd /tmp
export ANDROID_HOME=/usr/local/lib/android/sdk
mkdir -p install-helper/app/src/main/java/com/yann/installhelper
GRADLE_VER=8.12
if [ ! -f /tmp/gradle-${GRADLE_VER}/bin/gradle ]; then
  curl -sL "https://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip" -o /tmp/gradle.zip
  unzip -q /tmp/gradle.zip -d /tmp
fi

# Copy InstallHelper project files
cp -r "$1/install-helper/"* /tmp/install-helper/

# Build InstallHelper
cd /tmp/install-helper
/tmp/gradle-${GRADLE_VER}/bin/gradle assembleRelease --no-daemon -p . 2>&1 || echo "InstallHelper build failed (non-critical)"

# Copy helper APK next to main APK
mkdir -p /tmp/helper-output
cp /tmp/install-helper/app/build/outputs/apk/release/*.apk /tmp/helper-output/ 2>/dev/null || true

# --- Back to main build ---
# Patch applicationId
sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' app/build.gradle.kts 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' app/build.gradle 2>/dev/null || true

# Release build
echo "org.gradle.jvmargs=-Xmx4g" >> gradle.properties
echo "android.useAndroidX=true" >> gradle.properties

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64 2>&1 || {
  echo "=== BUILD FAILED ==="
  flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64 2>&1 || true
  echo "=== Listing build output ==="
  find build -name "*.apk" 2>/dev/null || echo "No APKs found"
  echo "=== Gradle error log (if exists) ==="
  cat /tmp/trophyroom/build/app/outputs/flutter-apk/*.log 2>/dev/null || true
  exit 1
}
# Debug APK paths
cp build/app/outputs/flutter-apk/app-debug.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/debug/app-debug.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/release/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/flutter-apk/app.apk /tmp/TrophyRoom.apk 2>/dev/null || true
file /tmp/TrophyRoom.apk 2>/dev/null || echo "No APK found"
ls -lh /tmp/TrophyRoom.apk 2>/dev/null || true
