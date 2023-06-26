import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';

import 'bottom_bar.dart';

class HomePageWithWiFi extends StatefulWidget {
  const HomePageWithWiFi({Key? key}) : super(key: key);

  @override
  _HomePageWithWiFiState createState() => _HomePageWithWiFiState();
}

class _HomePageWithWiFiState extends State<HomePageWithWiFi> {
  late Future<String?> _wifiName;
  late Future<String?> _wifiBSSID;
  late Future<String?> _wifiIP;

  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    final networkInfo = NetworkInfo();
    _wifiName = networkInfo.getWifiName();
    _wifiBSSID = networkInfo.getWifiBSSID();
    _wifiIP = networkInfo.getWifiIP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
          BottomNavbar(), // Replace `BottomNavbar()` with your actual bottom navigation bar widget
      body: FutureBuilder<void>(
        future: _getNetworkInfo(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(50, 100, 50, 50),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(223, 246, 255, 0.19),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected to ',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      FutureBuilder<String?>(
                        future: _wifiName,
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          } else {
                            final wifiName = snapshot.data;
                            return Text(
                              'SSID: ${wifiName ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: _wifiBSSID,
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          } else {
                            final wifiBSSID = snapshot.data;
                            return Text(
                              'BSSID: ${wifiBSSID ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: _wifiIP,
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          } else {
                            final wifiIP = snapshot.data;
                            return Text(
                              'IP Address: ${wifiIP ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.white,
                  thickness: 2,
                  indent: 45,
                  endIndent: 45,
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    // child: /* Add your content for the second row here */,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
