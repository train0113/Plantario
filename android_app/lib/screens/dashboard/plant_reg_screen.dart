import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:khuthon/screens/dashboard/bluetooth_screen.dart';

class PlantRegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistrationComplete;

  const PlantRegistrationScreen({super.key, required this.onRegistrationComplete});

  @override
  State<PlantRegistrationScreen> createState() => _PlantRegistrationScreenState();
}

class _PlantRegistrationScreenState extends State<PlantRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedType;
  BluetoothDevice? _selectedDevice;
  File? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(String uid, String plantName) async {
    if (_selectedImage == null) return null;
    final fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}_$plantName.jpg';
    final ref = FirebaseStorage.instance.ref().child('plant_images').child(fileName);
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식물 등록'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '식물 이름 입력',
                  hintText: '예: 민트, 라벤더',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '설명',
                  hintText: '식물의 주요 특징을 적어주세요.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text("식물 타입 선택", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTypeChip("다년생"),
                  _buildTypeChip("일년생"),
                  _buildTypeChip("관엽식물"),
                  _buildTypeChip("선인장"),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("사진 촬영 또는 선택"),
              ),
              const SizedBox(height: 12),
              _elevatedButton(
                _selectedDevice == null
                    ? "BLE 기기 선택"
                    : "선택된 기기: ${_selectedDevice!.name}",
                    () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothScreen()),
                  );
                  if (result is BluetoothDevice) {
                    setState(() {
                      _selectedDevice = result;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              _elevatedButton(
                _isSubmitting ? "등록 중..." : "나의 식물 키우기 시작",
                _isSubmitting ? null : _submitPlantData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPlantData() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final type = _selectedType;

    if (name.isEmpty || desc.isEmpty || type == null || _selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목과 기기 선택을 완료해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final imageUrl = await _uploadImageToStorage(user.uid, name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantData')
          .add({
        'name': name,
        'description': desc,
        'type': type,
        'bleDeviceName': _selectedDevice!.name,
        'bleDeviceId': _selectedDevice!.id.id,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      widget.onRegistrationComplete(); // 등록 완료 후 대시보드 전환
    }
  }

  Widget _buildTypeChip(String label) {
    final isSelected = _selectedType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedType = label;
        });
      },
      selectedColor: Colors.green[300],
    );
  }

  Widget _elevatedButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
