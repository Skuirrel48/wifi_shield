import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'homePageNoWifi.screen.dart';
import 'homePageWithWifi.screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              return const HomePage();
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkWiFiConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }
}
