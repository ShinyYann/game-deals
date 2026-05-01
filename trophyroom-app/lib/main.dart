import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pages/home_page.dart';
import 'pages/trophy_page.dart';
import 'pages/deals_page.dart';
import 'pages/guide_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'models/app_theme.dart';

/// Save crash log locally + try HTTP report
Future<void> _reportCrash(String type, dynamic error, StackTrace? stack) async {
  final log = '[${DateTime.now().toIso8601String()}][$type] $error\n$stack';
  // Always save to local file
  try {
    final dir = Directory('/storage/emulated/0/Android/data/com.yann.trophyroom/files');
    if (!await dir.exists()) {
      dir = Directory('/data/data/com.yann.trophyroom/files');
    }
    if (await dir.exists()) {
      await File('${dir.path}/crash.log').writeAsString('$log\n${"=" * 40}\n', mode: FileMode.append);
    }
  } catch (_) {}
  // Try POST to a free pastebin service
  try {
    final resp = await http.post(
      Uri.parse('https://dpaste.org/api/'),
      body: {'content': log, 'format': 'url', 'expiry_days': '7'},
    ).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final url = resp.body.trim();
      // Also try to write the URL locally
      try {
        final dir = Directory('/storage/emulated/0/Android/data/com.yann.trophyroom/files');
        if (!await dir.exists()) {
          dir = Directory('/data/data/com.yann.trophyroom/files');
        }
        if (await dir.exists()) {
          await File('${dir.path}/crash.url').writeAsString(url);
        }
      } catch (_) {}
    }
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    await _reportCrash('FLUTTER', details.exception, details.stack);
  };

  runZonedGuarded(() async {
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A12),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      runApp(const TrophyRoomApp());
    } catch (e, stack) {
      await _reportCrash('INIT', e, stack);
    }
  }, (Object error, StackTrace stack) async {
    await _reportCrash('ZONE', error, stack);
  });
}
