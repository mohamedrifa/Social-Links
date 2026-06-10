package com.example.social_link

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "social_link/app_availability"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledPlatforms" -> result.success(getInstalledPlatforms())
                "canOpenScheme" -> {
                    val scheme = call.argument<String>("scheme")
                    result.success(canOpenScheme(scheme))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledPlatforms(): List<String> {
        val packages = mapOf(
            "facebook" to listOf("com.facebook.katana"),
            "twitter" to listOf("com.twitter.android"),
            "instagram" to listOf("com.instagram.android"),
            "whatsapp" to listOf("com.whatsapp", "com.whatsapp.w4b"),
            "telegram" to listOf("org.telegram.messenger"),
            "linkedin" to listOf("com.linkedin.android"),
            "pinterest" to listOf("com.pinterest"),
            "tiktok" to listOf("com.zhiliaoapp.musically"),
            "snapchat" to listOf("com.snapchat.android"),
            "reddit" to listOf("com.reddit.frontpage"),
            "youtube" to listOf("com.google.android.youtube"),
            "wechat" to listOf("com.tencent.mm")
        )

        val installed = mutableListOf<String>()
        packages.forEach { (platform, packageNames) ->
            if (packageNames.any { isPackageInstalled(it) }) {
                installed.add(platform)
            }
        }

        if (canOpenScheme("mailto")) {
            installed.add("email")
        }

        return installed
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun canOpenScheme(scheme: String?): Boolean {
        if (scheme.isNullOrBlank()) return false
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = android.net.Uri.parse("$scheme:")
        }
        return intent.resolveActivity(packageManager) != null
    }
}
