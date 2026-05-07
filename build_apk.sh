#!/bin/bash
# ============================================================
# TrophyRoom APK 标准化编译脚本（v1.0）
# 本地 Mac 编译 → 上传服务器 → 输出下载链接
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER="$HOME/flutter/bin/flutter"
SRC="$SCRIPT_DIR/trophyroom-app"
BUILD_DIR="$SRC/build_tmp"
SERVER="root@8.153.97.56"
SERVER_PATH="/var/www/html/apk/TrophyRoom.apk"
DOWNLOAD_URL="http://8.153.97.56/apk/TrophyRoom.apk"

echo "🏗️  TrophyRoom APK Builder v1.0"
echo "=================================="

# 0. 检查 Flutter
if [ ! -x "$FLUTTER" ]; then
    echo "❌ Flutter not found at $FLUTTER"
    exit 1
fi

# 1. 准备构建目录
echo "📁 准备构建目录..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -r "$SRC/"* "$BUILD_DIR/"
cd "$BUILD_DIR"

# 2. 重建 Android 项目
echo "🔧 重建 Android 项目..."
rm -rf android lib test
"$FLUTTER" create --org com.trophyroom --project-name trophyroom . 2>&1 | tail -1
rm -f lib/main.dart
cp -r "$SRC/lib/"* lib/
mkdir -p assets
cp -r "$SRC/assets/"* assets/ 2>/dev/null || true

# ⚠️ 关键：恢复 pubspec.yaml（flutter create 会覆盖）
cp "$SRC/pubspec.yaml" pubspec.yaml

# 3. 注入 AndroidManifest 权限
echo "📋 注入权限..."
awk '/<application/ {
    print "    <uses-permission android:name=\"android.permission.INTERNET\"/>"
    print "    <uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\"/>"
    print "    <uses-permission android:name=\"android.permission.ACCESS_WIFI_STATE\"/>"
    print ""; print $0; next
} {print}' android/app/src/main/AndroidManifest.xml > android/app/src/main/AndroidManifest_tmp.xml
mv android/app/src/main/AndroidManifest_tmp.xml android/app/src/main/AndroidManifest.xml

# PSN OAuth 深链 intent-filter（macOS sed 不支持 \n，用 perl）
perl -i -pe 'if(/^        <\/activity>/ && !$done){$_="        <intent-filter>\n            <action android:name=\"android.intent.action.VIEW\" />\n            <category android:name=\"android.intent.category.DEFAULT\" />\n            <category android:name=\"android.intent.category.BROWSABLE\" />\n            <data android:scheme=\"com.scee.psxandroid\" />\n        </intent-filter>\n$_"; $done=1}' android/app/src/main/AndroidManifest.xml

# 4. NDK 版本（27 损坏了，用 26）
sed -i '' 's/ndkVersion = flutter.ndkVersion/ndkVersion = "26.3.11579264"/' android/app/build.gradle.kts

# 5. 阿里云镜像（国内加速）
cat > android/settings.gradle.kts << 'KTS'
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}
include(":app")
KTS

cat > android/build.gradle.kts << 'KTS'
allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
KTS

# 6. 编译
echo "🔨 编译 APK..."
"$FLUTTER" pub get 2>&1 | tail -3
"$FLUTTER" build apk --release --target-platform android-arm,android-arm64 2>&1 | tail -5

# 7. 保存到项目
cp build/app/outputs/flutter-apk/app-release.apk "$SCRIPT_DIR/TrophyRoom.apk"
ls -lh "$SCRIPT_DIR/TrophyRoom.apk"

# 8. 上传到服务器
echo "📤 上传到服务器..."
scp "$SCRIPT_DIR/TrophyRoom.apk" "$SERVER:$SERVER_PATH"

# 9. 验证
ssh "$SERVER" "ls -lh $SERVER_PATH" 2>/dev/null

echo ""
echo "✅ 编译发布完成！"
echo "📦 下载地址: $DOWNLOAD_URL"
