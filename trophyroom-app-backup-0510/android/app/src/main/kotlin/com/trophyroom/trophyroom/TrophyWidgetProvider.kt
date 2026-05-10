package com.trophyroom.trophyroom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews

class TrophyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        try {
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.trophy_widget)
                // 使用 XML 布局中的默认文本（无需读 SharedPreferences，因为 Flutter 用 DataStore 格式不兼容）
                views.setTextViewText(R.id.widget_title, "🏆 奖杯屋")
                views.setTextViewText(R.id.widget_psn, "🏆 PSN: -")
                views.setTextViewText(R.id.widget_steam, "🎮 Steam: -")
                views.setTextViewText(R.id.widget_switch, "🕹️ Switch: -")
                views.setTextViewText(R.id.widget_subtitle, "打开App更新")
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pi = PendingIntent.getActivity(context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    views.setOnClickPendingIntent(R.id.widget_container, pi)
                }
                mgr.updateAppWidget(id, views)
            }
        } catch (e: Exception) {
            Log.e("TrophyWidget", "onUpdate failed", e)
        }
    }
}
