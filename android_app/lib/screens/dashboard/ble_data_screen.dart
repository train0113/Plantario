import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDataScreen extends StatefulWidget {
  final BluetoothDevice device;

  const BleDataScreen({Key? key, required this.device}) : super(key: key);

  @override
  _BleDataScreenState createState() => _BleDataScreenState();
}

class _BleDataScreenState extends State<BleDataScreen> {
  String receivedData = "수신 대기 중...";
  List<String> log = [];

  String _buffer = "";
  Timer? _receiveTimer;

  @override
  void initState() {
    super.initState();
    connectAndListen();
  }

  Future<void> connectAndListen() async {
    try {
      await widget.device.connect();
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              _buffer += utf8.decode(value);

              _receiveTimer?.cancel();
              _receiveTimer = Timer(Duration(milliseconds: 200), () {
                final complete = _buffer.trim();
                setState(() {
                  receivedData = complete;
                  log.insert(0, complete);
                });
                _buffer = "";
              });
            });
          }
        }
      }
    } catch (e) {
      print("연결 또는 수신 에러: $e");
      setState(() {
        receivedData = "연결 실패 또는 수신 실패";
      });
    }
  }

  @override
  void dispose() {
    _receiveTimer?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("BLE 데이터 보기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("실시간 수신 데이터:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(receivedData),
            ),
            SizedBox(height: 24),
            Text("로그:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: log.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(log[index]),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'name': widget.device.name,
                  'id': widget.device.id.toString(),
                });
              },
              icon: Icon(Icons.check),
              label: Text("기기 선택 완료"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            )
          ],
        ),
      ),
    );
  }
}
