package com.luxury.prayer.prayer_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.R
import es.antonborri.home_widget.HomeWidgetPlugin

class MinimalWidgetProvider : AppWidgetProvider() {

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
                WidgetEngine.toggleDisplayMode(context, "minimal_mode_$id")
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
            val views = RemoteViews(context.packageName, R.layout.widget_minimal)
            val theme = WidgetEngine.resolveTheme(widgetData, "minimal")
            val sizeClass = WidgetEngine.resolveSizeClass(appWidgetManager, appWidgetId)
            val displayMode = WidgetEngine.getDisplayMode(context, "minimal_mode_$appWidgetId")

            val prayerName = widgetData.getString("next_prayer_name", "--")
            val prayerTime = widgetData.getString("next_prayer_time", "--:--")
            val countdown = WidgetEngine.computeTimeRemaining(widgetData, shortFormat = true)
            val topLabel = if (displayMode == "time") "وقت الصلاة" else "الصلاة القادمة"
            val majorText = if (displayMode == "time") prayerTime else countdown
            val minorText = if (displayMode == "time") countdown else prayerTime

            views.setInt(R.id.iv_background, "setColorFilter", theme.background)
            views.setTextViewText(R.id.tv_label_next, topLabel)
            views.setTextViewText(R.id.tv_prayer_name, prayerName)
            views.setTextViewText(R.id.tv_time_remaining, majorText)
            views.setTextViewText(R.id.tv_next_time, minorText)

            views.setTextColor(R.id.tv_prayer_name, theme.accent)
            views.setTextColor(R.id.tv_time_remaining, theme.text)
            views.setTextColor(R.id.tv_next_time, WidgetEngine.applyAlpha(theme.text, 170))
            views.setTextColor(R.id.tv_label_next, WidgetEngine.applyAlpha(theme.text, 136))

            when (sizeClass) {
                WidgetSizeClass.COMPACT -> {
                    WidgetEngine.setTextSize(views, R.id.tv_prayer_name, 14f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 20f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_time, 10f)
                }
                WidgetSizeClass.MEDIUM -> {
                    WidgetEngine.setTextSize(views, R.id.tv_prayer_name, 17f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 26f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_time, 12f)
                }
                WidgetSizeClass.EXPANDED -> {
                    WidgetEngine.setTextSize(views, R.id.tv_prayer_name, 20f)
                    WidgetEngine.setTextSize(views, R.id.tv_time_remaining, 30f)
                    WidgetEngine.setTextSize(views, R.id.tv_next_time, 13f)
                }
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetEngine.openAppIntent(context, appWidgetId)
            )
            views.setOnClickPendingIntent(
                R.id.tv_time_remaining,
                WidgetEngine.createToggleIntent(context, MinimalWidgetProvider::class.java, appWidgetId)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        val hasActive = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinimalWidgetProvider::class.java)
        ).isNotEmpty()
        if (hasActive) {
            WidgetUpdateReceiver.scheduleUpdates(context)
        }
    }
}
