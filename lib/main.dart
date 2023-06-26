import 'package:flutter/material.dart';

import 'screens/main.screen.dart';
import 'screens/settings.screen.dart';
import 'screens/wifi-info.screen.dart';

void main() => runApp(const WiFiShieldApp());

class WiFiShieldApp extends StatelessWidget {
  const WiFiShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WiFiShieldApp",
      home: MainPage(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 6, 40, 61),
      ),
      initialRoute: '/home',
      routes: {
        "/home": (context) => const MainPage(),
        "/wifi-info": (context) => const WifiInfo(),
        "/settings": (context) => const SettingsPage(),
      },
    );
  }
}
