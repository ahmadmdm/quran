package com.luxury.prayer.prayer_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.util.TypedValue
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.MainActivity
import java.util.concurrent.TimeUnit

enum class WidgetSizeClass {
    COMPACT,
    MEDIUM,
    EXPANDED
}

data class WidgetTheme(
    val background: Int,
    val text: Int,
    val accent: Int
)

object WidgetEngine {
    private const val ACTION_SMART_WIDGET_TOGGLE = "com.luxury.prayer.prayer_app.WIDGET_TOGGLE_VIEW"
    private const val SMART_WIDGET_PREFS = "smart_widget_state"

    fun resolveSizeClass(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): WidgetSizeClass {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        return when {
            minWidth >= 260 -> WidgetSizeClass.EXPANDED
            minWidth >= 180 -> WidgetSizeClass.MEDIUM
            else -> WidgetSizeClass.COMPACT
        }
    }

    fun resolveTheme(
        prefs: SharedPreferences,
        keyPrefix: String,
        defaultBackground: String = "#FF0F1629",
        defaultText: String = "#FFFFFFFF",
        defaultAccent: String = "#FFC9A24D"
    ): WidgetTheme {
        val slug = keyPrefix.lowercase().replace(' ', '_')
        val legacy = keyPrefix.lowercase().replace('_', ' ')
        val bg = parseColor(
            prefs.getString("${slug}_background_color", null)
                ?: prefs.getString("${legacy}_background_color", null)
                ?: defaultBackground,
            Color.parseColor(defaultBackground)
        )
        val text = parseColor(
            prefs.getString("${slug}_text_color", null)
                ?: prefs.getString("${legacy}_text_color", null)
                ?: defaultText,
            Color.parseColor(defaultText)
        )
        val accent = parseColor(
            prefs.getString("${slug}_accent_color", null)
                ?: prefs.getString("${legacy}_accent_color", null)
                ?: defaultAccent,
            Color.parseColor(defaultAccent)
        )
        return WidgetTheme(bg, text, accent)
    }

    fun computeNextPrayerIndex(prefs: SharedPreferences, now: Long = System.currentTimeMillis()): Int {
        for (i in 0..4) {
            val millis = prefs.getLong("prayer_time_millis_$i", 0L)
            if (millis > now) return i
        }
        return -1
    }

    fun computeTimeRemaining(
        prefs: SharedPreferences,
        now: Long = System.currentTimeMillis(),
        shortFormat: Boolean = false
    ): String {
        var nextPrayer = prefs.getLong("next_prayer_millis", 0L)
        if (nextPrayer <= now) {
            nextPrayer = Long.MAX_VALUE
            for (i in 0..5) {
                val candidate = prefs.getLong("prayer_time_millis_$i", 0L)
                if (candidate > now && candidate < nextPrayer) {
                    nextPrayer = candidate
                }
            }
        }
        if (nextPrayer == Long.MAX_VALUE || nextPrayer <= now) {
            return prefs.getString("time_remaining", "--:--") ?: "--:--"
        }
        val remaining = nextPrayer - now
        val hours = TimeUnit.MILLISECONDS.toHours(remaining)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(remaining) % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(remaining) % 60
        return if (shortFormat) {
            if (hours > 0) String.format("%d:%02d", hours, minutes) else String.format("%d د", minutes)
        } else {
            if (hours > 0) String.format("%d:%02d:%02d", hours, minutes, seconds)
            else String.format("%d:%02d", minutes, seconds)
        }
    }

    fun openAppIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun createToggleIntent(
        context: Context,
        receiverClass: Class<*>,
        appWidgetId: Int
    ): PendingIntent {
        val intent = Intent(context, receiverClass).apply {
            action = ACTION_SMART_WIDGET_TOGGLE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            appWidgetId + 7000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun isToggleAction(intent: Intent?): Boolean {
        return intent?.action == ACTION_SMART_WIDGET_TOGGLE
    }

    fun getDisplayMode(context: Context, key: String, fallback: String = "countdown"): String {
        val prefs = context.getSharedPreferences(SMART_WIDGET_PREFS, Context.MODE_PRIVATE)
        return prefs.getString(key, fallback) ?: fallback
    }

    fun toggleDisplayMode(context: Context, key: String): String {
        val prefs = context.getSharedPreferences(SMART_WIDGET_PREFS, Context.MODE_PRIVATE)
        val current = prefs.getString(key, "countdown") ?: "countdown"
        val next = if (current == "countdown") "time" else "countdown"
        prefs.edit().putString(key, next).apply()
        return next
    }

    fun applyAlpha(color: Int, alpha: Int): Int {
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    fun setTextSize(views: RemoteViews, viewId: Int, sizeSp: Float) {
        views.setTextViewTextSize(viewId, TypedValue.COMPLEX_UNIT_SP, sizeSp)
    }

    private fun parseColor(hex: String, fallback: Int): Int {
        return try {
            Color.parseColor(hex)
        } catch (_: Exception) {
            fallback
        }
    }
}
