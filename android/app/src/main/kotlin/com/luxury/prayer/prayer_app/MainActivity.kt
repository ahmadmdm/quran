package com.luxury.prayer.prayer_app

import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.luxury.prayer.prayer_app.service.CountdownService
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.luxury.prayer/countdown"
    private val migrationPrefsName = "prayer_app_migrations"
    private val flnScheduledPrefsName = "scheduled_notifications"
    private val flnScheduledKey = "scheduled_notifications"
    private val clearCorruptFlnCacheFlag = "clear_corrupt_fln_cache_v1_done"
    private val candidatePrefs = listOf(
        "scheduled_notifications",
        "FlutterSharedPreferences",
        "com.dexterous.flutterlocalnotifications"
    )
    private val candidateKeys = listOf(
        "scheduled_notifications",
        "flutter.scheduled_notifications",
        "com.dexterous.flutterlocalnotifications.scheduled_notifications"
    )

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        clearCorruptedFlutterLocalNotificationsCacheIfNeeded()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startCountdown") {
                val prayerName = call.argument<String>("prayer_name")
                val targetTime = call.argument<Long>("target_time")

                val serviceIntent = Intent(this, CountdownService::class.java)
                serviceIntent.putExtra("prayer_name", prayerName)
                serviceIntent.putExtra("target_time", targetTime)
                
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                result.success(null)
            } else if (call.method == "stopCountdown") {
                val serviceIntent = Intent(this, CountdownService::class.java)
                stopService(serviceIntent)
                result.success(null)
            } else if (call.method == "clearNotificationCache") {
                clearAllKnownFlnCacheKeys()
                Log.w("MainActivity", "Notification cache cleared by method channel")
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Some devices can persist incompatible data for flutter_local_notifications.
     * The plugin then throws "Missing type parameter." while reading scheduled notifications.
     * Clear that cache once so scheduling can recover.
     */
    private fun clearCorruptedFlutterLocalNotificationsCacheIfNeeded() {
        val migrationPrefs = getSharedPreferences(migrationPrefsName, MODE_PRIVATE)
        if (migrationPrefs.getBoolean(clearCorruptFlnCacheFlag, false)) return

        clearAllKnownFlnCacheKeys()
        Log.w("MainActivity", "Cleared incompatible flutter_local_notifications cache")

        migrationPrefs.edit().putBoolean(clearCorruptFlnCacheFlag, true).apply()
    }

    private fun clearAllKnownFlnCacheKeys() {
        // Legacy exact location used by old app versions.
        val legacyPrefs = getSharedPreferences(flnScheduledPrefsName, MODE_PRIVATE)
        legacyPrefs.edit().remove(flnScheduledKey).apply()

        // Known plugin/default shared prefs candidates across plugin/Android versions.
        for (prefsName in candidatePrefs) {
            val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
            removeCandidateKeys(prefs)
        }

        // Default shared preferences can also hold the serialized schedule list.
        val defaultPrefs = getSharedPreferences("${packageName}_preferences", MODE_PRIVATE)
        removeCandidateKeys(defaultPrefs)

        // Aggressive pass: scan all app shared prefs and remove keys related
        // to notifications/schedules. Some OEM/plugin versions use different keys.
        scrubNotificationKeysFromAllSharedPrefs()
    }

    private fun removeCandidateKeys(prefs: SharedPreferences) {
        val editor = prefs.edit()
        for (key in candidateKeys) {
            if (prefs.contains(key)) {
                editor.remove(key)
            }
        }
        editor.apply()
    }

    private fun scrubNotificationKeysFromAllSharedPrefs() {
        val sharedPrefsDir = File(applicationInfo.dataDir, "shared_prefs")
        val files = sharedPrefsDir.listFiles() ?: return

        val keyNeedles = listOf("notification", "notifications", "schedule", "dexterous", "flutter_local")

        for (file in files) {
            if (!file.name.endsWith(".xml")) continue
            val prefsName = file.name.removeSuffix(".xml")
            try {
                val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
                val all = prefs.all
                if (all.isEmpty()) continue

                val editor = prefs.edit()
                var touched = false

                for ((key, _) in all) {
                    val lower = key.lowercase()
                    if (keyNeedles.any { lower.contains(it) }) {
                        editor.remove(key)
                        touched = true
                    }
                }

                val prefsNameLower = prefsName.lowercase()
                if (prefsNameLower.contains("notification") || prefsNameLower.contains("dexterous")) {
                    editor.clear()
                    touched = true
                }

                if (touched) {
                    editor.apply()
                    Log.w("MainActivity", "Scrubbed notification-related keys in prefs: $prefsName")
                }
            } catch (e: Exception) {
                Log.w("MainActivity", "Failed scrubbing prefs ${file.name}: ${e.message}")
            }
        }
    }
}

