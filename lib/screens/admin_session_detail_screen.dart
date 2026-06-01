import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class AdminSessionDetailScreen extends StatelessWidget {
  final String sessionId;
  final String courseName;
  final String room;
  final String teacherName;

  const AdminSessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.courseName,
    required this.room,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Entête info séance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.deepPurple, size: 18),
                  const SizedBox(width: 6),
                  Text('Salle : $room', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person, color: Colors.deepPurple, size: 18),
                  const SizedBox(width: 6),
                  Text('Enseignant : $teacherName'),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.tag, color: Colors.deepPurple, size: 18),
                  const SizedBox(width: 6),
                  Text('Code : $sessionId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ]),
              ],
            ),
          ),

          // Liste des présents
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firebaseService.getSessionAttendance(sessionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Aucun étudiant présent.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Présents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${docs.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final name = data['studentName'] ?? 'Inconnu';
                          final email = data['studentEmail'] ?? '';
                          final time = (data['scannedAt'] as Timestamp?)?.toDate();
                          final timeStr = time != null
                              ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                              : '--:--';

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white, size: 18),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                            trailing: Text(timeStr, style: const TextStyle(color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
