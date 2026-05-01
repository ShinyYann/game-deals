#!/bin/bash
set -ex
cd "$1/net-test"
export ANDROID_HOME=/usr/local/lib/android/sdk

echo "sdk.dir=$ANDROID_HOME" > local.properties

# Download Gradle 8.12
GRADLE_VER=8.12
if [ ! -f /tmp/gradle-${GRADLE_VER}/bin/gradle ]; then
  curl -sL "https://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip" -o /tmp/gradle.zip
  unzip -q /tmp/gradle.zip -d /tmp
fi

# Build APK
/tmp/gradle-${GRADLE_VER}/bin/gradle assembleRelease --no-daemon -p .

# Copy APK
cp app/build/outputs/apk/release/*.apk /tmp/TrophyRoom.apk 2>/dev/null || true
ls -lh /tmp/TrophyRoom.apk 2>/dev/null || echo "No APK found"
