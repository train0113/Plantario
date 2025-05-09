import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    _startScan();
  }

  void _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
        _scanResults.sort((a, b) {
          final nameA = a.device.name.isNotEmpty ? a.device.name : '~';
          final nameB = b.device.name.isNotEmpty ? b.device.name : '~';
          return nameA.compareTo(nameB);
        });
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        _isScanning = scanning;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE 기기 선택")),
      body: Column(
        children: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                final name = result.device.name.isNotEmpty ? result.device.name : "(이름 없음)";
                return ListTile(
                  title: Text(name),
                  subtitle: Text(result.device.id.id),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () {
                    Navigator.pop(context, result.device);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
