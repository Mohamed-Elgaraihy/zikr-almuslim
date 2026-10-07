package com.zikralmuslim.zikr_almuslim

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class WirdWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            update(context, appWidgetManager, id)
        }
    }

    companion object {
        fun push(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WirdWidgetProvider::class.java),
            )
            for (id in ids) update(context, manager, id)
        }

        private fun update(
            context: Context,
            manager: AppWidgetManager,
            id: Int,
        ) {
            val prefs = context.getSharedPreferences(MainActivity.WIDGET_PREFS, Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val fresh = prefs.getString("day", "") == today
            val morningDone = fresh && prefs.getBoolean("morningDone", false)
            val eveningDone = fresh && prefs.getBoolean("eveningDone", false)
            val views = RemoteViews(context.packageName, R.layout.wird_widget)
            views.setTextViewText(R.id.morning_state, if (morningDone) "تم" else "باقٍ")
            views.setTextViewText(R.id.evening_state, if (eveningDone) "تم" else "باقٍ")
            views.setOnClickPendingIntent(R.id.slot_morning, open(context, "morning"))
            views.setOnClickPendingIntent(R.id.slot_evening, open(context, "evening"))
            manager.updateAppWidget(id, views)
        }

        private fun open(context: Context, slot: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "zikr.slot.$slot"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(MainActivity.EXTRA_SLOT, slot)
            }
            val request = if (slot == "morning") 31 else 32
            return PendingIntent.getActivity(
                context,
                request,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
