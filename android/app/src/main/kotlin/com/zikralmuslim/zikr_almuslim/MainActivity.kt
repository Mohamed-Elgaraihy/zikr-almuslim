package com.zikralmuslim.zikr_almuslim

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var deviceChannel: MethodChannel? = null
    private var pendingSlot: String? = null
    private var pickResult: MethodChannel.Result? = null

    private val pickLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent(),
    ) { uri ->
        val result = pickResult
        pickResult = null
        if (result == null) return@registerForActivityResult
        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }
        result.success(readText(uri))
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        rememberSlot(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val slot = intent.getStringExtra(EXTRA_SLOT) ?: return
        val channel = deviceChannel
        if (channel == null) {
            pendingSlot = slot
        } else {
            channel.invokeMethod("openSlot", slot)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zikr/links")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                }
            }

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zikr/device")
        deviceChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "share" -> share(call.argument("text"), call.argument("subject"), result)
                "pickText" -> {
                    pickResult?.success(null)
                    pickResult = result
                    pickLauncher.launch("*/*")
                }
                "setAwake" -> {
                    val on = call.argument<Boolean>("on") == true
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(true)
                }
                "updateWidget" -> {
                    val day = call.argument<String>("day").orEmpty()
                    val morning = call.argument<Boolean>("morningDone") == true
                    val evening = call.argument<Boolean>("eveningDone") == true
                    getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .putString("day", day)
                        .putBoolean("morningDone", morning)
                        .putBoolean("eveningDone", evening)
                        .apply()
                    WirdWidgetProvider.push(this)
                    result.success(true)
                }
                "takePendingSlot" -> {
                    val slot = pendingSlot
                    pendingSlot = null
                    result.success(slot)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun rememberSlot(intent: Intent?) {
        pendingSlot = intent?.getStringExtra(EXTRA_SLOT) ?: pendingSlot
    }

    private fun share(text: String?, subject: String?, result: MethodChannel.Result) {
        if (text.isNullOrEmpty()) {
            result.success(false)
            return
        }
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            if (!subject.isNullOrBlank()) putExtra(Intent.EXTRA_SUBJECT, subject)
        }
        try {
            startActivity(Intent.createChooser(send, subject ?: "مشاركة"))
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.success(false)
        }
    }

    private fun readText(uri: Uri): String? {
        return try {
            contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        const val EXTRA_SLOT = "zikr_slot"
        const val WIDGET_PREFS = "zikr_widget"
    }
}
