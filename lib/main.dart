import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';

import 'screens/settings.screen.dart';
import 'screens/homepage.screens.dart';

void main() => runApp(const WiFiShieldApp());

class WiFiShieldApp extends StatelessWidget {
  const WiFiShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WiFiShieldApp",
      home: Scaffold(
        body: FutureBuilder<bool>(
          future: _checkWiFiConnection(),
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
              final bool isConnectedToWiFi = snapshot.data ?? false;
              if (isConnectedToWiFi) {
                return const HomePageWithWiFi();
              } else {
                return const HomePageWithoutWiFi();
              }
            }
          },
        ),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 6, 40, 61),
      ),
      initialRoute: '/home',
      routes: {
        "/home": (context) => const HomePage(),
        "/settings": (context) => const SettingsPage(),
      },
    );
  }

  Future<bool> _checkWiFiConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.wifi;
  }
}

class HomePageWithWiFi extends StatelessWidget {
  const HomePageWithWiFi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WiFi Brief Information',
            style: TextStyle(fontSize: 24),
          ),
          // Add your custom WiFi content here
        ],
      ),
    );
  }
}

class HomePageWithoutWiFi extends StatelessWidget {
  const HomePageWithoutWiFi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You are not connected to a WiFi network.',
            style: TextStyle(fontSize: 24),
          ),
          ElevatedButton(
            onPressed: () {
              AppSettings.openWIFISettings();
            },
            child: Text('Open WiFi Settings'),
          ),
        ],
      ),
    );
  }
}
