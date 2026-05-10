package com.trophyroom.trophyroom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class InstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val sessionId = intent.getIntExtra("sessionId", -1)
        val statusCode = intent.getIntExtra(
            android.content.pm.PackageInstaller.EXTRA_STATUS,
            -1
        )
        val message = intent.getStringExtra(
            android.content.pm.PackageInstaller.EXTRA_STATUS_MESSAGE
        )

        when (statusCode) {
            android.content.pm.PackageInstaller.STATUS_SUCCESS -> {
                android.util.Log.d("TrophyRoom", "InstallReceiver: 安装成功 session=$sessionId")
            }
            android.content.pm.PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                // 需要用户确认安装
                val confirmIntent = intent.getParcelableExtra<Intent>(
                    android.content.Intent.EXTRA_INTENT
                )
                if (confirmIntent != null) {
                    confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(confirmIntent)
                }
            }
            else -> {
                android.util.Log.e("TrophyRoom", "InstallReceiver: 安装失败 session=$sessionId status=$statusCode msg=$message")
            }
        }
    }
}
