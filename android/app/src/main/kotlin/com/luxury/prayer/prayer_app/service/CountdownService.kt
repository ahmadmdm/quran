package com.luxury.prayer.prayer_app.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.CountDownTimer
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.luxury.prayer.prayer_app.MainActivity
import com.luxury.prayer.prayer_app.R
import java.util.concurrent.TimeUnit

class CountdownService : Service() {

    private var timer: CountDownTimer? = null
    private val CHANNEL_ID = "silent_channel_v2"
    private val NOTIFICATION_ID = 999

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "إشعارات صامتة",
                NotificationManager.IMPORTANCE_LOW
            )
            serviceChannel.description = "تحديثات العد التنازلي"
            serviceChannel.setSound(null, null)
            serviceChannel.enableVibration(false)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prayerName = intent?.getStringExtra("prayer_name") ?: "Prayer"
        val targetTime = intent?.getLongExtra("target_time", 0L) ?: 0L

        if (targetTime > System.currentTimeMillis()) {
            startForeground(NOTIFICATION_ID, createNotification(prayerName, "Calculating..."))
            startTimer(prayerName, targetTime)
        } else {
            stopSelf()
        }

        return START_NOT_STICKY
    }

    private fun startTimer(prayerName: String, targetTime: Long) {
        timer?.cancel()
        
        val duration = targetTime - System.currentTimeMillis()
        
        timer = object : CountDownTimer(duration, 60000) { // Update every minute
            override fun onTick(millisUntilFinished: Long) {
                val hours = TimeUnit.MILLISECONDS.toHours(millisUntilFinished)
                val minutes = TimeUnit.MILLISECONDS.toMinutes(millisUntilFinished) % 60
                
                val timeString = String.format("%02d:%02d", hours, minutes)
                updateNotification(prayerName, "Next prayer in $timeString")
            }

            override fun onFinish() {
                stopSelf()
            }
        }.start()
    }

    private fun createNotification(title: String, content: String): android.app.Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Next: $title")
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher) // Ensure this icon exists or use a valid one
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(title: String, content: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, createNotification(title, content))
    }

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }
}
