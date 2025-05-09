import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlantEditScreen extends StatefulWidget {
  final String plantId;
  final Map<String, dynamic> plantData;

  const PlantEditScreen({super.key, required this.plantId, required this.plantData});

  @override
  State<PlantEditScreen> createState() => _PlantEditScreenState();
}

class _PlantEditScreenState extends State<PlantEditScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.plantData['name'] ?? '';
    _descController.text = widget.plantData['description'] ?? '';
    _selectedType = widget.plantData['type'];
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantData')
        .doc(widget.plantId);

    await docRef.update({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'type': _selectedType,
    });

    setState(() => _isSaving = false);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("식물 수정")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "식물 이름"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "설명"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("식물 타입 선택", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              children: ["다년생", "일년생", "관엽식물", "선인장"].map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedType == type,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            if (_isSaving)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text("수정 저장"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
