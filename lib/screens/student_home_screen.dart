import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

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
            child: const Text('DÉCONNECTER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(List<DocumentSnapshot> attendanceDocs) {
    // Calculer les statistiques réelles
    // Par exemple, supposons que le semestre compte théoriquement 20 cours au total.
    const int totalExpectedClasses = 15;
    int attendedClasses = attendanceDocs.length;
    double attendancePercentage = totalExpectedClasses > 0 
        ? (attendedClasses / totalExpectedClasses).clamp(0.0, 1.0)
        : 0.0;
    int percentageInt = (attendancePercentage * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message de bienvenue
          Text(
            'Bonjour, $_studentName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prêt à valider votre présence ?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Carte statistiques d'émargement réelles
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MON HISTORIQUE D\'ÉMARGEMENT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$attendedClasses / $totalExpectedClasses présences',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: attendancePercentage,
                  backgroundColor: Colors.white30,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentageInt% de présence ce semestre',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Carte SCANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  'Scanner un code QR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Validez votre présence en cours en scannant',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scanner');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('SCANNER MAINTENANT →', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Dernières séances émargées réelles
          const Text(
            '📋 DERNIÈRES SÉANCES ÉMARGÉES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (attendanceDocs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Aucun émargement enregistré pour le moment.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = attendanceDocs[index].data() as Map<String, dynamic>;
                final course = data['course'] ?? 'Matière inconnue';
                final room = data['room'] ?? 'Salle';
                final teacher = data['teacherName'] ?? 'Enseignant';
                
                final scannedAt = data['scannedAt'] as Timestamp?;
                String timeStr = 'Date inconnue';
                if (scannedAt != null) {
                  final time = scannedAt.toDate();
                  timeStr = '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} à ${time.hour}h${time.minute.toString().padLeft(2, '0')}';
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Salle $room | Enseigné par $teacher',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Présent',
                              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Digital List - Étudiant'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _showLogoutDialog,
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(attendanceDocs),
              // Historique détaillé
              ListView.builder(
                padding: const EdgeInsets.all(16),
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
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.class_, color: Colors.blue),
                      title: Text(course, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Salle: $room | Enseignant: $teacher\n$dateStr'),
                      trailing: const Icon(Icons.verified, color: Colors.green),
                    ),
                  );
                },
              ),
              // Profil de l'étudiant
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.school, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _studentName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _studentEmail,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Rôle utilisateur:'),
                                  Text('Étudiant'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total émargements:'),
                                  Text('${attendanceDocs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex == 0 ? 0 : (_currentIndex == 1 ? 2 : 3), // Adapter pour correspondre aux items de la bar
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            ],
            onTap: (index) {
              if (index == 1) {
                // Rediriger vers l'appareil photo scanner
                Navigator.pushNamed(context, '/scanner');
              } else {
                setState(() {
                  // Maper les index de la BottomBar aux index réels du IndexedStack
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