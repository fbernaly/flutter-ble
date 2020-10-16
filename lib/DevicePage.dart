import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DevicePage extends StatefulWidget {
  DevicePage({Key key, this.device}) : super(key: key);

  final BluetoothDevice device;
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final _writeController = TextEditingController();
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.device.name),
    ),
    body: Center(child: CircularProgressIndicator()),
  );


  // List<ButtonTheme> _buildReadWriteNotifyButton(
  //     BluetoothCharacteristic characteristic) {
  //   List<ButtonTheme> buttons = new List<ButtonTheme>();
  //
  //   if (characteristic.properties.read) {
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: RaisedButton(
  //             color: Colors.blue,
  //             child: Text('READ', style: TextStyle(color: Colors.white)),
  //             onPressed: () async {
  //               var sub = characteristic.value.listen((value) {
  //                 setState(() {
  //                   widget.readValues[characteristic.uuid] = value;
  //                 });
  //               });
  //               await characteristic.read();
  //               sub.cancel();
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //   if (characteristic.properties.write) {
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: RaisedButton(
  //             child: Text('WRITE', style: TextStyle(color: Colors.white)),
  //             onPressed: () async {
  //               await showDialog(
  //                   context: context,
  //                   builder: (BuildContext context) {
  //                     return AlertDialog(
  //                       title: Text("Write"),
  //                       content: Row(
  //                         children: <Widget>[
  //                           Expanded(
  //                             child: TextField(
  //                               controller: _writeController,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       actions: <Widget>[
  //                         FlatButton(
  //                           child: Text("Send"),
  //                           onPressed: () {
  //                             characteristic.write(
  //                                 utf8.encode(_writeController.value.text));
  //                             Navigator.pop(context);
  //                           },
  //                         ),
  //                         FlatButton(
  //                           child: Text("Cancel"),
  //                           onPressed: () {
  //                             Navigator.pop(context);
  //                           },
  //                         ),
  //                       ],
  //                     );
  //                   });
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //   if (characteristic.properties.notify) {
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: RaisedButton(
  //             child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
  //             onPressed: () async {
  //               characteristic.value.listen((value) {
  //                 widget.readValues[characteristic.uuid] = value;
  //               });
  //               await characteristic.setNotifyValue(true);
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return buttons;
  // }
  //
  // ListView _buildConnectDeviceView() {
  //   List<Container> containers = new List<Container>();
  //
  //   for (BluetoothService service in _services) {
  //     List<Widget> characteristicsWidget = new List<Widget>();
  //
  //     for (BluetoothCharacteristic characteristic in service.characteristics) {
  //       characteristicsWidget.add(
  //         Align(
  //           alignment: Alignment.centerLeft,
  //           child: Column(
  //             children: <Widget>[
  //               Row(
  //                 children: <Widget>[
  //                   Text(characteristic.uuid.toString(),
  //                       style: TextStyle(fontWeight: FontWeight.bold)),
  //                 ],
  //               ),
  //               Row(
  //                 children: <Widget>[
  //                   ..._buildReadWriteNotifyButton(characteristic),
  //                 ],
  //               ),
  //               Row(
  //                 children: <Widget>[
  //                   Text('Value: ' +
  //                       widget.readValues[characteristic.uuid].toString()),
  //                 ],
  //               ),
  //               Divider(),
  //             ],
  //           ),
  //         ),
  //       );
  //     }
  //     containers.add(
  //       Container(
  //         child: ExpansionTile(
  //             title: Text(service.uuid.toString()),
  //             children: characteristicsWidget),
  //       ),
  //     );
  //   }
  //
  //   return ListView(
  //     padding: const EdgeInsets.all(8),
  //     children: <Widget>[
  //       ...containers,
  //     ],
  //   );
  // }

}
