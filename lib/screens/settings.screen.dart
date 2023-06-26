
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'bottom_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        shadowColor: Color.fromARGB(0, 0, 0, 0),
        toolbarHeight: 100,
      ),
      body: Row(
        children: [
          Container(
            width: 10,
            child: Text(''),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  child: Text(
                    'App settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: 50),
                ),
                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Color.fromARGB(255, 2, 13, 20),
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: Color.fromARGB(255, 2, 13, 20),
                      width: 2,
                    ),
                  ),
                  columnWidths: const <int, TableColumnWidth>{
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(300),
                    2: FixedColumnWidth(60),
                  },
                  children: <TableRow>[
                    TableRow(
                      children: [
                        Container(
                          child: FaIcon(
                            FontAwesomeIcons.info,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: Text(
                            'About us & this app',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: FaIcon(
                            FontAwesomeIcons.greaterThan,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Container(
                          child: FaIcon(
                            FontAwesomeIcons.bell,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: Text(
                            'Alerts & Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: SwitchNotif(),
                          padding: EdgeInsets.only(top: 15),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Container(
                          child: FaIcon(
                            FontAwesomeIcons.envelope,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: Text(
                            'Send us Feedback',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                        Container(
                          child: FaIcon(
                            FontAwesomeIcons.greaterThan,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(30),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            child: Text(''),
            width: 10,
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavbar(),
    );
  }
}

class SwitchNotif extends StatefulWidget {
  const SwitchNotif({super.key});

  @override
  State<SwitchNotif> createState() => _SwitchNotifState();
}

class _SwitchNotifState extends State<SwitchNotif> {
  bool light = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      // This bool value toggles the switch.
      value: light,
      activeColor: Color.fromARGB(255, 71, 181, 255),
      onChanged: (bool value) {
        // This is called when the user toggles the switch.
        setState(() {
          light = value;
        });
      },
    );
  }
}
