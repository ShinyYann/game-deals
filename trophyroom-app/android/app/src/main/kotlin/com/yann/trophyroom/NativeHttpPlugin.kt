package com.yann.trophyroom

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

class NativeHttpPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var applicationContext: Context? = null
    private var permissionRequested = false
    private var pendingUrl: String? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.yann.trophyroom/native_http")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "httpGet" -> {
                val urlStr = call.argument<String>("url") ?: ""
                // If permission not yet requested on this app launch, request it
                if (!permissionRequested) {
                    requestNetworkPermission(urlStr, result)
                } else {
                    executeHttpGet(urlStr, result)
                }
            }
            "requestNetworkPermission" -> {
                // Explicit call from Flutter to request network permission
                openNetworkSettings()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestNetworkPermission(urlStr: String, result: Result) {
        permissionRequested = true
        val activity = activityBinding?.activity ?: run {
            // No activity context, just try the request
            executeHttpGet(urlStr, result)
            return
        }

        val ctx = applicationContext ?: run {
            executeHttpGet(urlStr, result)
            return
        }

        // Try to open the app's application details settings page
        // This triggers the "允许联网" dialog on some Chinese ROMs
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${ctx.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        ctx.startActivity(intent)

        // Still execute the HTTP request
        executeHttpGet(urlStr, result)
    }

    private fun openNetworkSettings() {
        val ctx = applicationContext ?: return
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${ctx.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        ctx.startActivity(intent)
    }

    private fun executeHttpGet(urlStr: String, result: Result) {
        Thread {
            try {
                // Trust all certs (for testing)
                val trustAllCerts = arrayOf<TrustManager>(object : X509TrustManager {
                    override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
                    override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
                    override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
                })
                val sc = SSLContext.getInstance("TLS")
                sc.init(null, trustAllCerts, SecureRandom())
                HttpsURLConnection.setDefaultSSLSocketFactory(sc.socketFactory)
                HttpsURLConnection.setDefaultHostnameVerifier(HostnameVerifier { _, _ -> true })

                val url = URL(urlStr)
                val conn = url.openConnection() as HttpURLConnection
                conn.setRequestProperty("User-Agent", "TrophyRoom/1.0")
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                conn.requestMethod = "GET"

                val responseCode = conn.responseCode
                val reader = BufferedReader(InputStreamReader(if (responseCode == 200) conn.inputStream else conn.errorStream))
                val response = reader.readText()
                reader.close()
                conn.disconnect()

                result.success(response)
            } catch (e: Exception) {
                result.error("HTTP_ERROR", e.message ?: "Unknown", null)
            }
        }.start()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware implementations
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }
}
