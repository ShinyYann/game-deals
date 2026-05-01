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
if [ -f app/build.gradle.kts ]; then
  APP_GRADLE=app/build.gradle.kts
  sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' "$APP_GRADLE"
else
  APP_GRADLE=app/build.gradle
  sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' "$APP_GRADLE"
fi

# Append signing config
echo "" >> "$APP_GRADLE"
echo "android {" >> "$APP_GRADLE"
echo "    signingConfigs {" >> "$APP_GRADLE"
echo "        release {" >> "$APP_GRADLE"
echo "            keyAlias = \"release\"" >> "$APP_GRADLE"
echo "            keyPassword = \"trophyroom\"" >> "$APP_GRADLE"
echo "            storeFile = file(\"/tmp/release.keystore\")" >> "$APP_GRADLE"
echo "            storePassword = \"trophyroom\"" >> "$APP_GRADLE"
echo "        }" >> "$APP_GRADLE"
echo "    }" >> "$APP_GRADLE"
echo "    buildTypes {" >> "$APP_GRADLE"
echo "        release {" >> "$APP_GRADLE"
echo "            signingConfig = signingConfigs.release" >> "$APP_GRADLE"
echo "        }" >> "$APP_GRADLE"
echo "    }" >> "$APP_GRADLE"
echo "}" >> "$APP_GRADLE"

keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
