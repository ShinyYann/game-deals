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
                        val prefs = getFlutterPrefs(applicationContext)
                        val views = android.widget.RemoteViews(
                            applicationContext.packageName,
                            R.layout.trophy_widget
                        )

                        val title = prefs.getString("widget_title", "🏆 奖杯屋") ?: "🏆 奖杯屋"
                        val psn = prefs.getString("widget_psn", "🏆 PSN: -") ?: "🏆 PSN: -"
                        val steam = prefs.getString("widget_steam", "🎮 Steam: -") ?: "🎮 Steam: -"
                        val swi = prefs.getString("widget_switch", "🕹️ Switch: -") ?: "🕹️ Switch: -"
                        val poke = prefs.getString("widget_pokemon", "🐉 宝可梦: -") ?: "🐉 宝可梦: -"
                        val updated = prefs.getString("widget_updated", "--") ?: "--"

                        android.util.Log.d("TrophyWidget", "refreshWidget: title=$title psn=$psn steam=$steam")

                        views.setTextViewText(R.id.widget_title, title)
                        views.setTextViewText(R.id.widget_psn, psn)
                        views.setTextViewText(R.id.widget_steam, steam)
                        views.setTextViewText(R.id.widget_switch, swi)
                        views.setTextViewText(R.id.widget_updated, updated)
                        views.setTextViewText(R.id.widget_pokemon, poke)

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
                        // 兜底：强制重新触发 onUpdate（如果 ids 为空）
                        if (ids.isEmpty()) {
                            android.util.Log.d("TrophyWidget", "refreshWidget: ids empty, calling provider.forceUpdate")
                            val provider = TrophyWidgetProvider()
                            provider.forceUpdate(applicationContext)
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

    /** 安装 APK（Android 7.0+ 使用 FileProvider） */
    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw Exception("APK file not found: $path")
        }
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )
        val intent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    /** 获取与 Flutter shared_preferences 插件相同的 SharedPreferences 文件 */
    private fun getFlutterPrefs(context: Context): android.content.SharedPreferences {
        return context.getSharedPreferences(
            context.packageName + "_preferences",
            Context.MODE_PRIVATE
        )
    }
}
