import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';

import 'bottom_bar.dart';

class WifiInfo extends StatefulWidget {
  const WifiInfo({Key? key}) : super(key: key);

  @override
  _WifiInfoState createState() => _WifiInfoState();
}

class _WifiInfoState extends State<WifiInfo> {
  late Future<String?> _wifiName;
  late Future<String?> _wifiBSSID;
  late Future<String?> _wifiIP;
  late Future<String?> _wifiSubmask;
  late Future<String?> _wifiGatewayIP;

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
    _wifiSubmask = networkInfo.getWifiSubmask();
    _wifiGatewayIP = networkInfo.getWifiGatewayIP();
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
                        'Wi-Fi Network Information',
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
                      SizedBox(height: 30),
                      FutureBuilder<String?>(
                        future: _wifiSubmask,
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
                            final wifiSubmask = snapshot.data;
                            return Text(
                              'Netmask: ${wifiSubmask ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: _wifiGatewayIP,
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
                            final wifiGatewayIP = snapshot.data;
                            return Text(
                              'Gateway: ${wifiGatewayIP ?? ''}',
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
              ],
            );
          }
        },
      ),
    );
  }
}
