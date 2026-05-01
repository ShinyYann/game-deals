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
APP_GRADLE=app/build.gradle
if [ -f app/build.gradle.kts ]; then
  APP_GRADLE=app/build.gradle.kts
fi

keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"

cat > /tmp/trophyroom/android/gradle.properties << 'PROPS'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4g
storePassword=trophyroom
keyPassword=trophyroom
keyAlias=release
storeFile=/tmp/release.keystore
PROPS

sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' "$APP_GRADLE" 2>/dev/null || true
sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' "$APP_GRADLE" 2>/dev/null || true

# Inject signing config using Python (handles both .kts and .gradle)
python3 << 'PYEOF'
import os, sys

gradle_file = os.path.join('/tmp/trophyroom/android', 'app/build.gradle.kts')
if not os.path.exists(gradle_file):
    gradle_file = os.path.join('/tmp/trophyroom/android', 'app/build.gradle')

content = open(gradle_file).read()

# Find where buildTypes block is (or end of android block)
buildtypes_pos = content.rfind('buildTypes')

if 'build.gradle.kts' in gradle_file:
    signing_block = '''
    signingConfigs {
        create("release") {
            storePassword = properties["storePassword"] as String
            keyAlias = properties["keyAlias"] as String
            keyPassword = properties["keyPassword"] as String
            storeFile = file(properties["storeFile"] as String)
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
'''
else:
    signing_block = '''
    signingConfigs {
        release {
            storePassword project.properties['storePassword']
            keyAlias project.properties['keyAlias']
            keyPassword project.properties['keyPassword']
            storeFile file(project.properties['storeFile'])
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
        debug {
            signingConfig signingConfigs.release
        }
    }
'''

if buildtypes_pos > 0:
    content = content[:buildtypes_pos] + signing_block
    open(gradle_file, 'w').write(content)
    print(f"Signing injected into {gradle_file}")
else:
    print(f"Could not find buildTypes in {gradle_file}")
    print(content[:500])
    sys.exit(1)
PYEOF

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2 --target-platform android-arm,android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || \
  cp build/app/outputs/apk/release/app-release.apk /tmp/TrophyRoom.apk 2>/dev/null || true
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
