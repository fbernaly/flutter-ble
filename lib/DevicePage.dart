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
  List<BluetoothService> _services = new List<BluetoothService>();

  @override
  void initState() {
    super.initState();

    _discoverServices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.device.name),
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    bool showSpinner = _services.length == 0;
    return Stack(
      children: <Widget>[
        if (showSpinner) Center(child: CircularProgressIndicator()),
        _buildListViewOfServices(),
      ],
    );
  }

  Widget _buildListViewOfServices() {
    return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (BuildContext context, int index) {
          BluetoothService service = _services[index];
          return Container(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Service: "),
              SizedBox(height: 4),
              Text(
                service.uuid.toString().toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildListViewOfCharacteristics(service),
            ],
          ));
        });
  }

  Widget _buildListViewOfCharacteristics(BluetoothService service) {
    List<BluetoothCharacteristic> characteristics = service.characteristics;
    return ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.all(8),
        itemCount: characteristics.length,
        itemBuilder: (BuildContext context, int index) {
          BluetoothCharacteristic characteristic = characteristics[index];
          return Container(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Characteristic: "),
              SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  characteristic.uuid.toString().toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 4),
              Text('Value: ' +
                  widget.readValues[characteristic.uuid].toString()),
              SizedBox(height: 4),
              Row(
                children: <Widget>[
                  ..._buildReadWriteNotifyButton(characteristic),
                ],
              ),
              Divider(),
            ],
          ));
        });
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();
    if (characteristic.properties.read) {
      buttons.add(_buildButton("READ", () async {
        _readCharacteristic(characteristic);
      }));
    }
    if (characteristic.properties.write) {
      buttons.add(_buildButton("WRITE", () async {
        _writeCharacteristic(characteristic);
      }));
    }
    if (characteristic.properties.notify) {
      buttons.add(_buildButton("NOTIFY", () async {
        _notifyCharacteristic(characteristic);
      }));
    }
    return buttons;
  }

  ButtonTheme _buildButton(String title, VoidCallback onPressed) {
    return ButtonTheme(
      minWidth: 10,
      height: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: RaisedButton(
          child: Text(title, style: TextStyle(color: Colors.white)),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Future<void> _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    setState(() {
      _services = services;
    });
  }

  Future<void> _readCharacteristic(
      BluetoothCharacteristic characteristic) async {
    var sub = characteristic.value.listen((value) {
      setState(() {
        widget.readValues[characteristic.uuid] = value;
      });
    });
    await characteristic.read();
    sub.cancel();
  }

  Future<void> _writeCharacteristic(
      BluetoothCharacteristic characteristic) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Write"),
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _writeController,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Send"),
                onPressed: () {
                  characteristic
                      .write(utf8.encode(_writeController.value.text));
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _notifyCharacteristic(
      BluetoothCharacteristic characteristic) async {
    characteristic.value.listen((value) {
      widget.readValues[characteristic.uuid] = value;
    });
    await characteristic.setNotifyValue(true);
  }
}
