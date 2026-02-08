package com.luxury.prayer.prayer_app

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.luxury.prayer.prayer_app.service.CountdownService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.luxury.prayer/countdown"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
            } else {
                result.notImplemented()
            }
        }
    }
}

