package com.alaa.anti_tamper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.util.Base64
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.alaa.anti_tamper/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSignature" -> result.success(getAppSignature())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getAppSignature(): String {
        return try {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
            val sig = info.signatures?.get(0) ?: return "ERROR: no signature"
            val md = MessageDigest.getInstance("SHA-256")
            md.update(sig.toByteArray())
            Base64.encodeToString(md.digest(), Base64.DEFAULT).trim()
        } catch (e: Exception) {
            "ERROR: ${e.message}"
        }
    }
}
