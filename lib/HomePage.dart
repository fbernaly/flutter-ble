import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:focus_detector/focus_detector.dart';

import 'DevicePage.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSpinner = false;
  bool _isScanning = false;
  bool _onFocus = false;
  BluetoothState _bluetoothState;

  // Vital for identifying our FocusDetector when a rebuild occurs.
  final Key _focusDetectorKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FocusDetector(
        key: _focusDetectorKey,
        onFocusGained: _onFocusGained,
        onFocusLost: _onFocusLost,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: <Widget>[
              FlatButton(
                textColor: Colors.white,
                onPressed: () {
                  _startScanning();
                },
                child: Text("Scan"),
                shape:
                    CircleBorder(side: BorderSide(color: Colors.transparent)),
              ),
            ],
          ),
          body: _buildBody(),
        ),
      );

  Widget _buildBody() {
    String text = "";
    switch (_bluetoothState) {
      case BluetoothState.unknown:
        text = "Bluetooth state is unknown";
        break;

      case BluetoothState.unavailable:
        text = "Bluetooth state is unavailable";
        break;

      case BluetoothState.unauthorized:
        text =
            "Bluetooth state is unauthorized.\nGo to Settings and allow bluetooth access to the app.";
        break;

      case BluetoothState.turningOn:
        text = "Bluetooth state is turningOn";
        break;

      case BluetoothState.turningOff:
        text = "Bluetooth state is turningOff";
        break;

      case BluetoothState.off:
        text = "Bluetooth state is off.\nTurn on bluetooth in your phone.";
        break;

      default:
        break;
    }

    if (_bluetoothState != BluetoothState.on) {
      return Center(
          child: Text(
        text,
        textAlign: TextAlign.center,
      ));
    }

    return Stack(
      children: <Widget>[
        if (_showSpinner) Center(child: CircularProgressIndicator()),
        _buildListViewOfDevices()
      ],
    );
  }

  Widget _buildListViewOfDevices() {
    final List<BluetoothDevice> devices = widget.devicesList;
    return RefreshIndicator(
      child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (BuildContext context, int index) {
            BluetoothDevice device = devices[index];
            return Container(
                child: Column(
              children: [
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            device.name == ''
                                ? '(unknown device)'
                                : device.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(device.id.toString()),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    FlatButton(
                      color: Colors.blue,
                      child: Text(
                        'Connect',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        _connect(device);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ));
          }),
      onRefresh: _startScanning,
    );
  }

  void _onFocusGained() {
    print('Home gained focus');
    _onFocus = true;
    _subscribe();
    _startScanning();
  }

  void _onFocusLost() {
    print('Home lost focus');
    _onFocus = false;
    _stopScanning();
  }

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
        _showSpinner = false;
      });
    }
  }

  void _subscribe() {
    widget.flutterBlue.state.listen((state) {
      setState(() {
        print("Bluetooth state: " + state.toString());
        _bluetoothState = state;
        if (state == BluetoothState.on) {
          _startScanning();
        }
      });
    });
    widget.flutterBlue.isScanning.listen((value) {
      if (_isScanning == value) return;
      _isScanning = value;
      print("Bluetooth is scanning: " + value.toString());
    });
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
  }

  Future<void> _startScanning() async {
    if (_bluetoothState != BluetoothState.on) return;
    setState(() {
      _showSpinner = true;
      widget.devicesList.clear();
      _stopScanning();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        if (_isScanning || !_onFocus) return;
        _isScanning = true;
        print("Start scanning...");
        widget.flutterBlue.startScan();
      });
    });
  }

  void _stopScanning() {
    if (_isScanning) {
      print("Stop scanning...");
      widget.flutterBlue.stopScan();
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_bluetoothState != BluetoothState.on) return;
    _stopScanning();
    setState(() {
      _showSpinner = true;
    });
    try {
      await device.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        throw e;
      }
      _startScanning();
    } finally {
      setState(() {
        _showSpinner = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DevicePage(device: device),
        ),
      );
    }
  }
}
