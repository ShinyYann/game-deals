
package com.yann.trophyroom

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
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

class NativeHttpPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.yann.trophyroom/native_http")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "httpGet") {
            val urlStr = call.argument<String>("url") ?: ""
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
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
