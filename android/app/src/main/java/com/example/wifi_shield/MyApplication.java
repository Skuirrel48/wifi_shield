package com.example.wifi_shield;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;

import io.flutter.app.FlutterApplication;

public class MyApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel("messages", "Messages",
                    NotificationManager.IMPORTANCE_HIGH);
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);

            NotificationChannel wifiScanChannel = new NotificationChannel("wifi_scanning_channel", "WifiShield",
                NotificationManager.IMPORTANCE_HIGH);
            NotificationManager wifiScanManager = getSystemService(NotificationManager.class);
            wifiScanManager.createNotificationChannel(wifiScanChannel);
    

            System.out.println("MyApplication.java being executed...");
        } else {
            System.out.println("MyApplication.java being executed (but false)...");
        }

    }

}
