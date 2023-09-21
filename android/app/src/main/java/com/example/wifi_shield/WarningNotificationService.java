package com.example.wifi_shield;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiManager;
import android.content.Context;
import java.util.*;

public class WarningNotificationService extends Service {

    private static final int NOTIFICATION_ID = 103;

    private final Handler handler = new Handler(Looper.getMainLooper());

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, createNotification());
        System.out.println("I'm in WarningNotificationService");


        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private Notification createNotification() {
        return new NotificationCompat.Builder(this, "wifi_scanning_channel")
                .setContentTitle("WifiShield Warning Alert")
                .setContentText("A Suspicious Wi-Fi is detected!")
                .setSmallIcon(R.drawable.launch_background)
                .build();
    }
}
