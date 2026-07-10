import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'admin_users_screen.dart';
import 'admin_session_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _AdminDashboard(),
    const _AdminRequestsPage(),
    const _AdminSessionsPage(),
    const _AdminUsersPage(),
    const _AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Demandes'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Séances'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Utilisateurs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// ONGLET 1 : DASHBOARD
// ═══════════════════════════════════════
class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = _firebaseService.getSystemStats();
    });
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color, int delay) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Centre de Contrôle'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshStats),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? {};
          return RefreshIndicator(
            onRefresh: () async => _refreshStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text('Vue d\'ensemble', style: Theme.of(context).textTheme.displaySmall),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard('Étudiants', stats['students'] ?? 0, Icons.school_rounded, Colors.blue, 100),
                      _buildStatCard('Enseignants', stats['teachers'] ?? 0, Icons.person_rounded, AppTheme.success, 200),
                      _buildStatCard('Séances', stats['sessions'] ?? 0, Icons.event_note_rounded, Colors.orange, 300),
                      _buildStatCard('Émargements', stats['attendances'] ?? 0, Icons.check_circle_rounded, AppTheme.primary, 400),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.error.withValues(alpha: 0.8), AppTheme.error],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppTheme.error.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Demandes en attente', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                Text('${stats['pending'] ?? 0}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Text('Activité (7 derniers jours)', style: Theme.of(context).textTheme.displaySmall),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            barGroups: List.generate(7, (i) {
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: ((stats['attendances'] ?? 0) / 7.0 * (i % 3 + 0.5)),
                                  color: AppTheme.primary,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ]);
                            }),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                                    return Text(days[v.toInt()], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary));
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// ONGLET 2 : DEMANDES ENSEIGNANTS
// ═══════════════════════════════════════
class _AdminRequestsPage extends StatefulWidget {
  const _AdminRequestsPage();
  @override
  State<_AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<_AdminRequestsPage> with SingleTickerProviderStateMixin {
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

  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getPendingTeacherRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('Aucune demande en attente.', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snapshot.data!.docs[i];
            final req = doc.data() as Map<String, dynamic>;
            return FadeInUp(
              delay: Duration(milliseconds: i * 100),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                              Text(req['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(req['phone'] ?? 'N/A', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(req['diploma'] ?? 'N/A', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                            onPressed: () => _firebaseService.rejectTeacherRequest(doc.id),
                            child: const Text('Rejeter', style: TextStyle(color: AppTheme.error)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                            onPressed: () async {
                              final code = await _firebaseService.approveTeacherRequest(doc.id);
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Demande Approuvée', style: TextStyle(color: AppTheme.success)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Transmettez ce code d\'invitation à l\'enseignant :'),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppTheme.primary)),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: code));
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié !'), backgroundColor: AppTheme.success));
                                        },
                                        child: const Text('Copier'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: const Text('Approuver'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getProcessedTeacherRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Aucune demande traitée.', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final req = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            final isApproved = req['status'] == 'approved';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isApproved ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isApproved ? Icons.check_rounded : Icons.close_rounded, color: isApproved ? AppTheme.success : AppTheme.error),
                ),
                title: Text(req['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: Text(req['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                trailing: isApproved
                    ? GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: req['invitationCode'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié !'), backgroundColor: AppTheme.success));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(req['invitationCode'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12)),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Rejeté', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
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
        title: const Text('Demandes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions_rounded), text: 'En attente'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendingList(), _buildHistoryList()],
      ),
    );
  }
}

// ═══════════════════════════════════════
// ONGLET 3 : SÉANCES ACTIVES
// ═══════════════════════════════════════
class _AdminSessionsPage extends StatelessWidget {
  const _AdminSessionsPage();

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Séances Actives'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.getActiveSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Aucune séance active.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final expires = (data['expiresAt'] as Timestamp?)?.toDate();
              final expiresStr = expires != null ? 'Expire à ${expires.hour}:${expires.minute.toString().padLeft(2, '0')}' : '';

              return FadeInUp(
                delay: Duration(milliseconds: i * 100),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.sensors_rounded, color: Colors.orange),
                    ),
                    title: Text(data['course'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text('Salle: ${data['room']} • ${data['teacherName']}\n$expiresStr', style: const TextStyle(height: 1.4, color: AppTheme.textSecondary)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_rounded, color: AppTheme.primary),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminSessionDetailScreen(
                                sessionId: doc.id,
                                courseName: data['course'] ?? '',
                                room: data['room'] ?? '',
                                teacherName: data['teacherName'] ?? '',
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, color: AppTheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Fermer la séance ?'),
                                content: Text('Forcer la fermeture de "${data['course']}" ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) await firebaseService.closeSession(doc.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// ONGLET 4 : GESTION UTILISATEURS
// ═══════════════════════════════════════
class _AdminUsersPage extends StatelessWidget {
  const _AdminUsersPage();
  @override
  Widget build(BuildContext context) => const AdminUsersScreen();
}

// ═══════════════════════════════════════
// ONGLET 5 : PROFIL ADMIN
// ═══════════════════════════════════════
class _AdminProfilePage extends StatelessWidget {
  const _AdminProfilePage();

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profil Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 2)),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.admin_panel_settings_rounded, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text('Administrateur', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await firebaseService.signOut();
                    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  label: const Text('SE DÉCONNECTER', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
