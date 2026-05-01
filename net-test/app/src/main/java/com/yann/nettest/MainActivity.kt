package com.yann.nettest

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Try 1: Open system app settings (triggers permission dialog on some ROMs)
        findViewById<Button>(R.id.btn_settings).setOnClickListener {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${packageName}")
            }
            startActivity(intent)
        }
        
        // Try 2: Test HTTP connection
        findViewById<Button>(R.id.btn_http).setOnClickListener {
            testHttp()
        }
        
        // Auto-trigger settings on first launch
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${packageName}")
        }
        startActivity(intent)
    }
    
    private fun testHttp() {
        val tv = findViewById<TextView>(R.id.tv_result)
        tv.text = "Testing..."
        
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val result = withContext(Dispatchers.IO) {
                    val url = URL("https://httpbin.org/ip")
                    val conn = url.openConnection() as HttpURLConnection
                    conn.connectTimeout = 8000
                    conn.readTimeout = 8000
                    conn.requestMethod = "GET"
                    
                    val reader = BufferedReader(InputStreamReader(conn.inputStream))
                    val text = reader.readText()
                    reader.close()
                    conn.disconnect()
                    text
                }
                tv.text = "SUCCESS: $result"
                Toast.makeText(this@MainActivity, "网络正常!", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                tv.text = "FAILED: ${e.message}"
                Log.e("NetTest", "HTTP test failed", e)
            }
        }
    }
}
