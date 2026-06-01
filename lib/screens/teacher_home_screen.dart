import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  String _generatedCode = '';
  DateTime? _expirationTime;
  
  String _teacherName = 'Chargement...';
  String _teacherEmail = '';
  
  final FirebaseService _firebaseService = FirebaseService();
  bool _isGenerating = false;
  
  // Stats dynamiques
  int _totalSessionsCreated = 0;
  int _totalAttendanceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      try {
        final doc = await _firebaseService.getUserProfile(user.uid);
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _teacherName = data['name'] ?? 'Enseignant';
            _teacherEmail = data['email'] ?? user.email ?? '';
          });
          _fetchStats(user.uid);
        }
      } catch (e) {
        debugPrint('Erreur de chargement du profil: $e');
      }
    }
  }

  Future<void> _fetchStats(String teacherId) async {
    try {
      // Compter le nombre de séances créées par cet enseignant
      final sessionsQuery = await FirebaseFirestore.instance
          .collection('sessions')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      int attendancesCount = 0;
      for (var doc in sessionsQuery.docs) {
        final attendanceQuery = await FirebaseFirestore.instance
            .collection('attendance')
            .where('sessionId', isEqualTo: doc.id)
            .get();
        attendancesCount += attendanceQuery.docs.length;
      }

      if (mounted) {
        setState(() {
          _totalSessionsCreated = sessionsQuery.docs.length;
          _totalAttendanceCount = attendancesCount;
        });
      }
    } catch (e) {
      debugPrint('Erreur de chargement des statistiques: $e');
    }
  }

  String _generateUniqueCode() {
    String date = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String random = DateTime.now().millisecondsSinceEpoch.toString().substring(9, 13);
    return 'SESS-$date-$random';
  }

  Future<void> _generateQR() async {
    if (_courseController.text.isEmpty || _roomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir la matière et la salle')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final String sessionCode = _generateUniqueCode();
    final DateTime expTime = DateTime.now().add(const Duration(minutes: 30));

    try {
      await _firebaseService.createSession(
        sessionId: sessionCode,
        course: _courseController.text,
        room: _roomController.text,
        teacherName: _teacherName,
        expiresAt: expTime,
      );

      if (mounted) {
        setState(() {
          _generatedCode = sessionCode;
          _expirationTime = expTime;
        });
        
        final user = _firebaseService.currentUser;
        if (user != null) {
          _fetchStats(user.uid);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de création de session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // Fonction d'exportation PDF
  Future<void> _exportSessionToPdf(List<DocumentSnapshot> presentDocs) async {
    if (_generatedCode.isEmpty) return;

    List<Map<String, dynamic>> studentsList = [];
    for (var doc in presentDocs) {
      final data = doc.data() as Map<String, dynamic>;
      studentsList.add({
        'name': data['studentName'] ?? 'Inconnu',
        'email': data['studentEmail'] ?? '',
        'scannedAt': data['scannedAt'],
      });
    }

    try {
      await PdfService.generateAndShareAttendancePdf(
        courseName: _courseController.text,
        roomName: _roomController.text,
        teacherName: _teacherName,
        sessionId: _generatedCode,
        students: studentsList,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'export PDF : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Écran Accueil (Génération QR)
  Widget _buildHomeScreen() {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  'Bonjour, $_teacherName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez une séance pour générer un QR code',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Matière
                TextField(
                  controller: _courseController,
                  decoration: InputDecoration(
                    labelText: 'Matière',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.book, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 16),

                // Salle
                TextField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: 'Salle',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton Générer
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateQR,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isGenerating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'GÉNÉRER LE QR CODE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // QR Code généré & Liste des étudiants présents en temps réel
                if (_generatedCode.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        QrImageView(
                          data: _generatedCode,
                          version: QrVersions.auto,
                          size: 180,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _generatedCode,
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        if (_expirationTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Expire à : ${_expirationTime!.hour}:${_expirationTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _generatedCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code de session copié !')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('COPIER'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _generatedCode = '';
                                    _expirationTime = null;
                                    _courseController.clear();
                                    _roomController.clear();
                                  });
                                },
                                child: const Text('NOUVEAU'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Bouton CLÔTURER la séance
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clôturer la séance ?'),
                            content: const Text('Les étudiants ne pourront plus émarger. Cette action est irréversible.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Clôturer', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _firebaseService.closeSession(_generatedCode);
                          if (mounted) {
                            setState(() {
                              _generatedCode = '';
                              _expirationTime = null;
                              _courseController.clear();
                              _roomController.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Séance clôturée avec succès.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.stop_circle, color: Colors.red),
                      label: const Text('CLÔTURER LA SÉANCE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section d'écoute temps réel
                  StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.getPresentStudentsStream(_generatedCode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final presentDocs = snapshot.data?.docs ?? [];
                      
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 5,
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
                                  'Présents en temps réel',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${presentDocs.length}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            if (presentDocs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'En attente d\'émargement...',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              )
                            else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: presentDocs.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final data = presentDocs[index].data() as Map<String, dynamic>;
                                  final name = data['studentName'] ?? 'Étudiant';
                                  final email = data['studentEmail'] ?? '';
                                  final time = (data['scannedAt'] as Timestamp?)?.toDate();
                                  final timeStr = time != null
                                      ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                      : '';
                                      
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.check, color: Colors.white),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                                    trailing: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Bouton Exporter en PDF
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton.icon(
                                  onPressed: () => _exportSessionToPdf(presentDocs),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('EXPORTER LA LISTE EN PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Écran Absents (étudiants non présents pour la séance actuelle)
  Widget _buildAbsentsScreen() {
    if (_generatedCode.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Créez d\'abord une séance active pour voir les absents.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getPresentStudentsStream(_generatedCode),
      builder: (context, presentSnapshot) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get(),
          builder: (context, allStudentsSnapshot) {
            if (!allStudentsSnapshot.hasData || !presentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final presentIds = presentSnapshot.data!.docs
                .map((d) => (d.data() as Map<String, dynamic>)['studentId'] as String?)
                .toSet();

            final absentStudents = allStudentsSnapshot.data!.docs
                .where((d) => !presentIds.contains(d.id))
                .toList();

            if (absentStudents.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, size: 80, color: Colors.green),
                    SizedBox(height: 16),
                    Text('Tout le monde est présent ! 🎉', style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${absentStudents.length} absent(s)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text('${presentSnapshot.data!.docs.length} présent(s)', style: const TextStyle(fontSize: 14, color: Colors.green)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: absentStudents.length,
                    itemBuilder: (context, i) {
                      final data = absentStudents[i].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                        title: Text(data['name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Écran Historique (Séances passées)
  Widget _buildHistoryScreen() {
    final user = _firebaseService.currentUser;
    if (user == null) return const Center(child: Text('Non connecté.'));
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('teacherId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final sessionDocs = snapshot.data?.docs ?? [];
        
        if (sessionDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Aucune séance enregistrée',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  child: const Text('Créer une séance'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessionDocs.length,
          itemBuilder: (context, index) {
            final session = sessionDocs[index];
            final data = session.data() as Map<String, dynamic>;
            final course = data['course'] ?? '';
            final room = data['room'] ?? '';
            final sessionId = data['sessionId'] ?? '';
            final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
            
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('sessionId', isEqualTo: sessionId)
                  .get(),
              builder: (context, attendanceSnapshot) {
                final count = attendanceSnapshot.data?.docs.length ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.school, color: Colors.white),
                    ),
                    title: Text(course, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Salle: $room | Code: $sessionId'),
                        Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count présent(s)',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    onTap: () async {
                      // Permettre de ré-exporter la liste à partir de l'historique
                      if (attendanceSnapshot.hasData) {
                        List<Map<String, dynamic>> studentsList = [];
                        for (var doc in attendanceSnapshot.data!.docs) {
                          final attData = doc.data() as Map<String, dynamic>;
                          studentsList.add({
                            'name': attData['studentName'] ?? 'Inconnu',
                            'email': attData['studentEmail'] ?? '',
                            'scannedAt': attData['scannedAt'],
                          });
                        }
                        await PdfService.generateAndShareAttendancePdf(
                          courseName: course,
                          roomName: room,
                          teacherName: _teacherName,
                          sessionId: sessionId,
                          students: studentsList,
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Écran Profil
  Widget _buildProfileScreen() {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 60, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                Text(
                  _teacherName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_teacherEmail, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _profileStatRow('Séances créées', '$_totalSessionsCreated'),
                      const Divider(),
                      _profileStatRow('Total émargements', '$_totalAttendanceCount'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('SE DÉCONNECTER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter de votre compte Enseignant ?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Digital List - Enseignant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          _buildAbsentsScreen(),
          _buildHistoryScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() { _currentIndex = index; });
          final user = _firebaseService.currentUser;
          if (user != null) _fetchStats(user.uid);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Session'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Absents'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}