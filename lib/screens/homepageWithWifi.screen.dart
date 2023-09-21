import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Import dart:async for Timer
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart'; // Import the flutter_background_service package
import 'package:network_tools/network_tools.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysql_client/mysql_client.dart';
import 'homePageNoWifi.screen.dart';
import 'bottom_bar.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'WiFiShield', // id
    'WiFiShield App', // title
    description:
        'This channel is used for alerting notification', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'WiFiShield',
      initialNotificationTitle: 'WiFiShield App',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 111,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        //something to show on foreground
        print("In foreground...");
      } else {
        print("In background...");
      }
    }
  });
}

/**GLOBAL THINGSSSSS */
late Future<String?> _wifiName;
late Future<String?> _wifiBSSID;
late Future<String?> _wifiIP;
late Future<String?> _wifiSubmask;
late Future<String?> _wifiGatewayIP;
late String _networkAddress;
late MySQLConnection conn;

int totalUsableHosts = 0;
int connectedDevices = 0;
bool devicesFound = false;
bool evilTwin = false;
String previousSSID = "";
bool oneTime = false;

List<Map<String, String>> wifiNetworks = [];
List<Map<String, String>> duplicateWifis = [];
List<Map<String, String>> suspiciousWifis = [];

final StreamController<List<Map<String, String>>> _wifiNetworkStreamController =
    StreamController<List<Map<String, String>>>.broadcast();

Timer? _refreshTimer; // Timer for periodic refresh

Future<void> _checkAndScanWifiNetworks() async {
  PermissionStatus locationStatus = await Permission.location.request();
  PermissionStatus wifiStatus = await Permission.nearbyWifiDevices.request();

  if (locationStatus == PermissionStatus.granted &&
      wifiStatus == PermissionStatus.granted) {
    _scanWifiNetworks();
  } else {
    // Handle denied or restricted permission
  }
}

Future<void> _scanWifiNetworks() async {
  const platform = MethodChannel('com.example.wifi_shield');
  final List<dynamic> result = await platform.invokeMethod('scanWifi');
  final List<Map<String, String>> networks = List<Map<String, String>>.from(
    result.map((item) => Map<String, String>.from(item)),
  );
  // print("Current nearby nerworks: $networks");
  await hasDuplicateSSID(networks);

  // Add the new list of networks to the stream
  _wifiNetworkStreamController.add(networks);
}

Future<bool> hasDuplicateSSID(List<Map<String, String>> networks) async {
  final wifiName = await _wifiName;
  String wifiNameStr = wifiName.toString();
  wifiNameStr = wifiNameStr.replaceAll('"', '');
  final wifiBSSID = await _wifiBSSID;
  String wifiBSSIDStr = wifiBSSID.toString();
  wifiBSSIDStr = wifiBSSIDStr.replaceAll('"', '');
  evilTwin = false;
  print("Connected SSID: $wifiNameStr, BSSID: $wifiBSSIDStr");

  duplicateWifis = [];
  suspiciousWifis = [];
  for (final network in networks) {
    final ssid = network['SSID'];
    final bssid = network['BSSID'];
    if (wifiNameStr == ssid && wifiBSSIDStr != bssid) {
      //Checking Critical Evil Twin attack
      print('Duplicate SSID: $ssid (BSSID: $bssid)');
      duplicateWifis.add(network);
      evilTwin = true;
    } else {
      //Checking Warning Evil Twin attack
      print("Current BSSID: $bssid");
      if (await _checkBSSIDQuery(bssid.toString())) {
        const platform = MethodChannel('com.example.wifi_shield');
        final bool result = await platform.invokeMethod(
            'attackNotification', 1); //1 means warning alert
        suspiciousWifis.add(network);
        print("Suspicious wifi detected which is $suspiciousWifis");
      }
    }
  }
  if (evilTwin) {
    print(duplicateWifis);
    const platform = MethodChannel('com.example.wifi_shield');
    final bool result = await platform.invokeMethod(
        'attackNotification', 0); //0 means critical alert
    // evilTwin = false;
    await _insertAttackQuery(
        "Evil Twin",
        "An evil twin attack is a deceptive Wi-Fi network impersonation where hackers create a rogue network that looks legitimate, allowing them to intercept user data.",
        duplicateWifis);
    print("Evil Twin detected which is $duplicateWifis");
    return true;
  }
  return false;
}

Future<MySQLConnection> _initiateDBConn() async {
  final conn = await MySQLConnection.createConnection(
    host: "192.168.1.101",
    port: 3306,
    userName: "wifishieldeth",
    password: "wifishield",
    secure: false,
    databaseName: "wifishield", // optional
  );

// actually connect to database
  await conn.connect();
  return conn;
}

Future<String> _retrieveWifiInfoIDQuery() async {
  // final conn = await _initiateDBConn();
  if (!conn.connected) conn = await _initiateDBConn();
  final _ssid = await _wifiName;
  final bssid = await _wifiBSSID;
  String ssid = _ssid.toString().replaceAll('"', "");
  String wifi_info_id = "";
  if (_ssid != null && bssid != null) {
    var res = await conn.execute(
        "SELECT wifi_info_id from wifi_info WHERE ssid = :ssid AND bssid = :bssid",
        {"ssid": ssid, "bssid": bssid});

    for (final row in res.rows) {
      wifi_info_id = row.colAt(0).toString();
    }
  }
  return wifi_info_id;
}

Future<bool> _checkBSSIDQuery(String bssid) async {
  // final conn = await _initiateDBConn();
  if (!conn.connected) conn = await _initiateDBConn();

  final wifi_info_id = await _retrieveWifiInfoIDQuery();
  var res = await conn.execute("SELECT ssid, bssid FROM attacks");
  if (res.numOfRows > 0) {
    for (final row in res.rows) {
      if (row.colAt(1) == bssid) {
        previousSSID = row.colAt(0).toString();
        return true; //found same bssid from previous attacks
      }
    }
  }

  return false;
}

Future<bool> _insertAttackQuery(String attack_type, String attack_desc,
    List<Map<String, String>> wifiList) async {
  // final conn = await _initiateDBConn();
  if (!conn.connected) conn = await _initiateDBConn();

  var res;
  final wifi_info_id = await _retrieveWifiInfoIDQuery();
  res = await conn.execute(
      "SELECT ssid, bssid FROM attacks WHERE wifi_info_id = :wifi_info_id",
      {"wifi_info_id": wifi_info_id});
  if (res.numOfRows > 0) {
    for (final row in res.rows) {
      for (Map<String, String> wifi in wifiList) {
        if (row.colAt(0).toString() ==
                wifi["SSID"].toString().replaceAll('"', "") &&
            row.colAt(1).toString() == wifi["BSSID"]) {
          res = await conn.execute(
              "UPDATE attacks SET attack_type = :attack_type, attack_desc = :attack_desc, capabilities = :capabilities, level = :level, frequency = :frequency, standard = :standard, detection_time = current_timestamp() WHERE wifi_info_id = :wifi_info_id AND ssid = :ssid AND bssid = :bssid",
              {
                "wifi_info_id": wifi_info_id,
                "attack_type": attack_type,
                "attack_desc": attack_desc,
                "ssid": wifi['SSID'],
                "bssid": wifi['BSSID'],
                "capabilities": wifi['capabilities'],
                "level": wifi['level'],
                "frequency": wifi['frequency'],
                "standard": wifi['standard']
              });
          print("Updating attacks....");
        } else {
          res = await conn.execute(
              "INSERT INTO attacks (wifi_info_id, attack_type, attack_desc, ssid, bssid, capabilities, level, frequency, standard) VALUES (:wifi_info_id, :attack_type, :attack_desc, :ssid, :bssid, :capabilities, :level, :frequency, :standard)",
              {
                "wifi_info_id": wifi_info_id,
                "attack_type": attack_type,
                "attack_desc": attack_desc,
                "ssid": wifi['SSID'],
                "bssid": wifi['BSSID'],
                "capabilities": wifi['capabilities'],
                "level": wifi['level'],
                "frequency": wifi['frequency'],
                "standard": wifi['standard']
              });
          print("Inserting new attack....");
        }
      }
      if (res.affectedRows.toInt() > 0) {
        // conn.close();
        return true;
      }
    }
  } else {
    for (Map<String, String> wifi in wifiList) {
      res = await conn.execute(
          "INSERT INTO attacks (wifi_info_id, attack_type, attack_desc, ssid, bssid, capabilities, level, frequency, standard) VALUES (:wifi_info_id, :attack_type, :attack_desc, :ssid, :bssid, :capabilities, :level, :frequency, :standard)",
          {
            "wifi_info_id": wifi_info_id,
            "attack_type": attack_type,
            "attack_desc": attack_desc,
            "ssid": wifi['SSID'],
            "bssid": wifi['BSSID'],
            "capabilities": wifi['capabilities'],
            "level": wifi['level'],
            "frequency": wifi['frequency'],
            "standard": wifi['standard']
          });
    }
  }
  // conn.close();
  return false;
}

Future<bool> _insertWifiQuery() async {
  // final conn = await _initiateDBConn();
  if (!conn.connected) conn = await _initiateDBConn();

  //check if wifi is detected or not
  final wifiName = await _wifiName;
  final wifiBSSID = await _wifiBSSID;
  final wifiIP = await _wifiIP;
  String ssid = wifiName.toString();
  ssid = ssid.replaceAll('"', '');
  String bssid = wifiBSSID.toString();
  bssid = bssid.replaceAll('"', '');
  String ip_addr = wifiIP.toString();
  if (wifiName != null && wifiBSSID != null && wifiIP != null) {
    //check wifi exists in db
    var res = await conn.execute(
        "SELECT * FROM wifi_info WHERE ssid = :ssid AND bssid = :bssid",
        {"ssid": ssid, "bssid": bssid});

    if (res.numOfRows == 0) {
      res = await conn.execute(
          "INSERT INTO wifi_info (ssid, bssid, ip_addr_local, network_addr) VALUES (:ssid, :bssid, :ip_addr_local, :network_addr)",
          {
            "ssid": ssid,
            "bssid": bssid,
            "ip_addr_local": ip_addr,
            "network_addr": _networkAddress
          });
    }
    // conn.close();
    return true;
  }
  // conn.close();
  return false;
}

Future<bool> _insertDevicesQuery() async {
  // final conn = await _initiateDBConn();
  if (!conn.connected) conn = await _initiateDBConn();

  final wifi_info_id = await _retrieveWifiInfoIDQuery();
  var res = await conn.execute(
      "INSERT INTO devices (wifi_info_id, total_devices) VALUES (:wifi_info_id, :total_devices)",
      {"wifi_info_id": wifi_info_id, "total_devices": connectedDevices});
  if (res.affectedRows.toInt() > 0) {
    return true;
  }
  return false;
}

/** GLOBAL THINGSS */
class HomePageWithWiFi extends StatefulWidget {
  const HomePageWithWiFi({Key? key}) : super(key: key);

  @override
  _HomePageWithWiFiState createState() => _HomePageWithWiFiState();
}

class _HomePageWithWiFiState extends State<HomePageWithWiFi> {
  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
    _calculateTotalUsableHosts(_wifiSubmask);
    _calcNetworkAddr();
    // Start a timer to refresh network data every 3 seconds
    _refreshTimer = Timer.periodic(Duration(milliseconds: 1500), (_) {
      _scanWifiNetworks(); // Start listening to Wi-Fi networks
      updateUI();
    });
  }

  Future<void> _checkWifiConnection() async {
    final wifiName = await _wifiName;
    if (wifiName == null) {
      // Device is not connected to Wi-Fi, navigate to HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => HomePage(),
        ),
      );
    }
  }

  Future<void> _findDevices() async {
    setState(() {
      devicesFound = false; // Reset devicesFound before starting pingHosts
    });

    // Show a loading indicator immediately after the button is clicked
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding devices...'),
            ],
          ),
        );
      },
    );

    // Introduce a small delay before running pingHosts
    await Future.delayed(Duration(milliseconds: 800));

    await _executePing();

    // Close the sheet after pingHosts is done
    Navigator.of(context).pop();

    setState(() {
      devicesFound = true;
    });
  }

  Future<void> _executePing() async {
    await _calcNetworkAddr(); // Make sure _calcNetworkAddr() has completed
    await pingHosts(); // Execute pingHosts() after _calcNetworkAddr() is done
  }

  Future<void> _getNetworkInfo() async {
    final networkInfo = NetworkInfo();
    _wifiName = networkInfo.getWifiName();
    _wifiBSSID = networkInfo.getWifiBSSID();
    _wifiIP = networkInfo.getWifiIP();
    _wifiSubmask = networkInfo.getWifiSubmask();
    _wifiGatewayIP = networkInfo.getWifiGatewayIP();
    conn = await _initiateDBConn();
  }

  Future<void> _calcNetworkAddr() async {
    await _checkWifiConnection();
    String ipAddr = await _wifiIP ?? '';
    String subnetmask = await _wifiSubmask ?? '';
    List<int> ipAddressParts = ipAddr.split('.').map(int.parse).toList();
    List<int> subnetMaskParts = subnetmask.split('.').map(int.parse).toList();
    // Calculate the network address
    List<int> networkAddressParts = List.generate(
        4, (index) => ipAddressParts[index] & subnetMaskParts[index]);

    _networkAddress = networkAddressParts.join('.');
  }

  Future<void> _calculateTotalUsableHosts(
      Future<String?> subnetMaskFuture) async {
    await _checkWifiConnection();
    final subnetMask = await subnetMaskFuture;

    if (subnetMask != null) {
      // Count the number of zeros in the subnet mask to determine the bits available for hosts
      totalUsableHosts = 32 -
          subnetMask
              .split('.')
              .map((octet) => (int.parse(octet))
                  .toRadixString(2)
                  .replaceAll('0', '')
                  .length)
              .reduce((a, b) => a + b);
      totalUsableHosts = pow(2, totalUsableHosts).toInt() - 2;
    } else {
      // Handle the case where the subnetMask is null
      totalUsableHosts = 0;
    }
  }

  Future<void> pingHosts() async {
    await _calcNetworkAddr();
    print("ha " + _networkAddress);
    _networkAddress =
        _networkAddress.substring(0, _networkAddress.lastIndexOf('.'));
    final stream = HostScanner.getAllPingableDevices(_networkAddress);
    int deviceCounter = 0;

    await for (final host in stream) {
      // Same host can be emitted multiple times
      // Use Set<ActiveHost> instead of List<ActiveHost>
      print('Found device: $host');
      deviceCounter++;
    }

    setState(() {
      connectedDevices = deviceCounter;
    });

    print('Scan completed. Total device: $deviceCounter');

    //send to db
    _insertDevicesQuery();
  }

  Future<void> _refreshApp() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => HomePageWithWiFi(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // No animation
          },
        ),
      );
    }
  }

  void updateUI() {
    setState(() {
      suspiciousWifis;
      duplicateWifis;
    });
  }

  @override
  Widget build(BuildContext context) {
    // FlutterBackgroundService().startService();
    return Scaffold(
        bottomNavigationBar:
            BottomNavbar(), // Replace `BottomNavbar()` with your actual bottom navigation bar widget
        appBar: AppBar(
          title: const Text('WiFiShield'),
          backgroundColor: Color.fromARGB(255, 71, 181, 255),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshApp, // This function will be called on refresh
          child: FutureBuilder<String?>(
            future: _wifiName,
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // print("wifi is not scanned!!!");
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                return ListView(
                  children: <Widget>[
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
                                _insertWifiQuery();
                                final wifiName = snapshot.data;
                                return Text(
                                  'Connected to ${wifiName ?? ''}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Devices connected: ',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                devicesFound ? connectedDevices.toString() : '',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                // Use ElevatedButton if preferred
                                onPressed:
                                    _findDevices, // Disable after devices are found
                                child: Text('Find'),
                              ),
                            ],
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
                    SizedBox(height: 50),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 50),
                      // child: /* Add your content for the second row here */,
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (duplicateWifis.isNotEmpty &&
                              suspiciousWifis
                                  .isEmpty) // Check if there are duplicates
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(191, 228, 120, 120),
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
                                    'An Attack is Detected!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Possible attack: Evil Twin Attack',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Description: An evil twin attack is a deceptive Wi-Fi network impersonation where hackers create a rogue network that looks legitimate, allowing them to intercept user data.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text('Details of the possbile fake Wi-Fi:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      )),
                                  SizedBox(height: 10),
                                  for (final duplicateWifi in duplicateWifis)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '\t\tSSID: ${duplicateWifi['SSID']}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text(
                                            '\t\tBSSID: ${duplicateWifi['BSSID']}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Divider(), // Add a divider between duplicate networks
                                      ],
                                    ),
                                ],
                              ),
                            )
                          else if (suspiciousWifis.isNotEmpty &&
                              duplicateWifis
                                  .isEmpty) //only suspicious wifi detected
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(191, 227, 172, 90),
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
                                    'A Suspicious Wi-Fi detected!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Possible security threat: Evil Twin attack',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Description: This Wi-Fi may have acted as an 'Evil Twin,' imitating your network in the past and posing potential security risks.",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text('Details:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      )),
                                  SizedBox(height: 10),
                                  for (final suspiciousWifi in suspiciousWifis)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '\t\tCurrent information of the suspicious Wi-Fi',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text(
                                            '\t\t\tSSID: ${suspiciousWifi['SSID']}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text(
                                            '\t\t\tBSSID: ${suspiciousWifi['BSSID']}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Divider(), // Add a divider between duplicate networks
                                      ],
                                    ),
                                ],
                              ),
                            )
                          else if (duplicateWifis.isNotEmpty &&
                              suspiciousWifis.isNotEmpty)
                            ListView(children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(191, 228, 120, 120),
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
                                      'An Attack is Detected!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Possible attack: Evil Twin Attack',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Description: An evil twin attack is a deceptive Wi-Fi network impersonation where hackers create a rogue network that looks legitimate, allowing them to intercept user data.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text('Details of the possbile fake Wi-Fi:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        )),
                                    SizedBox(height: 10),
                                    for (final duplicateWifi in duplicateWifis)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '\t\tSSID: ${duplicateWifi['SSID']}',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(
                                              '\t\tBSSID: ${duplicateWifi['BSSID']}',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Divider(), // Add a divider between duplicate networks
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(191, 227, 172, 90),
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
                                      'A Suspicious Wi-Fi detected!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Possible security threat: Evil Twin attack',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Description: This Wi-Fi may have acted as an 'Evil Twin,' imitating your network in the past and posing potential security risks.",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text('Details:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        )),
                                    SizedBox(height: 10),
                                    for (final suspiciousWifi
                                        in suspiciousWifis)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '\t\tCurrent information of the suspicious Wi-Fi',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(
                                              '\t\t\tSSID: ${suspiciousWifi['SSID']}',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(
                                              '\t\t\tBSSID: ${suspiciousWifi['BSSID']}',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white)), // Add a divider between duplicate networks
                                        ],
                                      ),
                                  ],
                                ),
                              )
                            ])
                          else // Display the "Your Wi-Fi is safe" container
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  child: Image(
                                    image:
                                        AssetImage('images/wifi_connected.png'),
                                    width: 200,
                                  ),
                                  margin: EdgeInsets.only(bottom: 15),
                                ),
                                Container(
                                  child: Text(
                                    'Your Wi-Fi is safe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                    ),
                                  ),
                                  margin: EdgeInsets.only(bottom: 10),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ));
  }
}
