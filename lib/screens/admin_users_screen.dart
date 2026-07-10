import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Aucun $role inscrit.', style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final name = data['name'] ?? 'Inconnu';
            final email = data['email'] ?? '';
            final isBlocked = data['isBlocked'] == true;

            return FadeInUp(
              delay: Duration(milliseconds: index * 50),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isBlocked ? AppTheme.error.withValues(alpha: 0.1) : (role == 'teacher' ? AppTheme.success.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      role == 'teacher' ? Icons.school_rounded : Icons.person_rounded,
                      color: isBlocked ? AppTheme.error : (role == 'teacher' ? AppTheme.success : Colors.blue),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isBlocked ? AppTheme.error : AppTheme.textPrimary),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        if (isBlocked) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('🔒 Compte suspendu', style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: !isBlocked,
                    activeColor: AppTheme.success,
                    inactiveThumbColor: AppTheme.error,
                    onChanged: (_) async {
                      final action = isBlocked ? 'réactiver' : 'suspendre';
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer'),
                          content: Text('Voulez-vous $action le compte de $name ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? AppTheme.success : AppTheme.error),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(isBlocked ? 'Réactiver' : 'Suspendre'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _firebaseService.toggleUserBlock(uid, isBlocked);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded), text: 'Étudiants'),
            Tab(icon: Icon(Icons.person_outline_rounded), text: 'Enseignants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList('student'),
          _buildUserList('teacher'),
        ],
      ),
    );
  }
}
