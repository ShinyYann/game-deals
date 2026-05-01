#!/bin/bash
set -ex

cd /tmp
flutter create --org com.yann --project-name trophyroom trophyroom
# Copy custom Android config (manifest, plugins, etc.)
rm -rf trophyroom/android/app/src/main
cp -r "$1/trophyroom-app/android/app/src/main" trophyroom/android/app/src/main/
rm -rf trophyroom/lib/*
cp -r "$1/trophyroom-app/lib/"* trophyroom/lib/
cp "$1/trophyroom-app/pubspec.yaml" trophyroom/pubspec.yaml
cd /tmp/trophyroom
flutter pub get

cd /tmp/trophyroom/android

# Generate keystore
keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"

# Patch applicationId
sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' app/build.gradle.kts 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' app/build.gradle 2>/dev/null || true

# Create init script for signing
mkdir -p /tmp/trophyroom/android/init.d
cat > /tmp/trophyroom/android/init.d/signing.gradle << 'GRADLEINIT'
rootProject.subprojects { project ->
    if (project.plugins.hasPlugin("com.android.application")) {
        project.android {
            signingConfigs {
                release {
                    storePassword = "trophyroom"
                    keyAlias = "release"
                    keyPassword = "trophyroom"
                    storeFile = file("/tmp/release.keystore")
                }
            }
            buildTypes {
                release {
                    signingConfig = signingConfigs.release
                }
                debug {
                    signingConfig = signingConfigs.release
                }
            }
        }
    }
}
GRADLEINIT

# Add init script config to gradle.properties
echo "org.gradle.jvmargs=-Xmx4g" >> gradle.properties
echo "android.useAndroidX=true" >> gradle.properties

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/release/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || true
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
