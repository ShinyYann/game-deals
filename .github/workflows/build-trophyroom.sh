#!/bin/bash
set -ex

WORK_DIR="/tmp/trophyroom"

# Clean any previous build artefacts
rm -rf "$WORK_DIR"

# Create Flutter project with ONLY Android platform
flutter create --org com.yann --project-name trophyroom --platforms android "$WORK_DIR"

# Copy our custom Dart code
rm -rf "$WORK_DIR/lib/"*
cp -r "$1/trophyroom-app/lib/"* "$WORK_DIR/lib/"
cp "$1/trophyroom-app/pubspec.yaml" "$WORK_DIR/pubspec.yaml"

cd "$WORK_DIR"
flutter pub get

# ====== FORCE INTERNET PERMISSIONS ======
# Flutter's default template may not include INTERNET in release builds
# Patch the AndroidManifest.xml to add permissions
ANDROID_MANIFEST="$WORK_DIR/android/app/src/main/AndroidManifest.xml"
if [ -f "$ANDROID_MANIFEST" ]; then
  echo "Patching AndroidManifest.xml for network permissions..."
  
  # Add internet permissions before the <application> tag
  # The template starts with <manifest>, we need permissions between manifest and application
  # First check if INTERNET is already there
  if grep -q "INTERNET" "$ANDROID_MANIFEST"; then
    echo "  INTERNET permission already present"
  else
    # Add permissions before <application
    awk '
    /<application/ {
      print "    <uses-permission android:name=\"android.permission.INTERNET\"/>"
      print "    <uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\"/>"
      print "    <uses-permission android:name=\"android.permission.ACCESS_WIFI_STATE\"/>"
    }
    { print }
    ' "$ANDROID_MANIFEST" > "${ANDROID_MANIFEST}.new"
    mv "${ANDROID_MANIFEST}.new" "$ANDROID_MANIFEST"
    echo "  Permissions added successfully"
    grep "permission" "$ANDROID_MANIFEST"
  fi
else
  echo "WARNING: AndroidManifest.xml not found at $ANDROID_MANIFEST"
  # Try alternate location
  find "$WORK_DIR" -name "AndroidManifest.xml" -path "*/app/*" 2>/dev/null
fi

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
ANDROID_DIR="$WORK_DIR/android"
if [ -f "$ANDROID_DIR/app/build.gradle.kts" ]; then
  echo "Using Kotlin DSL project"
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
