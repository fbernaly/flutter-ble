import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

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

  @override
  void initState() {
    super.initState();
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
    widget.flutterBlue.startScan();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildBody(),
      );

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        if (_showSpinner || widget.devicesList.length ==  0)
          Center(child: CircularProgressIndicator()),
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
      onRefresh: _reScan,
    );
  }

  Future<void> _reScan() async {
    setState(() {
      _showSpinner = false;
      widget.devicesList.clear();
      widget.flutterBlue.stopScan();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        widget.flutterBlue.startScan();
      });
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    widget.flutterBlue.stopScan();
    setState(() {
      _showSpinner = true;
    });
    try {
      await device.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        throw e;
      }
      _reScan();
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
