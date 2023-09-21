import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'homePageNoWifi.screen.dart';
import 'homePageWithWifi.screen.dart';
import 'package:permission_handler/permission_handler.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _checkAndRequestPermissions(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final bool permissionsGranted = snapshot.data ?? false;

            if (permissionsGranted) {
              return FutureBuilder<String?>(
                future: _checkWiFiConnection(),
                builder: (BuildContext context,
                    AsyncSnapshot<String?> wifiSnapshot) {
                  if (wifiSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (wifiSnapshot.hasError) {
                    return Center(
                      child: Text('Error: ${wifiSnapshot.error}'),
                    );
                  } else {
                    final String? wifiName = wifiSnapshot.data;

                    if (wifiName != null) {
                      return const HomePageWithWiFi();
                    } else {
                      return const HomePage();
                    }
                  }
                },
              );
            } else {
              return const PermissionDeniedPage();
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    final permissions = await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    // Check if both permissions are granted
    if (permissions[Permission.location] == PermissionStatus.granted &&
        permissions[Permission.nearbyWifiDevices] == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }

  Future<String?> _checkWiFiConnection() async {
    final networkInfo = NetworkInfo();
    return networkInfo.getWifiName();
  }
}

class PermissionDeniedPage extends StatelessWidget {
  const PermissionDeniedPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Permission Denied',
              style: TextStyle(fontSize: 24),
            ),
            ElevatedButton(
              onPressed: () {
                _openAppSettings();
              },
              child: Text('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
