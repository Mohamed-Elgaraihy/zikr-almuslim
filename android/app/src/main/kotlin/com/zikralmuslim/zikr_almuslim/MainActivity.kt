package com.zikralmuslim.zikr_almuslim

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var deviceChannel: MethodChannel? = null
    private var pendingSlot: String? = null
    private var pickResult: MethodChannel.Result? = null
    private var openOemAfterBattery = false

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
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "*/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(intent, REQUEST_PICK)
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
                "allowBackground" -> {
                    allowBackgroundReminders()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_BATTERY) {
            if (openOemAfterBattery) {
                openOemAfterBattery = false
                openOemStartup()
            }
            return
        }
        if (requestCode != REQUEST_PICK) return
        val result = pickResult
        pickResult = null
        if (result == null) return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        result.success(readText(uri))
    }

    private fun allowBackgroundReminders() {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        val ignoring = power.isIgnoringBatteryOptimizations(packageName)
        if (!ignoring) {
            openOemAfterBattery = true
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            try {
                startActivityForResult(intent, REQUEST_BATTERY)
                return
            } catch (_: ActivityNotFoundException) {
                openOemAfterBattery = false
            }
        }
        if (!openOemStartup()) openAppDetails()
    }

    private fun openOemStartup(): Boolean {
        val screens = listOf(
            ComponentName(
                "com.hihonor.systemmanager",
                "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            ComponentName(
                "com.hihonor.systemmanager",
                "com.hihonor.systemmanager.appcontrol.activity.StartupAppControlActivity",
            ),
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
            ),
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            ),
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            ),
            ComponentName(
                "com.oppo.safe",
                "com.oppo.safe.permission.startup.StartupAppListActivity",
            ),
            ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            ),
            ComponentName(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            ),
            ComponentName(
                "com.oneplus.security",
                "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
            ),
            ComponentName(
                "com.asus.mobilemanager",
                "com.asus.mobilemanager.entry.FunctionActivity",
            ),
            ComponentName(
                "com.transsion.phonemaster",
                "com.cyin.himgr.autostart.AutoStartActivity",
            ),
            ComponentName(
                "com.letv.android.letvsafe",
                "com.letv.android.letvsafe.AutobootManageActivity",
            ),
        )
        for (component in screens) {
            try {
                startActivity(Intent().setComponent(component))
                return true
            } catch (_: Exception) {
                continue
            }
        }
        return false
    }

    private fun openAppDetails() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
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
        const val REQUEST_PICK = 4107
        const val REQUEST_BATTERY = 4108
    }
}
