import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Import dart:async for Timer
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'screens/homePageNoWifi.screen.dart';
import 'screens/homepageWithWifi.screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(WiFiShieldApp());
}

class WiFiShieldApp extends StatelessWidget {
  WiFiShieldApp({Key? key}) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 6, 40, 61),
      ),
      home: AppInitializationPage(),
    );
  }
}

class AppInitializationPage extends StatefulWidget {
  const AppInitializationPage({Key? key}) : super(key: key);

  @override
  _AppInitializationPageState createState() => _AppInitializationPageState();
}

class _AppInitializationPageState extends State<AppInitializationPage> {
  bool _permissionsGranted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Text(
              'WiFiShield',
              style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(fontSize: 20), // Adjust the font size
                padding: EdgeInsets.all(16), // Adjust the button padding
              ),
              onPressed: () async {
                final permissionsGranted = await _checkAndRequestPermissions();
                setState(() {
                  _permissionsGranted = permissionsGranted;
                });
                if (permissionsGranted) {
                  _navigateToHomePage();
                }
              },
              child: Text("Let's start"),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    final permissions = await [
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
      Permission.notification,
    ].request();

    final locationAlwaysPermission = await Permission.locationAlways.request();
    print(permissions);
    // Check if both permissions are granted
    if (permissions[Permission.locationWhenInUse] == PermissionStatus.granted &&
        locationAlwaysPermission == PermissionStatus.granted &&
        permissions[Permission.nearbyWifiDevices] == PermissionStatus.granted &&
        permissions[Permission.notification] == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }

  void _navigateToHomePage() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) {
        return FutureBuilder<String?>(
          future: _checkWiFiConnection(),
          builder: (BuildContext context, AsyncSnapshot<String?> wifiSnapshot) {
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
      },
    ));
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
                _openAppSettings(context);
              },
              child: Text('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppSettings(BuildContext context) async {
    await openAppSettings();
  }
}
