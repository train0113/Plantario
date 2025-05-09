import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:khuthon/screens/community/post_detail_screen.dart';
import 'package:khuthon/screens/community/post_write_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('아직 글이 없습니다.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userId = data['userId'];
              final title = data['title'] ?? '제목 없음';
              final content = data['content'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final formattedTime = DateFormat('yyyy.MM.dd HH:mm').format(createdAt);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserData(userId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final nickname = userData?['userName'] ?? '익명';
                  final imageUrl = userData?['imageUrl'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nickname, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            "${formattedTime}\n${content.length > 50 ? content.substring(0, 50) + '...' : content}",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(data: data),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostWriteScreen()),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
