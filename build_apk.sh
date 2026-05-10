#!/bin/bash
# ============================================================
# TrophyRoom APK 编译与发布（标准化流程）
# 本地 Mac 编译 → 上传服务器 → 直链下载
# 最后更新: 2026-05-10 00:34
# ⚠️ 每次编译前：VERSION_CODE += 1 ← 忘记这个 App 不推更新！
# ============================================================
set -e

FLUTTER="${FLUTTER_BIN:-flutter}"
REPO="/Users/shinyyann/.openclaw/workspace/game-deals"
SRC="$REPO/trophyroom-app"
SERVER="root@8.153.97.56"
DEPLOY_PATH="/var/www/html/apk/TrophyRoom.apk"
BUILD_DIR="/tmp/trophyroom-build"
VERSION_CODE=107  # ⚠️ 每次编译前 +1！App 靠 versionCode 比较来弹更新提示

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

# Step 2b: Set version code (flutter create defaults to 1)
echo "🔧 Step 2b: Setting versionCode=$VERSION_CODE..."
if [ -f android/app/build.gradle.kts ]; then
    perl -i -pe "s{versionCode = flutter.versionCode}{versionCode = $VERSION_CODE}" android/app/build.gradle.kts
else
    perl -i -pe "s{versionCode flutterVersionCode.toInteger\(\)}{versionCode $VERSION_CODE}" android/app/build.gradle
fi

# Step 3: Copy source code
echo "📋 Step 3: Copying source code..."
rm -f lib/main.dart
cp -r "$SRC"/lib/* lib/
mkdir -p assets
cp -r "$SRC"/assets/* assets/ 2>/dev/null || true

# Step 4: Restore pubspec.yaml (flutter create overwrites it!)
echo "📦 Step 4: Restoring pubspec.yaml..."
cp "$SRC"/pubspec.yaml pubspec.yaml

# Step 5: Get dependencies and fix NDK version
echo "📦 Step 5: Getting dependencies..."
# Pub mirror for China
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
$FLUTTER pub get 2>&1 | tail -3

echo "🔧 Step 6: Fixing NDK version..."
# Create dummy NDK 27 source.properties (plugins check this file exists)
ndk27="/tmp/flutter/ndk/27.0.12077973"
mkdir -p "$ndk27"
cat > "$ndk27/source.properties" << 'NDKEOF'
Pkg.Desc = Android NDK
Pkg.Revision = 27.0.12077973
NDKEOF
export ANDROID_NDK_HOME="$ndk27"
perl -i -pe "s/ndkVersion = flutter\\.ndkVersion/ndkVersion = \"27.0.12077973\"/" android/app/build.gradle.kts

# Step 7: Aliyun Maven mirrors (Google Maven blocked in China)
echo "🔧 Step 7: Adding Aliyun Maven mirrors..."
for f in android/settings.gradle.kts android/build.gradle.kts; do
  perl -i -pe 's{google\(\)}{maven { url = uri("https://maven.aliyun.com/repository/google") }\n        maven { url = uri("https://maven.aliyun.com/repository/public") }\n        google()}' "$f"
done

# Step 7: Copy widget layout & Kotlin + network config
echo "🔧 Step 7: Copying widget & network config..."
mkdir -p android/app/src/main/res/{layout,xml,drawable}
mkdir -p android/app/src/main/kotlin/com/trophyroom/trophyroom
cp "$SRC"/android/app/src/main/res/layout/trophy_widget.xml android/app/src/main/res/layout/
cp "$SRC"/android/app/src/main/res/xml/trophy_widget_info.xml android/app/src/main/res/xml/
cp "$SRC"/android/app/src/main/res/xml/network_security_config.xml android/app/src/main/res/xml/
cp "$SRC"/android/app/src/main/res/drawable/widget_bg.xml android/app/src/main/res/drawable/
cp "$SRC"/android/app/src/main/kotlin/com/trophyroom/trophyroom/MainActivity.kt android/app/src/main/kotlin/com/trophyroom/trophyroom/
cp "$SRC"/android/app/src/main/kotlin/com/trophyroom/trophyroom/TrophyWidgetProvider.kt android/app/src/main/kotlin/com/trophyroom/trophyroom/
cp "$SRC"/android/app/src/main/kotlin/com/trophyroom/trophyroom/InstallReceiver.kt android/app/src/main/kotlin/com/trophyroom/trophyroom/

echo "🔧 Step 8: Injecting network permissions and FileProvider..."
perl -i -pe 's{<manifest xmlns:android="http://schemas.android.com/apk/res/android">}{<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>}' android/app/src/main/AndroidManifest.xml
perl -i -pe 's{android:label="trophyroom"}{android:label="trophyroom"\n        android:networkSecurityConfig="\@xml/network_security_config"\n        android:usesCleartextTraffic="true"}' android/app/src/main/AndroidManifest.xml
# Hot update FileProvider
mkdir -p android/app/src/main/res/xml
cp "$SRC"/android/app/src/main/res/xml/file_paths.xml android/app/src/main/res/xml/
perl -i -pe 's{</activity>}{</activity>\n        <provider\n            android:name="androidx.core.content.FileProvider"\n            android:authorities="${applicationId}.fileprovider"\n            android:exported="false"\n            android:grantUriPermissions="true">\n            <meta-data\n                android:name="android.support.FILE_PROVIDER_PATHS"\n                android:resource="\@xml/file_paths" />\n        </provider>}' android/app/src/main/AndroidManifest.xml

# Step 9: PSN OAuth deep link
echo "🔧 Step 9: Injecting PSN OAuth deep link..."
perl -i -pe 's{</activity>}{        <intent-filter>\n                <action android:name="android.intent.action.VIEW" />\n                <category android:name="android.intent.category.DEFAULT" />\n                <category android:name="android.intent.category.BROWSABLE" />\n                <data android:scheme="com.scee.psxandroid" />\n            </intent-filter>\n        </activity>}' android/app/src/main/AndroidManifest.xml

# Step 9b: Browser queries (Android 11+ 需要声明才能打开浏览器)
echo "🔧 Step 9b: Injecting browser queries..."
perl -i -pe 's{</queries>}{        <intent>\n            <action android:name="android.intent.action.VIEW"/>\n            <data android:scheme="http"/>\n        </intent>\n        <intent>\n            <action android:name="android.intent.action.VIEW"/>\n            <data android:scheme="https"/>\n        </intent>\n    </queries>}' android/app/src/main/AndroidManifest.xml

# Step 10: Custom app icon + app name "奖杯屋"
echo "🎨 Step 10: Applying custom icon and app name..."
for mdir in "$SRC"/android/app/src/main/res/mipmap-*/; do
  mname=$(basename "$mdir")
  cp -f "$mdir"ic_launcher.png "android/app/src/main/res/$mname/ic_launcher.png" 2>/dev/null || true
  cp -f "$mdir"ic_launcher_round.png "android/app/src/main/res/$mname/ic_launcher_round.png" 2>/dev/null || true
done
perl -i -pe 's{android:label="trophyroom"}{android:label="奖杯屋"}' android/app/src/main/AndroidManifest.xml

# Step 11: Inject widget provider
echo "📱 Step 11: Injecting desktop widget..."
perl -i -pe 's{</activity>}{</activity>\n\n        <!-- Widget (native) -->\n        <receiver\n            android:name=".TrophyWidgetProvider"\n            android:exported="true"\n            android:label="奖杯屋">\n            <intent-filter>\n                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />\n            </intent-filter>\n            <meta-data\n                android:name="android.appwidget.provider"\n                android:resource="\@xml/trophy_widget_info" />\n        </receiver>}' android/app/src/main/AndroidManifest.xml

# Step 12: Build APK
echo "🔨 Step 12: Building APK..."
# Remove old APK first to avoid false positives
rm -f build/app/outputs/flutter-apk/app-release.apk
$FLUTTER build apk --release --target-platform android-arm,android-arm64 2>&1
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo "❌ Step 12: BUILD FAILED (exit code $BUILD_RESULT)"
    exit 1
fi

# Step 13: Deploy to server (fallback)
APK="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  SIZE=$(ls -lh "$APK" | awk '{print $5}')
  echo "✅ APK built: $SIZE"
  echo "📤 Step 13: Deploying to server..."
  scp "$APK" "$SERVER:$DEPLOY_PATH"
  # 写入本次更新日志
CHANGELOG_FILE="/tmp/trophyroom_changelog.txt"
echo "" > "$CHANGELOG_FILE"
if [ -f "$SRC/../changelog.txt" ]; then
  # 取最新一段（版本号行到下一个版本号行之间）
  awk "/^v$VERSION_CODE /{flag=1; next} /^v/{flag=0} flag" "$SRC/../changelog.txt" >> "$CHANGELOG_FILE"
fi
CHANGELOG=$(cat "$CHANGELOG_FILE" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")
echo "   📝 Changelog: $CHANGELOG"

# 同步更新 version.json 让 App 检测到新版本
  ssh "$SERVER" "cat > /var/www/html/apk/version.json << 'CHANGELOG_EOF'
{
  \"versionCode\": $VERSION_CODE,
  \"versionName\": \"1.0.$VERSION_CODE\",
  \"apkUrl\": \"http://8.153.97.56/apk/TrophyRoom.apk\",
  \"changelog\": $CHANGELOG
}
CHANGELOG_EOF"
  echo "   -> http://8.153.97.56/apk/TrophyRoom.apk"
else
  echo "❌ Build failed - APK not found"
  exit 1
fi

# Step 14: Upload to GitHub Releases (fast CDN for auto-update)
if [ -f "$APK" ] && [ -n "$GH_TOKEN" ]; then
  echo "📤 Step 14: Uploading to GitHub Releases..."
  # Ensure 'latest' tag exists
  TAG="latest"
  # Upload asset to the release
  curl -s -H "Authorization: Bearer $GH_TOKEN" \
    -H "Content-Type: application/vnd.android.package-archive" \
    -T "$APK" \
    "https://uploads.github.com/repos/ShinyYann/trophyroom/releases/tags/$TAG/assets?name=TrophyRoom.apk" \
    -o /dev/null -w "   -> GitHub: %{http_code}\n"
  echo "   -> https://github.com/ShinyYann/trophyroom/releases/download/$TAG/TrophyRoom.apk"
elif [ ! -n "$GH_TOKEN" ]; then
  echo "⏭️  Step 14: Skipped (GH_TOKEN not set, server deploy only)"
fi
