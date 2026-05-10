package com.trophyroom.trophyroom

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val WIDGET_CHANNEL = "com.trophyroom.trophyroom/widget"
        const val UPDATE_CHANNEL = "com.trophyroom.trophyroom/update"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 桌面小组件频道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "refreshWidget" -> {
                    try {
                        val views = android.widget.RemoteViews(
                            applicationContext.packageName,
                            R.layout.trophy_widget
                        )

                        val args = call.arguments as? Map<*, *>
                        val title = args?.get("title")?.toString() ?: "🏆 奖杯屋"
                        val psn = args?.get("psn")?.toString() ?: "🏆 PSN: -"
                        val steam = args?.get("steam")?.toString() ?: "🎮 Steam: -"
                        val switch = args?.get("switch")?.toString() ?: "🕹️ Switch: -"
                        val subtitle = args?.get("updated")?.toString() ?: "--"

                        android.util.Log.d("TrophyWidget", "refreshWidget: title=$title psn=$psn steam=$steam")

                        views.setTextViewText(R.id.widget_title, title)
                        views.setTextViewText(R.id.widget_psn, psn)
                        views.setTextViewText(R.id.widget_steam, steam)
                        views.setTextViewText(R.id.widget_switch, switch)
                        views.setTextViewText(R.id.widget_subtitle, subtitle)

                        // 点击打开 App
                        val intent = applicationContext.packageManager
                            .getLaunchIntentForPackage(applicationContext.packageName)
                        if (intent != null) {
                            val pendingIntent = android.app.PendingIntent.getActivity(
                                applicationContext, 0, intent,
                                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                            )
                            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                        }

                        // 更新所有组件实例
                        val manager = AppWidgetManager.getInstance(applicationContext)
                        val cn = android.content.ComponentName(
                            applicationContext,
                            TrophyWidgetProvider::class.java
                        )
                        val ids = manager.getAppWidgetIds(cn)
                        android.util.Log.d("TrophyWidget", "refreshWidget: cn=${cn} ids=${ids.size}")

                        for (id in ids) {
                            manager.updateAppWidget(id, views)
                        }
                        // 兜底：尝试触发 onUpdate（如果 ids 为空）
                        if (ids.isEmpty()) {
                            android.util.Log.d("TrophyWidget", "refreshWidget: no widget ids found, nothing to update")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 热更新频道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    try {
                        val path = call.argument<String>("path") ?: throw Exception("Missing path")
                        installApk(path)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                "getVersionCode" -> {
                    try {
                        val pkgInfo = applicationContext.packageManager.getPackageInfo(applicationContext.packageName, 0)
                        result.success(pkgInfo.longVersionCode.toInt())
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** 安装 APK — PackageInstaller Session API (Android 5.0+) */
    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw Exception("APK file not found: $path")
        }

        val packageInstaller = applicationContext.packageManager.packageInstaller
        val params = android.content.pm.PackageInstaller.SessionParams(
            android.content.pm.PackageInstaller.SessionParams.MODE_FULL_INSTALL
        )
        val sessionId = packageInstaller.createSession(params)
        val session = packageInstaller.openSession(sessionId)

        try {
            // 写入 APK 内容
            file.inputStream().use { input ->
                session.openWrite("TrophyRoom", 0, file.length()).use { out ->
                    input.copyTo(out, 8192)
                }
            }

            // 创建安装结果回调
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                applicationContext,
                sessionId,
                android.content.Intent(applicationContext, InstallReceiver::class.java).apply {
                    putExtra("sessionId", sessionId)
                },
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )

            // 提交安装（Session.commit() API 21+ 可用）
            session.commit(pendingIntent.intentSender)
            android.util.Log.d("TrophyRoom", "installApk: session=$sessionId committed")
        } catch (e: Exception) {
            session.abandon()
            android.util.Log.e("TrophyRoom", "installApk error", e)
            throw Exception("安装失败: ${e.message}")
        }
    }
}
