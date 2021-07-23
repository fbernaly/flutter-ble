import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DevicePage extends StatefulWidget {
  DevicePage({Key key, this.device}) : super(key: key);

  final BluetoothDevice device;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final _writeController = TextEditingController();
  final _mtuController = TextEditingController();
  List<BluetoothService> _services = <BluetoothService>[];
  List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  int _mtu = 0;

  @override
  void initState() {
    super.initState();

    _subscribe();
    _discoverServices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.device.name),
        ),
        body: _buildBody(),
      );

  @override
  void dispose() {
    super.dispose();
    widget.device.disconnect();
    _subscriptions.forEach((element) {
      element.cancel();
    });
  }

  Widget _buildBody() {
    bool showSpinner = _services.length == 0;
    return Stack(
      children: <Widget>[
        if (showSpinner) Center(child: CircularProgressIndicator()),
        _buildDeviceView(),
      ],
    );
  }

  Widget _buildDeviceView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Platform.isIOS
              ? "UUID: "
              : (Platform.isAndroid ? "Address: " : "ID: ")),
          SizedBox(height: 4),
          Text(
            widget.device.id.toString().toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text("MTU: "),
              Text(
                _mtu.toString(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              if (Platform.isAndroid)
                _buildButton("REQUEST MTU", () async {
                  _requestMtu();
                })
            ],
          ),
          Divider(),
        ]),
        _buildListViewOfServices(),
      ],
    );
  }

  Widget _buildListViewOfServices() {
    return ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
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
              Text('Value: ' + readValues[characteristic.uuid].toString()),
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
    List<ButtonTheme> buttons = <ButtonTheme>[];
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
        child: ElevatedButton(
          child: Text(title, style: TextStyle(color: Colors.white)),
          onPressed: onPressed,
        ),
      ),
    );
  }

  void _subscribe() {
    StreamSubscription<BluetoothState> stateSubscription =
        widget.flutterBlue.state.listen((event) {
      if (event != BluetoothState.on) Navigator.pop(context);
    });
    _subscriptions.add(stateSubscription);

    StreamSubscription<BluetoothDeviceState> deviceStateSubscription =
        widget.device.state.listen((event) {
      if (event == BluetoothDeviceState.disconnected) Navigator.pop(context);
    });
    _subscriptions.add(deviceStateSubscription);

    StreamSubscription<int> mtuSubscription = widget.device.mtu.listen((mtu) {
      setState(() {
        _mtu = mtu;
      });
    });
    _subscriptions.add(mtuSubscription);
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
        readValues[characteristic.uuid] = value;
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
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter(RegExp('[0-9A-Fa-f]'),
                          allow: true)
                    ],
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Send"),
                onPressed: () {
                  final values = _getByteArray(_writeController.value.text);
                  print("Write data: " + values.toString());
                  characteristic.write(values);
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _requestMtu() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Request Mtu"),
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _mtuController,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Request"),
                onPressed: () {
                  Navigator.pop(context);
                  int mtu = int.parse(_mtuController.value.text);
                  widget.device.requestMtu(mtu);
                },
              ),
              TextButton(
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
      readValues[characteristic.uuid] = value;
    });
    await characteristic.setNotifyValue(true);
  }

  List<int> _getByteArray(String hexString) {
    List<int> values = <int>[];
    String fullString = hexString;
    if (fullString.length % 2 == 1) fullString = '0' + fullString;
    for (int i = 0; i < fullString.length; i += 2) {
      final hex = fullString.substring(i, i + 2);
      final number = int.parse(hex, radix: 16);
      values.add(number);
    }
    return values;
  }
}
