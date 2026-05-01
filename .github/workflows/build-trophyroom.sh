#!/bin/bash
set -e

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

# Patch applicationId
cd /tmp/trophyroom/android
sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' app/build.gradle.kts 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' app/build.gradle 2>/dev/null || true

# Increase JVM heap for Gradle
echo "org.gradle.jvmargs=-Xmx4g" >> gradle.properties
echo "android.useAndroidX=true" >> gradle.properties

# Generate consistent debug keystore for fixed signing (so Android keeps network permissions)
keytool -genkey -v -keystore /tmp/trophyroom/android/app/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null || true

# Create key.properties pointing to the keystore
cat > /tmp/trophyroom/android/key.properties << EOF
storePassword=android
keyPassword=android
keyAlias=androiddebugkey
storeFile=app/debug.keystore
EOF

# Build APK
cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64

# Copy APK to output
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || cp /tmp/trophyroom/build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
file /tmp/TrophyRoom.apk
