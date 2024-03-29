import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'bottom_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void _refreshApp(BuildContext context) {
    Restart.restartApp();
  }

  @override
  Widget build(BuildContext context) {
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
                    image: AssetImage('images/wifi_not_connected.png'),
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
                SizedBox(height: 10),
                Container(
                  child: ElevatedButton(
                    child: Text('Refresh'),
                    onPressed: () => _refreshApp(context),
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
      // bottomNavigationBar: const BottomNavbar(),
    );
  }
}
