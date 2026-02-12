package com.luxury.prayer.prayer_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PremiumClockWidgetProvider : AppWidgetProvider() {

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
        if (WidgetEngine.isToggleAction(intent)) {
            val id = intent?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                ?: AppWidgetManager.INVALID_APPWIDGET_ID
            if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                WidgetEngine.toggleDisplayMode(context, "premium_mode_$id")
                val manager = AppWidgetManager.getInstance(context)
                onUpdate(context, manager, intArrayOf(id))
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_premium_clock)
            val theme = WidgetEngine.resolveTheme(widgetData, "premium_clock")
            val sizeClass = WidgetEngine.resolveSizeClass(appWidgetManager, appWidgetId)
            val mode = WidgetEngine.getDisplayMode(context, "premium_mode_$appWidgetId")

            val prayerName = widgetData.getString("next_prayer_name", "--")
            val prayerTime = widgetData.getString("next_prayer_time", "--:--")
            val countdown = WidgetEngine.computeTimeRemaining(widgetData, shortFormat = true)
            val displayPrimary = if (mode == "time") prayerTime else countdown
            val displaySecondary = if (mode == "time") countdown else prayerTime

            views.setInt(R.id.iv_background, "setColorFilter", theme.background)
            views.setTextViewText(R.id.tv_next_prayer_name, prayerName)
            views.setTextViewText(R.id.tv_time_remaining, displayPrimary)
            views.setTextViewText(R.id.tv_prayer_time, displaySecondary)

            views.setTextColor(R.id.tv_clock_time, theme.accent)
            views.setTextColor(R.id.tv_clock_seconds, WidgetEngine.applyAlpha(theme.accent, 136))
            views.setTextColor(R.id.tv_next_prayer_name, theme.text)
            views.setTextColor(R.id.tv_time_remaining, WidgetEngine.applyAlpha(theme.text, 190))
            views.setTextColor(R.id.tv_prayer_time, WidgetEngine.applyAlpha(theme.text, 140))

            val now = System.currentTimeMillis()
            val nextIndex = WidgetEngine.computeNextPrayerIndex(widgetData, now)
            var nextMillis = 0L
            var prevMillis = 0L
            if (nextIndex >= 0) {
                nextMillis = widgetData.getLong("prayer_time_millis_$nextIndex", 0L)
                if (nextIndex > 0) {
                    prevMillis = widgetData.getLong("prayer_time_millis_${nextIndex - 1}", 0L)
                }
            }
            if (nextMillis > 0 && prevMillis > 0 && nextMillis > prevMillis) {
                val progress = (((now - prevMillis).toFloat() / (nextMillis - prevMillis).toFloat()) * 100f)
                    .toInt().coerceIn(0, 100)
                views.setProgressBar(R.id.progress_ring, 100, progress, false)
            } else {
                views.setProgressBar(R.id.progress_ring, 100, 50, false)
            }

            when (sizeClass) {
                WidgetSizeClass.COMPACT -> {
                    WidgetEngine.setTextSize(views, R.id.tv_clock_time, 28f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer_name, 13f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 11f)
                }
                WidgetSizeClass.MEDIUM -> {
                    WidgetEngine.setTextSize(views, R.id.tv_clock_time, 34f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer_name, 16f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 13f)
                }
                WidgetSizeClass.EXPANDED -> {
                    WidgetEngine.setTextSize(views, R.id.tv_clock_time, 40f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_prayer_name, 18f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 15f)
                }
            }

            views.setOnClickPendingIntent(
                R.id.widget_clock_root,
                WidgetEngine.openAppIntent(context, appWidgetId + 3000)
            )
            views.setOnClickPendingIntent(
                R.id.tv_time_remaining,
                WidgetEngine.createToggleIntent(context, PremiumClockWidgetProvider::class.java, appWidgetId)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        val hasActive = appWidgetManager.getAppWidgetIds(
            ComponentName(context, PremiumClockWidgetProvider::class.java)
        ).isNotEmpty()
        if (hasActive) {
            WidgetUpdateReceiver.scheduleUpdates(context)
        }
    }
}
