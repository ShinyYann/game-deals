#!/bin/bash
set -ex

cd /tmp
flutter create --org com.yann --project-name trophyroom trophyroom
rm -rf trophyroom/lib/*
cp -r "$1/trophyroom-app/lib/"* trophyroom/lib/
cp "$1/trophyroom-app/pubspec.yaml" trophyroom/pubspec.yaml
cd /tmp/trophyroom
flutter pub get

cd /tmp/trophyroom/android

# Generate keystore
keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"

# Use Groovy DSL for signing instead of patching the Kotlin build.gradle.kts
# Write a signing.gradle file that gets applied via android block
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
        if (type.name == "release" || type.name == "debug") {
            type.signingConfig = signingConfigs.release
        }
    }
}
SIGNEOF

# Apply signing config by appending to the app build.gradle
echo '' >> app/build.gradle
echo '// Apply signing config' >> app/build.gradle
echo "apply from: '/tmp/signing.gradle'" >> app/build.gradle

# Patch applicationId in both Gradle files
sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' app/build.gradle.kts 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' app/build.gradle 2>/dev/null || true

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/release/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || true
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
