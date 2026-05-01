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
  echo "Using Kotlin DSL (.kts)"
  APP_GRADLE=app/build.gradle.kts
  sed -i 's/applicationId = ".*"/applicationId = "com.yann.trophyroom"/' "$APP_GRADLE"
  # For Kotlin DSL, we need a different approach - replace the whole android block
  # First, get the keystore working by generating key.properties
  keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"
  # Add signing config to local.properties
  cat >> /tmp/trophyroom/android/key.properties << 'EOF'
storePassword=trophyroom
keyPassword=trophyroom
keyAlias=release
storeFile=/tmp/release.keystore
EOF
  # Read key.properties for Gradle
  cat >> "$APP_GRADLE" << 'EOF'

val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = java.util.Properties()
if (keystorePropsFile.exists()) {
    keystoreProps.load(keystorePropsFile.inputStream())
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProps["keyAlias"] as String
            keyPassword = keystoreProps["keyPassword"] as String
            storeFile = file(keystoreProps["storeFile"] as String)
            storePassword = keystoreProps["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
EOF
else
  echo "Using Groovy DSL (.gradle)"
  # Generate keystore
  keytool -genkey -v -keystore /tmp/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass trophyroom -keypass trophyroom -dname "CN=TrophyRoom,OU=Dev,O=Yann,L=Shanghai,S=Shanghai,C=CN"
  APP_GRADLE=app/build.gradle
  sed -i 's/applicationId ".*"/applicationId "com.yann.trophyroom"/' "$APP_GRADLE"
  cat >> "$APP_GRADLE" << 'EOF'

def keystorePropsFile = rootProject.file('key.properties')
def keystoreProps = new Properties()
if (keystorePropsFile.exists()) {
    keystoreProps.load(new FileInputStream(keystorePropsFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProps['keyAlias']
            keyPassword keystoreProps['keyPassword']
            storeFile file(keystoreProps['storeFile'])
            storePassword keystoreProps['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
EOF
  # Write key.properties
  cat > /tmp/trophyroom/android/key.properties << 'EOF'
storePassword=trophyroom
keyPassword=trophyroom
keyAlias=release
storeFile=/tmp/release.keystore
EOF
fi

cd /tmp/trophyroom
flutter build apk --release --build-number=$2 --build-name=1.0.$2
cp build/app/outputs/flutter-apk/app-release.apk /tmp/TrophyRoom.apk
file /tmp/TrophyRoom.apk
ls -lh /tmp/TrophyRoom.apk
