import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:khuthon/config/palette.dart';
import 'package:khuthon/screens/dashboard/plant_edit_screen.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  String userName = "사용자";
  List<String> log = [];
  String _buffer = "";
  Timer? _receiveTimer;
  BluetoothConnectionState _deviceState = BluetoothConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _connectedDevice;

  int? light;
  int? water;
  double? temp;
  double? humi;

  @override
  void initState() {
    super.initState();
    _loadFavoriteDeviceData();
  }

  Future<void> _loadFavoriteDeviceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantData')
        .where('isFavorite', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data();
    final deviceId = data['bleDeviceId'];

    if (deviceId != null) {
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
        final completer = Completer<BluetoothDevice>();

        final subscription = FlutterBluePlus.scanResults.listen((results) {
          for (var result in results) {
            if (result.device.id.id == deviceId) {
              FlutterBluePlus.stopScan();
              completer.complete(result.device);
              break;
            }
          }
        });

        final device = await completer.future;
        _connectedDevice = device;
        await device.connect(autoConnect: false);

        _connectionSubscription = device.state.listen((state) async {
          setState(() {
            _deviceState = state;
          });
        });

        final services = await device.discoverServices();
        for (var service in services) {
          for (var char in service.characteristics) {
            if (char.properties.notify) {
              await char.setNotifyValue(true);
              char.value.listen((value) {
                _buffer += utf8.decode(value);
                _receiveTimer?.cancel();
                _receiveTimer = Timer(const Duration(milliseconds: 200), () {
                  final complete = _buffer.trim();
                  setState(() {
                    log.insert(0, complete);
                    _parseBleData(complete);
                  });
                  _buffer = "";
                });
              });
            }
          }
        }

        subscription.cancel();
      } catch (e) {
        print("BLE 연결 오류: $e");
      }
    }
  }

  void _parseBleData(String data) {
    final regex = RegExp(r'(Light|Water|Temp|Humi):\s*([\d.]+)%?');
    for (final match in regex.allMatches(data)) {
      final key = match.group(1);
      final value = match.group(2);
      switch (key) {
        case 'Light':
          light = int.tryParse(value!);
          break;
        case 'Water':
          water = int.tryParse(value!);
          break;
        case 'Temp':
          temp = double.tryParse(value!);
          break;
        case 'Humi':
          humi = double.tryParse(value!);
          break;
      }
    }
  }

  @override
  void dispose() {
    _receiveTimer?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  String interpretLight(int value) {
    if (value < 0 || value > 1023) return "측정 불가";
    if (value <= 100) return "매우 밝음";
    if (value <= 500) return "보통 밝음";
    if (value <= 800) return "어두움";
    return "매우 어두움";
  }

  void showPlantOptionsDialog(BuildContext context, String docId, String plantName, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("‘$plantName’ 관리"),
        content: const Text("이 식물을 어떻게 하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('plantData')
                  .doc(docId)
                  .delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("식물이 삭제되었습니다.")),
              );
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantEditScreen(
                    plantId: docId,
                    plantData: data,
                  ),
                ),
              );
            },
            child: const Text("수정"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('userName')) {
            userName = data['userName'];
          }
        }

        return Scaffold(
          backgroundColor: Palette.backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("안녕하세요, $userName님!",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Icon(Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("내 식물 상태", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _statusBox("조도", light != null ? interpretLight(light!) : "-", Icons.wb_sunny, Colors.amber),
                      const SizedBox(width: 12),
                      _statusBox("수분", water != null ? "$water%" : "-", Icons.water_drop, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusBox("온도", temp != null ? "${temp!.toStringAsFixed(1)}°C" : "-", Icons.thermostat, Colors.red),
                      const SizedBox(width: 12),
                      _statusBox("습도", humi != null ? "${humi!.toStringAsFixed(1)}%" : "-", Icons.air, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text("내 식물", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('plantData')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text("등록된 식물이 없습니다."));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? '이름 없음';
                            final createdAt = data['createdAt'] as Timestamp?;
                            final age = createdAt != null
                                ? 'D+${DateTime.now().difference(createdAt.toDate()).inDays}'
                                : 'D+0';
                            final imageUrl = data['imageUrl'] as String?;
                            final isFavorite = data['isFavorite'] == true;
                            final docId = doc.id;

                            return _plantCard(
                              name,
                              age,
                              imageUrl,
                              isFavorite: isFavorite,
                              onStarTap: () async {
                                final userId = FirebaseAuth.instance.currentUser!.uid;
                                final plantCollection = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('plantData');

                                final batch = FirebaseFirestore.instance.batch();

                                for (final d in docs) {
                                  batch.update(plantCollection.doc(d.id), {'isFavorite': false});
                                }

                                batch.update(plantCollection.doc(docId), {'isFavorite': true});
                                await batch.commit();
                              },
                              onTap: () => showPlantOptionsDialog(context, docId, name, data),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("BLE 수신 로그", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: log.length,
                      itemBuilder: (context, index) => ListTile(
                        dense: true,
                        title: Text(log[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _statusBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label),
                const Spacer(),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  static Widget _plantCard(
      String name,
      String age,
      String? imageUrl, {
        required bool isFavorite,
        required VoidCallback onStarTap,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/images/plant1.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onStarTap,
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.yellow[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(age, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
