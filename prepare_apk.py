"""Prepare Android project structure for GitHub Actions APK build."""
import os, struct, zlib

# Create icons
def png(w, h):
    raw = b''
    for y in range(h):
        raw += b'\x00'
        for x in range(w):
            cx, cy = w // 2, h // 2
            d = ((x - cx)**2 + (y - cy)**2)**0.5
            if d < w * 0.26 or abs(x - w // 2) < w * 0.1:
                raw += bytes([200, 200, 220, 255])
            else:
                raw += bytes([15, 22, 48, 255])

    def c(ty, d):
        return struct.pack('>I', len(d)) + ty + d + struct.pack('>I', zlib.crc32(ty + d) & 0xffffffff)

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    return sig + c(b'IHDR', ihdr) + c(b'IDAT', zlib.compress(raw)) + c(b'IEND', b'')

for name, size in [('mipmap-hdpi', 72), ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144), ('mipmap-xxxhdpi', 192)]:
    d = f'android/app/src/main/res/{name}'
    os.makedirs(d, exist_ok=True)
    with open(f'{d}/ic_launcher.png', 'wb') as f:
        f.write(png(size))

# Create directories
for d in ['android/app/src/main/java/com/yann/gamedeals',
          'android/app/src/main/res/values',
          'android/gradle/wrapper']:
    os.makedirs(d, exist_ok=True)

# AndroidManifest.xml
with open('android/app/src/main/AndroidManifest.xml', 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.yann.gamedeals">
  <uses-permission android:name="android.permission.INTERNET"/>
  <application android:allowBackup="true" android:icon="@mipmap/ic_launcher" android:label="Yann\u5c0f\u7ad9" android:theme="@style/AppTheme" android:usesCleartextTraffic="true">
    <activity android:name=".MainActivity" android:exported="true" android:configChanges="orientation|screenSize|keyboardHidden">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
''')

# styles.xml
with open('android/app/src/main/res/values/styles.xml', 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="AppTheme" parent="Theme.AppCompat.NoActionBar">
    <item name="android:windowBackground">#0f0f1a</item>
  </style>
</resources>
''')

# MainActivity.java
with open('android/app/src/main/java/com/yann/gamedeals/MainActivity.java', 'w') as f:
    f.write('''package com.yann.gamedeals;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import androidx.appcompat.app.AppCompatActivity;
public class MainActivity extends AppCompatActivity {
  private WebView wv;
  @Override protected void onCreate(Bundle b) {
    super.onCreate(b); wv = new WebView(this); setContentView(wv);
    WebSettings s = wv.getSettings();
    s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true);
    s.setLoadWithOverviewMode(true); s.setUseWideViewPort(true);
    wv.setWebViewClient(new WebViewClient());
    wv.loadUrl("https://shinyyann.github.io/game-deals/");
  }
  @Override public void onBackPressed() {
    if (wv.canGoBack()) wv.goBack(); else super.onBackPressed();
  }
}
''')

# build.gradle (project)
with open('android/build.gradle', 'w') as f:
    f.write('''buildscript {
  repositories { google(); mavenCentral() }
  dependencies { classpath "com.android.tools.build:gradle:8.2.0" }
}
allprojects { repositories { google(); mavenCentral() } }
''')

# settings.gradle
with open('android/settings.gradle', 'w') as f:
    f.write('rootProject.name = "YannGameDeals"\ninclude ":app"\n')

# gradle.properties
with open('android/gradle.properties', 'w') as f:
    f.write('org.gradle.jvmargs=-Xmx2048m\nandroid.useAndroidX=true\n')

# app/build.gradle
with open('android/app/build.gradle', 'w') as f:
    f.write('''plugins { id "com.android.application" }
android {
  namespace "com.yann.gamedeals"
  compileSdk 34
  defaultConfig {
    applicationId "com.yann.gamedeals"
    minSdk 21
    targetSdk 34
    versionCode 1
    versionName "1.0.0"
  }
  buildTypes { release { minifyEnabled false } }
}
dependencies { implementation "androidx.appcompat:appcompat:1.6.1" }
''')

# gradle-wrapper.properties
with open('android/gradle/wrapper/gradle-wrapper.properties', 'w') as f:
    f.write('''distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''')

print("Android project prepared successfully!")
