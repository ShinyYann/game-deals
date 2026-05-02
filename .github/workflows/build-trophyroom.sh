#!/bin/bash
set -ex

WORK_DIR="/tmp/trophyroom"

# Clean any previous build artefacts
rm -rf "$WORK_DIR"

# Create Flutter project with ONLY Android platform
# Using --template=app and adding --platforms=android avoids web/ios/macos/linux/windows dependencies
flutter create --org com.yann --project-name trophyroom --platforms android "$WORK_DIR"

# Copy our custom Dart code
rm -rf "$WORK_DIR/lib/"*
cp -r "$1/trophyroom-app/lib/"* "$WORK_DIR/lib/"
cp "$1/trophyroom-app/pubspec.yaml" "$WORK_DIR/pubspec.yaml"

cd "$WORK_DIR"
flutter pub get

# Generate keystore
keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom \
  -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"

# Write a small Groovy signing script
cat > /tmp/signing.gradle << 'SIGNEOF'
android {
    signingConfigs {
        release {
            storePassword = "trophyroom"
            keyAlias = "release"
            keyPassword = "trophyroom"
            storeFile = file("/tmp/release.keystore")
        }
    }
    buildTypes.all { type ->
        type.signingConfig = signingConfigs.release
    }
}
SIGNEOF

# Flutter 3.31+ generates build.gradle.kts (Kotlin DSL).
# We can safely append the Groovy apply line to the bottom of app/build.gradle.
# Note: flutter create generates "android/app/build.gradle.kts" on recent Flutter.
ANDROID_DIR="$WORK_DIR/android"
if [ -f "$ANDROID_DIR/app/build.gradle.kts" ]; then
  # For Kotlin DSL projects, inject signing via Groovy init script
  # instead of mixing Groovy into a Kotlin file
  cat > /tmp/init-signing.gradle << 'INITEOF'
initscript {
    repositories { google(); mavenCentral() }
}
rootProject { project ->
    allprojects { p ->
        p.afterEvaluate {
            if (p.plugins.hasPlugin("com.android.application")) {
                p.android.signingConfigs.create("release")
                p.android.signingConfigs.release.storePassword = "trophyroom"
                p.android.signingConfigs.release.keyAlias = "release"
                p.android.signingConfigs.release.keyPassword = "trophyroom"
                p.android.signingConfigs.release.storeFile = file("/tmp/release.keystore")
                p.android.buildTypes.all { type ->
                    type.signingConfig = p.android.signingConfigs.release
                }
            }
        }
    }
}
INITEOF
  echo "Using Kotlin DSL project, init script prepared"
elif [ -f "$ANDROID_DIR/app/build.gradle" ]; then
  # Groovy DSL - append signing config
  echo '' >> "$ANDROID_DIR/app/build.gradle"
  echo '// Apply signing config' >> "$ANDROID_DIR/app/build.gradle"
  echo "apply from: '/tmp/signing.gradle'" >> "$ANDROID_DIR/app/build.gradle"
  echo "Using Groovy DSL project, signing appended"
fi

# Patch applicationId
sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' "$ANDROID_DIR/app/build.gradle.kts" 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' "$ANDROID_DIR/app/build.gradle" 2>/dev/null || true

cd "$WORK_DIR"
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/release/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/debug/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || true
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
