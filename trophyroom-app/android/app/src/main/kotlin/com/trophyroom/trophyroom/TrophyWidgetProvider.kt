package com.trophyroom.trophyroom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * TrophyRoom 桌面小组件
 * 从 Flutter 的 SharedPreferences 读取数据
 */
class TrophyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 先尝试读 SharedPreferences
        val prefs = try {
            context.getSharedPreferences(
                context.packageName + "_preferences",
                Context.MODE_PRIVATE
            )
        } catch (_: Exception) { null }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.trophy_widget)

            val title = prefs?.getString("widget_title", null) ?: "🏆 奖杯屋"
            val psn = prefs?.getString("widget_psn", null) ?: "🏆 PSN: -"
            val steam = prefs?.getString("widget_steam", null) ?: "🎮 Steam: -"
            val swi = prefs?.getString("widget_switch", null) ?: "🕹️ Switch: -"
            val poke = prefs?.getString("widget_pokemon", null) ?: "🐉 宝可梦: -"
            val updated = prefs?.getString("widget_updated", null) ?: "--"

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_psn, psn)
            views.setTextViewText(R.id.widget_steam, steam)
            views.setTextViewText(R.id.widget_switch, swi)
            views.setTextViewText(R.id.widget_updated, updated)
            views.setTextViewText(R.id.widget_pokemon, poke)

            // 点击打开 App
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    /**
     * 强制刷新所有组件
     */
    fun forceUpdate(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, TrophyWidgetProvider::class.java)
        )
        onUpdate(context, manager, ids)
    }
}
