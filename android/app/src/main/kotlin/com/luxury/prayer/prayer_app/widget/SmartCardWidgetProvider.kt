package com.luxury.prayer.prayer_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.concurrent.TimeUnit

class SmartCardWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val ACTION_SHOW_REMAINING = "com.luxury.prayer.prayer_app.SHOW_REMAINING_SMART_CARD"
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateReceiver.scheduleUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateReceiver.checkAndCancelUpdates(context)
    }

    override fun onReceive(context: Context, intent: Intent?) {
        super.onReceive(context, intent)
        when {
            WidgetEngine.isToggleAction(intent) -> {
                val id = intent?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                    ?: AppWidgetManager.INVALID_APPWIDGET_ID
                if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    WidgetEngine.toggleDisplayMode(context, "smart_mode_$id")
                    val manager = AppWidgetManager.getInstance(context)
                    onUpdate(context, manager, intArrayOf(id))
                }
            }
            intent?.action == ACTION_SHOW_REMAINING -> {
                val index = intent.getIntExtra("index", -1)
                val appWidgetId = intent.getIntExtra("appWidgetId", AppWidgetManager.INVALID_APPWIDGET_ID)
                if (index == -1 || appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

                val data = HomeWidgetPlugin.getData(context)
                val millis = data.getLong("prayer_time_millis_$index", 0L)
                if (millis <= 0L) return

                val now = System.currentTimeMillis()
                val diff = millis - now
                val text = if (diff > 0) {
                    val hours = TimeUnit.MILLISECONDS.toHours(diff)
                    val minutes = TimeUnit.MILLISECONDS.toMinutes(diff) % 60
                    String.format("-%02d:%02d", hours, minutes)
                } else {
                    val abs = kotlin.math.abs(diff)
                    val hours = TimeUnit.MILLISECONDS.toHours(abs)
                    val minutes = TimeUnit.MILLISECONDS.toMinutes(abs) % 60
                    String.format("+%02d:%02d", hours, minutes)
                }

                val views = RemoteViews(context.packageName, R.layout.widget_smart_card)
                views.setTextViewText(getResId(index, "time"), text)
                AppWidgetManager.getInstance(context).partiallyUpdateAppWidget(appWidgetId, views)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_smart_card)
            val theme = WidgetEngine.resolveTheme(data, "smart_card")
            val sizeClass = WidgetEngine.resolveSizeClass(appWidgetManager, appWidgetId)
            val mode = WidgetEngine.getDisplayMode(context, "smart_mode_$appWidgetId")

            views.setInt(R.id.iv_background, "setColorFilter", theme.background)

            val nextPrayerName = data.getString("next_prayer_name", "--")
            val countdown = WidgetEngine.computeTimeRemaining(data, shortFormat = true)
            val nextPrayerTime = data.getString("next_prayer_time", "--:--")
            views.setTextViewText(R.id.tv_next_prayer, nextPrayerName)
            views.setTextViewText(R.id.tv_countdown, if (mode == "time") nextPrayerTime else countdown)
            views.setTextViewText(R.id.tv_header_label, if (mode == "time") "وقت الصلاة" else "الصلاة القادمة")
            views.setTextColor(R.id.tv_next_prayer, theme.accent)
            views.setTextColor(R.id.tv_countdown, theme.text)
            views.setTextColor(R.id.tv_header_label, WidgetEngine.applyAlpha(theme.text, 136))

            when (sizeClass) {
                WidgetSizeClass.COMPACT -> {
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer, 13f)
                    WidgetEngine.setTextSize(views, R.id.tv_countdown, 16f)
                }
                WidgetSizeClass.MEDIUM -> {
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer, 16f)
                    WidgetEngine.setTextSize(views, R.id.tv_countdown, 20f)
                }
                WidgetSizeClass.EXPANDED -> {
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer, 18f)
                    WidgetEngine.setTextSize(views, R.id.tv_countdown, 24f)
                }
            }

            val now = System.currentTimeMillis()
            val nextPrayerIndex = WidgetEngine.computeNextPrayerIndex(data, now)
            for (i in 0..4) {
                val name = data.getString("prayer_name_$i", "--")
                val time = data.getString("prayer_time_$i", "--:--")
                val nameId = getResId(i, "name")
                val timeId = getResId(i, "time")
                val itemId = getResId(i, "item")

                views.setTextViewText(nameId, name)
                views.setTextViewText(timeId, time)
                if (i == nextPrayerIndex) {
                    views.setTextColor(nameId, theme.accent)
                    views.setTextColor(timeId, theme.text)
                } else {
                    views.setTextColor(nameId, WidgetEngine.applyAlpha(theme.text, 136))
                    views.setTextColor(timeId, WidgetEngine.applyAlpha(theme.text, 200))
                }

                val intent = Intent(context, SmartCardWidgetProvider::class.java).apply {
                    action = ACTION_SHOW_REMAINING
                    putExtra("index", i)
                    putExtra("appWidgetId", appWidgetId)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    i + (appWidgetId * 10),
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(itemId, pendingIntent)
            }

            views.setOnClickPendingIntent(
                R.id.widget_smart_card_root,
                WidgetEngine.openAppIntent(context, appWidgetId + 2000)
            )
            views.setOnClickPendingIntent(
                R.id.tv_countdown,
                WidgetEngine.createToggleIntent(context, SmartCardWidgetProvider::class.java, appWidgetId)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        val hasActive = appWidgetManager.getAppWidgetIds(
            ComponentName(context, SmartCardWidgetProvider::class.java)
        ).isNotEmpty()
        if (hasActive) {
            WidgetUpdateReceiver.scheduleUpdates(context)
        }
    }

    private fun getResId(index: Int, type: String): Int {
        return when (index) {
            0 -> when (type) { "name" -> R.id.tv_name_0; "time" -> R.id.tv_time_0; else -> R.id.item_0 }
            1 -> when (type) { "name" -> R.id.tv_name_1; "time" -> R.id.tv_time_1; else -> R.id.item_1 }
            2 -> when (type) { "name" -> R.id.tv_name_2; "time" -> R.id.tv_time_2; else -> R.id.item_2 }
            3 -> when (type) { "name" -> R.id.tv_name_3; "time" -> R.id.tv_time_3; else -> R.id.item_3 }
            4 -> when (type) { "name" -> R.id.tv_name_4; "time" -> R.id.tv_time_4; else -> R.id.item_4 }
            else -> R.id.tv_name_0
        }
    }
}
