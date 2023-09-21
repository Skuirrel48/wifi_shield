package com.example.wifi_shield;

import io.flutter.embedding.android.FlutterActivity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.net.wifi.ScanResult;
import android.net.wifi.WifiManager;
import android.content.Context;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private Intent warningNotificationService;
    private Intent criticalNotificationService;
    private MethodChannel.Result sendWifiResult;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // Register plugins if needed.
        // GeneratedPluginRegistrant.registerWith(this);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // GeneratedPluginRegistrant.registerWith(this);
        warningNotificationService = new Intent(MainActivity.this, WarningNotificationService.class);
        criticalNotificationService = new Intent(MainActivity.this, CriticalNotificationService.class);
        System.out.println("I'm in MainActivity");

        new MethodChannel(getFlutterEngine().getDartExecutor(), "com.example.wifi_shield")
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        // if (methodCall.method.equals("startService")) {
                        //     startService();
                        //     result.success("Service Started");
                        // }
                        
                        if (methodCall.method.equals("scanWifi")) {
                            // startService();
                            List<Map<String, String>> wifiList = startScanningWifi();
                            result.success(wifiList);
                        } else if (methodCall.method.equals("attackNotification")) {
                            if ((int)methodCall.arguments() == 0) //Critical alert called
                                attackNotificationService(0);
                            else if ((int)methodCall.arguments() == 1) //warning alert called
                                attackNotificationService(1);
                            result.success(true);
                        } else if (methodCall.method.equals("stopNotification")) {
                            stopNotification();
                            result.success(true);
                        } else {    
                            result.notImplemented();
                        }
                    }
                });

    }

    public List<ScanResult> getNearbyWifiNetworks() {
        WifiManager wifiManager = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        List<ScanResult> scanResults = wifiManager.getScanResults();
        return scanResults;
    }

    public List<Map<String, String>> startScanningWifi() {
        List<ScanResult> wifiNetworks = getNearbyWifiNetworks();
        List<Map<String, String>> wifiList = new ArrayList<>();
        for (ScanResult scanResult : wifiNetworks) {
            Map<String, String> networkInfo = new HashMap<>();
            networkInfo.put("SSID", scanResult.SSID);
            networkInfo.put("BSSID", scanResult.BSSID);
            networkInfo.put("capabilities", scanResult.capabilities);
            networkInfo.put("level", Integer.toString(scanResult.level));
            networkInfo.put("frequency", Integer.toString(scanResult.frequency));
            networkInfo.put("standard", Integer.toString(scanResult.getWifiStandard()));
            wifiList.add(networkInfo);
        }
        // System.out.println(wifiNetworks);
        return wifiList;
       
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // stopService(forService);
        stopService(criticalNotificationService);
        stopService(warningNotificationService);
    }

    private void attackNotificationService(int level) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // startForegroundService(forService);
            if (level == 0) //critical
                startForegroundService(criticalNotificationService);
            else
                startForegroundService(warningNotificationService);

        } else {
            // startService(forService);
            if (level == 0) //critical
                startForegroundService(criticalNotificationService);
            else
                startForegroundService(warningNotificationService);
        }
    } 

    private void stopNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // startForegroundService(forService);
            stopService(criticalNotificationService);
            stopService(warningNotificationService);
        } else {
            // startService(forService);
            stopService(criticalNotificationService);
            stopService(warningNotificationService);
        }
    } 

}