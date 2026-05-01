package com.yann.installhelper

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.util.Log
import android.widget.*
import android.widget.AdapterView.OnItemClickListener
import androidx.appcompat.app.AppCompatActivity
import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : AppCompatActivity() {
    private lateinit var listView: ListView
    private lateinit var statusText: TextView
    private var apkFiles: List<File> = listOf()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check and request storage permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }

        // LinearLayout
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(24, 24, 24, 24)
        layout.setBackgroundColor(0xFF0A0A12.toInt())

        // Title
        val title = TextView(this)
        title.text = "InstallHelper \ud83d\udcf1"
        title.textSize = 24f
        title.setTextColor(0xFFFFFFFF.toInt())
        title.gravity = android.view.Gravity.CENTER
        title.setPadding(0, 24, 0, 24)
        layout.addView(title)

        // Subtitle
        val subtitle = TextView(this)
        subtitle.text = "安装在 Download 文件夹中的 APK（模拟 Play Store 安装）"
        subtitle.textSize = 14f
        subtitle.setTextColor(0xFFAAAAAA.toInt())
        subtitle.gravity = android.view.Gravity.CENTER
        subtitle.setPadding(0, 0, 0, 24)
        layout.addView(subtitle)

        // Status text
        statusText = TextView(this)
        statusText.text = "扫描中..."
        statusText.textSize = 14f
        statusText.setTextColor(0xFFAAAAAA.toInt())
        statusText.gravity = android.view.Gravity.CENTER
        statusText.setPadding(0, 0, 0, 16)
        layout.addView(statusText)

        // ListView for APK files
        listView = ListView(this)
        layout.addView(listView)

        setContentView(layout)

        scanApks()
    }

    override fun onResume() {
        super.onResume()
        scanApks()
    }

    private fun scanApks() {
        val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        apkFiles = downloadDir.listFiles()
            ?.filter { it.name.endsWith(".apk") }
            ?.sortedByDescending { it.lastModified() }
            ?: listOf()

        if (apkFiles.isEmpty()) {
            statusText.text = "\u274c Download 文件夹中没有找到 APK 文件"
            listView.adapter = null
            return
        }

        statusText.text = "\u2705 找到 ${apkFiles.size} 个 APK 文件"
        val names = apkFiles.map { "${it.name} (${it.length() / 1024 / 1024}MB)" }.toTypedArray()
        listView.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, names)

        listView.onItemClickListener = OnItemClickListener { _, _, position, _ ->
            installApk(apkFiles[position])
        }
    }

    private fun installApk(apkFile: File) {
        statusText.text = "\ud83d\udd04 正在安装: ${apkFile.name}..."
        
        try {
            // Use pm install with Google Play installer flag
            val cmd = "pm install -i com.android.vending -r "${apkFile.absolutePath}""
            Log.d("InstallHelper", "Running: $cmd")

            val runtime = Runtime.getRuntime()
            val process = runtime.exec(arrayOf("sh", "-c", "echo 'installhelper' | su -c '$cmd' 2>&1"))
            
            // Also try without root
            val process2 = runtime.exec(arrayOf("sh", "-c", "$cmd 2>&1"))
            
            val reader = BufferedReader(InputStreamReader(process2.inputStream))
            val output = reader.readText()
            reader.close()
            
            val reader2 = BufferedReader(InputStreamReader(process2.errorStream))
            val err = reader2.readText()
            reader2.close()

            process2.waitFor()

            val result = output + err
            Log.d("InstallHelper", "Result: $result")

            runOnUiThread {
                if (result.contains("Success")) {
                    statusText.text = "\u2705 安装成功! ${apkFile.name}\n\n系统已记录安装来源为: Google Play"
                    Toast.makeText(this, "安装成功! 试试打开 TrophyRoom", Toast.LENGTH_LONG).show()
                } else if (result.contains("INSTALL_FAILED_ALREADY_EXISTS")) {
                    statusText.text = "\u2139\ufe0f 已存在，尝试卸载旧版本后再试"
                } else if (result.contains("Permission denied") || result.contains("not allowed")) {
                    // Try using the Intent-based install as fallback
                    statusText.text = "\u26a0\ufe0f Shell 方式被拒绝，换为系统安装器..."
                    installViaIntent(apkFile)
                } else {
                    statusText.text = "\u274c 失败: ${result.take(200)}"
                }
            }
        } catch (e: Exception) {
            runOnUiThread {
                statusText.text = "\u274c 异常: ${e.message?.take(100)}"
            }
        }
    }

    private fun installViaIntent(apkFile: File) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.fromFile(apkFile),
                    "application/vnd.android.package-archive"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            statusText.text = "\u27a1\ufe0f 已打开系统安装器，安装后会尝试注册 Play Store 安装来源"
        } catch (e: Exception) {
            statusText.text = "\u274c 无法打开系统安装器: ${e.message?.take(100)}"
        }
    }
}
