#!/bin/bash
# ============================================================
# TrophyRoom APK 编译与发布（标准化流程）
# 本地 Mac 编译 → 上传服务器 → 直链下载
# 最后更新: 2026-05-07 22:03
# ============================================================
set -e

FLUTTER="${FLUTTER_BIN:-flutter}"
REPO="/Users/shinyyann/.openclaw/workspace/game-deals"
SRC="$REPO/trophyroom-app"
SERVER="root@8.153.97.56"
DEPLOY_PATH="/var/www/html/apk/TrophyRoom.apk"
BUILD_DIR="/tmp/trophyroom-build"

echo "🏗️  TrophyRoom APK Builder"
echo "=========================="

# Step 1: Clean build dir
echo "📁 Step 1: Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -r "$SRC"/* "$BUILD_DIR/"
cd "$BUILD_DIR"

# Remove old android/lib/test (will be regenerated)
rm -rf android lib test

# Step 2: Generate fresh Flutter project
echo "🔧 Step 2: Generating Flutter project..."
$FLUTTER create --org com.trophyroom --project-name trophyroom . 2>&1 | tail -2

# Step 3: Copy source code
echo "📋 Step 3: Copying source code..."
rm -f lib/main.dart
cp -r "$SRC"/lib/* lib/
mkdir -p assets
cp -r "$SRC"/assets/* assets/ 2>/dev/null || true

# Step 4: Restore pubspec.yaml (flutter create overwrites it!)
echo "📦 Step 4: Restoring pubspec.yaml..."
cp "$SRC"/pubspec.yaml pubspec.yaml

# Step 5: Fix NDK version (27 source.properties missing, use 26)
echo "🔧 Step 5: Fixing NDK version..."
perl -i -pe "s/ndkVersion = flutter\\.ndkVersion/ndkVersion = \"26.3.11579264\"/" android/app/build.gradle.kts

# Step 6: Aliyun Maven mirrors (Google Maven blocked in China)
echo "🔧 Step 6: Adding Aliyun Maven mirrors..."
for f in android/settings.gradle.kts android/build.gradle.kts; do
  perl -i -pe 's{google\(\)}{maven { url = uri("https://maven.aliyun.com/repository/google") }\n        maven { url = uri("https://maven.aliyun.com/repository/public") }\n        google()}' "$f"
done

# Step 7: Inject INTERNET permission + cleartext HTTP
echo "🔧 Step 7: Injecting network permissions..."
perl -i -pe 's{<manifest xmlns:android="http://schemas.android.com/apk/res/android">}{<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>}' android/app/src/main/AndroidManifest.xml
perl -i -pe 's{android:label="trophyroom"}{android:label="trophyroom"\n        android:networkSecurityConfig="\@xml/network_security_config"\n        android:usesCleartextTraffic="true"}' android/app/src/main/AndroidManifest.xml
mkdir -p android/app/src/main/res/xml
cp "$SRC"/android/app/src/main/res/xml/network_security_config.xml android/app/src/main/res/xml/

# Step 8: PSN OAuth deep link
echo "🔧 Step 8: Injecting PSN OAuth deep link..."
perl -i -pe 's{</activity>}{        <intent-filter>\n                <action android:name="android.intent.action.VIEW" />\n                <category android:name="android.intent.category.DEFAULT" />\n                <category android:name="android.intent.category.BROWSABLE" />\n                <data android:scheme="com.scee.psxandroid" />\n            </intent-filter>\n        </activity>}' android/app/src/main/AndroidManifest.xml

# Step 9: Build APK
echo "🔨 Step 9: Building APK..."
$FLUTTER build apk --release --target-platform android-arm,android-arm64 2>&1 | tail -10

# Step 10: Deploy to server
APK="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  SIZE=$(ls -lh "$APK" | awk '{print $5}')
  echo "✅ APK built: $SIZE"
  echo "📤 Step 10: Deploying to server..."
  scp "$APK" "$SERVER:$DEPLOY_PATH"
  echo "🎉 Done! Download: http://8.153.97.56/apk/TrophyRoom.apk"
else
  echo "❌ Build failed - APK not found"
  exit 1
fi
