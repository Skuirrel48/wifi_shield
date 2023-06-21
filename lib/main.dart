import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'bottom_bar.dart';

void main() => runApp(const WiFiShieldApp());

class WiFiShieldApp extends StatelessWidget {
  const WiFiShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WiFiShieldApp",
      home: const HomePage(),
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
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Image(
                    image: AssetImage(
                      'images/wifi_not_connected.png',
                    ),
                    width: 200,
                  ),
                  margin: EdgeInsets.only(bottom: 15),
                ),
                Container(
                  child: Text(
                    'Please connect to a network',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: 10),
                ),
                Container(
                  child: ElevatedButton(
                    child: Text('Open Wi-Fi Settings'),
                    onPressed: () {
                      AppSettings.openWIFISettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 71, 181, 255),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavbar(),
    );
  }
}
