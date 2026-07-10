import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _studentName = 'Chargement...';
  String _studentEmail = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      try {
        final doc = await _firebaseService.getUserProfile(user.uid);
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _studentName = data['name'] ?? 'Étudiant';
            _studentEmail = data['email'] ?? user.email ?? '';
          });
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement du profil: $e');
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter de votre compte Étudiant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firebaseService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('DÉCONNECTER', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(List<DocumentSnapshot> attendanceDocs) {
    const int totalExpectedClasses = 15;
    int attendedClasses = attendanceDocs.length;
    double attendancePercentage = totalExpectedClasses > 0 
        ? (attendedClasses / totalExpectedClasses).clamp(0.0, 1.0)
        : 0.0;
    int percentageInt = (attendancePercentage * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Text(
              'Bonjour, ${_studentName.split(' ').first} 👋',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 8),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Prêt à valider votre présence aujourd\'hui ?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TAUX DE PRÉSENCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$percentageInt%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$attendedClasses / $totalExpectedClasses cours',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: attendancePercentage,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/scanner');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scanner un QR Code',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Validez votre présence instantanément',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: const Text(
              'Dernières présences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (attendanceDocs.isEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune présence enregistrée.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceDocs.length > 3 ? 3 : attendanceDocs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = attendanceDocs[index].data() as Map<String, dynamic>;
                  final course = data['course'] ?? 'Inconnu';
                  final teacher = data['teacherName'] ?? '';
                  final scannedAt = data['scannedAt'] as Timestamp?;
                  String timeStr = '';
                  if (scannedAt != null) {
                    final time = scannedAt.toDate();
                    timeStr = '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} - ${time.hour}h${time.minute.toString().padLeft(2, '0')}';
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teacher,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté.')));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getStudentAttendanceHistoryStream(user.uid),
      builder: (context, snapshot) {
        final attendanceDocs = snapshot.data?.docs ?? [];
        
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Mon Espace'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _showLogoutDialog,
                tooltip: 'Déconnexion',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(attendanceDocs),
              // Historique détaillé
              ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: attendanceDocs.length,
                itemBuilder: (context, index) {
                  final data = attendanceDocs[index].data() as Map<String, dynamic>;
                  final course = data['course'] ?? '';
                  final room = data['room'] ?? '';
                  final teacher = data['teacherName'] ?? '';
                  final scannedAt = (data['scannedAt'] as Timestamp?)?.toDate();
                  final dateStr = scannedAt != null 
                      ? '${scannedAt.day.toString().padLeft(2, '0')}/${scannedAt.month.toString().padLeft(2, '0')}/${scannedAt.year} à ${scannedAt.hour}h${scannedAt.minute.toString().padLeft(2, '0')}'
                      : '';
                      
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.class_rounded, color: AppTheme.primary),
                      ),
                      title: Text(course, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Salle $room • $teacher\n$dateStr', style: const TextStyle(height: 1.4)),
                      ),
                      trailing: const Icon(Icons.verified_rounded, color: AppTheme.success),
                    ),
                  );
                },
              ),
              // Profil
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _studentName,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _studentEmail,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.badge_rounded, color: AppTheme.textSecondary),
                              title: const Text('Rôle'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ÉTUDIANT',
                                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.history_edu_rounded, color: AppTheme.textSecondary),
                              title: const Text('Total présences'),
                              trailing: Text(
                                '${attendanceDocs.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex == 0 ? 0 : (_currentIndex == 1 ? 2 : 3),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historique'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
            onTap: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, '/scanner');
              } else {
                setState(() {
                  if (index == 0) _currentIndex = 0;
                  if (index == 2) _currentIndex = 1;
                  if (index == 3) _currentIndex = 2;
                });
              }
            },
          ),
        );
      },
    );
  }
}