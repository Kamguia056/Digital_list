import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';

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
        SnackBar(
          content: const Text('Veuillez remplir la matière et la salle'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
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
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
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
          content: Text('Erreur PDF : ${e.toString()}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_rounded, size: 60, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Bonjour, ${_teacherName.split(' ').first}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Créez une séance pour générer le QR code.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 40),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: CustomTextField(
                    controller: _courseController,
                    labelText: 'Matière (ex: Algorithmique)',
                    prefixIcon: Icons.book_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: CustomTextField(
                    controller: _roomController,
                    labelText: 'Salle (ex: Amphi 300)',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 32),

                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: PrimaryButton(
                    text: 'Générer le QR Code',
                    isLoading: _isGenerating,
                    onPressed: _generateQR,
                    icon: Icons.qr_code_rounded,
                  ),
                ),
                const SizedBox(height: 32),

                if (_generatedCode.isNotEmpty)
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: QrImageView(
                              data: _generatedCode,
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.textPrimary,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              _generatedCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (_expirationTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Expire à : ${_expirationTime!.hour}:${_expirationTime!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _generatedCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Code copié !'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  label: const Text('Copier'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
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
                                  child: const Text('Nouveau'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Clôturer la séance ?'),
                                    content: const Text('Les étudiants ne pourront plus émarger. Action irréversible.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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
                                      const SnackBar(content: Text('Séance clôturée.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.stop_circle_rounded, color: AppTheme.error),
                              label: const Text('CLÔTURER LA SÉANCE', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_generatedCode.isNotEmpty)
                  StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.getPresentStudentsStream(_generatedCode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final presentDocs = snapshot.data?.docs ?? [];
                      return FadeInUp(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Présents',
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${presentDocs.length}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (presentDocs.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Text(
                                      'En attente d\'émargement...',
                                      style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                )
                              else ...[
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: presentDocs.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final data = presentDocs[index].data() as Map<String, dynamic>;
                                    final name = data['studentName'] ?? 'Étudiant';
                                    final time = (data['scannedAt'] as Timestamp?)?.toDate();
                                    final timeStr = time != null ? '${time.hour}h${time.minute.toString().padLeft(2, '0')}' : '';
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      leading: const CircleAvatar(
                                        backgroundColor: AppTheme.success,
                                        radius: 16,
                                        child: Icon(Icons.check, color: Colors.white, size: 16),
                                      ),
                                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      trailing: Text(timeStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _exportSessionToPdf(presentDocs),
                                    icon: const Icon(Icons.picture_as_pdf_rounded),
                                    label: const Text('EXPORTER EN PDF'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbsentsScreen() {
    if (_generatedCode.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text(
                'Créez d\'abord une séance active\npour voir les absents.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
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
                    Icon(Icons.celebration_rounded, size: 64, color: AppTheme.success),
                    SizedBox(height: 16),
                    Text('Tout le monde est présent ! 🎉', style: TextStyle(fontSize: 18, color: AppTheme.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Absents', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('${absentStudents.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.error)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: AppTheme.border),
                        Column(
                          children: [
                            const Text('Présents', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('${presentSnapshot.data!.docs.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: absentStudents.length,
                      itemBuilder: (context, i) {
                        final data = absentStudents[i].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.error,
                              radius: 16,
                              child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                            title: Text(data['name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryScreen() {
    final user = _firebaseService.currentUser;
    if (user == null) return const Center(child: Text('Non connecté.'));
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final sessionDocs = snapshot.data?.docs ?? [];
        if (sessionDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucune séance enregistrée', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 0),
                  child: const Text('Créer une séance', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: sessionDocs.length,
          itemBuilder: (context, index) {
            final data = sessionDocs[index].data() as Map<String, dynamic>;
            final course = data['course'] ?? '';
            final room = data['room'] ?? '';
            final sessionId = data['sessionId'] ?? '';
            final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
            
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('attendance').where('sessionId', isEqualTo: sessionId).get(),
              builder: (context, attendanceSnapshot) {
                final count = attendanceSnapshot.data?.docs.length ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.class_rounded, color: AppTheme.primary),
                    ),
                    title: Text(course, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text('Salle $room\n$dateStr', style: const TextStyle(height: 1.4)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('$count présents', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    onTap: () async {
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
                          courseName: course, roomName: room, teacherName: _teacherName, sessionId: sessionId, students: studentsList,
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

  Widget _buildProfileScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 2)),
                child: const CircleAvatar(radius: 50, backgroundColor: AppTheme.primary, child: Icon(Icons.person_rounded, size: 50, color: Colors.white)),
              ),
              const SizedBox(height: 24),
              Text(_teacherName, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(_teacherEmail, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
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
                      leading: const Icon(Icons.class_rounded, color: AppTheme.textSecondary),
                      title: const Text('Séances créées'),
                      trailing: Text('$_totalSessionsCreated', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.people_rounded, color: AppTheme.textSecondary),
                      title: const Text('Total émargements'),
                      trailing: Text('$_totalAttendanceCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firebaseService.signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Déconnecter', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Espace Enseignant'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          const SizedBox(width: 8),
        ],
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
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Absents'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}