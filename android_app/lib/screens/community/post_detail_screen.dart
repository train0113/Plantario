// lib/screens/community/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostDetailScreen({super.key, required this.data});

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '제목 없음';
    final content = data['content'] ?? '';
    final userId = data['userId'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedTime = createdAt != null ? DateFormat('yyyy.MM.dd HH:mm').format(createdAt) : '작성일 미상';

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 보기')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(userId),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          final nickname = userData?['userName'] ?? '익명';
          final imageUrl = userData?['imageUrl'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                      child: imageUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(formattedTime, style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
