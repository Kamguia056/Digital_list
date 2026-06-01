import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir le Device ID
  Future<String> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? 'unknown_ios';
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id;
    }
    return 'unknown_device';
  }

  // 1. CONNEXION
  Future<UserCredential> signIn(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      String currentDeviceId = await _getDeviceId();
      DocumentSnapshot userDoc = await getUserProfile(credential.user!.uid);
      
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        // VÉRIFICATION BLOCAGE
        if (data['isBlocked'] == true) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-blocked',
            message: 'Votre compte a été suspendu par un administrateur. Contactez votre établissement.',
          );
        }

        String? savedDeviceId = data['deviceId'];
        Timestamp? lockedUntil = data['deviceLockedUntil'];
        
        if (savedDeviceId != null && savedDeviceId != currentDeviceId) {
          if (lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now())) {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'device-locked',
              message: 'Compte verrouillé sur un autre appareil jusqu\'au ${lockedUntil.toDate().day.toString().padLeft(2, '0')}/${lockedUntil.toDate().month.toString().padLeft(2, '0')}/${lockedUntil.toDate().year}.',
            );
          } else {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'device-change-requested',
              message: 'Changement d\'appareil détecté.',
            );
          }
        } else if (savedDeviceId == null) {
          await _db.collection('users').doc(credential.user!.uid).update({
            'deviceId': currentDeviceId,
            'deviceLockedUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          });
        }
      }
    }

    return credential;
  }

  // 1.bis LIER UN NOUVEL APPAREIL
  Future<void> bindNewDevice(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      String currentDeviceId = await _getDeviceId();
      await _db.collection('users').doc(credential.user!.uid).update({
        'deviceId': currentDeviceId,
        'deviceLockedUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });
    }
  }

  // OBTENIR LE PROFIL UTILISATEUR
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // 2. INSCRIPTION ÉTUDIANT
  Future<UserCredential> signUpStudent({
    required String email,
    required String password,
    required String name,
  }) async {
    // Créer le compte d'authentification
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Enregistrer le profil étudiant dans Firestore
    if (credential.user != null) {
      String deviceId = await _getDeviceId();
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'deviceId': deviceId,
        'deviceLockedUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });
    }

    return credential;
  }

  // 3. INSCRIPTION ENSEIGNANT (via code d'invitation)
  Future<UserCredential> signUpTeacher({
    required String email,
    required String password,
    required String name,
    required String invitationCode,
  }) async {
    // Dans une vraie application, nous vérifierions que l'invitationCode est valide dans une collection Firestore 'invitations'
    // Pour simplifier et sécuriser la démo, on valide les codes commençant par 'TEACH-'
    if (!invitationCode.startsWith('TEACH-')) {
      throw FirebaseAuthException(
        code: 'invalid-invitation-code',
        message: "Code d'invitation invalide. Contactez l'administrateur.",
      );
    }

    // Créer le compte
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Enregistrer le profil enseignant dans Firestore
    if (credential.user != null) {
      String deviceId = await _getDeviceId();
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'deviceId': deviceId,
        'deviceLockedUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });
    }

    return credential;
  }

  // 4. DEMANDE DE DEVENIR ENSEIGNANT
  Future<void> submitTeacherRequest({
    required String name,
    required String email,
    required String phone,
    required String diploma,
    String? localImagePath,
  }) async {
    // Enregistrer la demande dans Firestore
    await _db.collection('teacher_requests').add({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'diploma': diploma.trim(),
      'localImagePath': localImagePath, // Pour référence locale de l'image de carte
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 5. CRÉATION D'UNE SÉANCE DE COURS (Par un Enseignant)
  Future<void> createSession({
    required String sessionId,
    required String course,
    required String room,
    required String teacherName,
    required DateTime expiresAt,
  }) async {
    final String teacherId = currentUser?.uid ?? 'unknown_teacher';

    await _db.collection('sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'course': course.trim(),
      'room': room.trim(),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  // 6. VALIDATION DE PRÉSENCE (Par un Étudiant via QR Code / Code manuel)
  Future<Map<String, dynamic>> validatePresence(String sessionId) async {
    final String? studentId = currentUser?.uid;
    if (studentId == null) {
      return {'success': false, 'message': 'Utilisateur non connecté.'};
    }

    // 1. Récupérer la session dans Firestore
    DocumentSnapshot sessionDoc = await _db.collection('sessions').doc(sessionId).get();
    if (!sessionDoc.exists) {
      return {'success': false, 'message': "Cette séance n'existe pas."};
    }

    Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
    Timestamp expiresAt = sessionData['expiresAt'];

    // 2. Vérifier si la séance a expiré
    if (DateTime.now().isAfter(expiresAt.toDate())) {
      return {'success': false, 'message': 'Cette séance a expiré (validité dépassée).'};
    }

    // 3. Récupérer les informations de l'étudiant connecté
    DocumentSnapshot studentDoc = await _db.collection('users').doc(studentId).get();
    if (!studentDoc.exists) {
      return {'success': false, 'message': 'Profil étudiant introuvable.'};
    }

    Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
    String studentName = studentData['name'] ?? 'Étudiant';
    String studentEmail = studentData['email'] ?? '';

    // 4. Enregistrer la présence
    String attendanceId = '${sessionId}_$studentId';
    await _db.collection('attendance').doc(attendanceId).set({
      'sessionId': sessionId,
      'course': sessionData['course'],
      'room': sessionData['room'],
      'teacherName': sessionData['teacherName'],
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'scannedAt': FieldValue.serverTimestamp(),
    });

    return {
      'success': true,
      'message': 'Présence validée avec succès !',
      'course': sessionData['course'],
      'room': sessionData['room'],
      'teacherName': sessionData['teacherName'],
    };
  }

  // 7. ÉCOUTER LA LISTE DES PRÉSENTS D'UNE SÉANCE EN TEMPS RÉEL (Pour l'Enseignant)
  Stream<QuerySnapshot> getPresentStudentsStream(String sessionId) {
    return _db
        .collection('attendance')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }

  // 8. ÉCOUTER L'HISTORIQUE DE PRÉSENCES D'UN ÉTUDIANT (Pour l'Étudiant)
  Stream<QuerySnapshot> getStudentAttendanceHistoryStream(String studentId) {
    return _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }

  // 9. DÉCONNEXION
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 10. GESTION DES DEMANDES ENSEIGNANTS (ADMIN)
  Stream<QuerySnapshot> getPendingTeacherRequests() {
    return _db.collection('teacher_requests').where('status', isEqualTo: 'pending').snapshots();
  }

  Stream<QuerySnapshot> getProcessedTeacherRequests() {
    return _db.collection('teacher_requests')
        .where('status', whereIn: ['approved', 'rejected']).snapshots();
  }

  // Retourne le code généré pour l'afficher dans la dialog
  Future<String> approveTeacherRequest(String requestId) async {
    String randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    String inviteCode = 'TEACH-$randomPart';
    await _db.collection('teacher_requests').doc(requestId).update({
      'status': 'approved',
      'invitationCode': inviteCode,
      'approvedAt': FieldValue.serverTimestamp(),
    });
    return inviteCode;
  }

  Future<void> rejectTeacherRequest(String requestId) async {
    await _db.collection('teacher_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // 11. STATISTIQUES GLOBALES DU SYSTÈME (ADMIN DASHBOARD)
  Future<Map<String, int>> getSystemStats() async {
    try {
      final studentCount = await _db.collection('users').where('role', isEqualTo: 'student').count().get();
      final teacherCount = await _db.collection('users').where('role', isEqualTo: 'teacher').count().get();
      final sessionCount = await _db.collection('sessions').count().get();
      final attendanceCount = await _db.collection('attendance').count().get();
      final pendingCount = await _db.collection('teacher_requests').where('status', isEqualTo: 'pending').count().get();
      return {
        'students': studentCount.count ?? 0,
        'teachers': teacherCount.count ?? 0,
        'sessions': sessionCount.count ?? 0,
        'attendances': attendanceCount.count ?? 0,
        'pending': pendingCount.count ?? 0,
      };
    } catch (e) {
      return {'students': 0, 'teachers': 0, 'sessions': 0, 'attendances': 0, 'pending': 0};
    }
  }

  // 12. GESTION DES UTILISATEURS (ADMIN)
  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').where('role', whereIn: ['student', 'teacher']).snapshots();
  }

  Future<void> toggleUserBlock(String uid, bool currentlyBlocked) async {
    await _db.collection('users').doc(uid).update({'isBlocked': !currentlyBlocked});
  }

  // 13. GESTION DES SÉANCES (ADMIN + ENSEIGNANT)
  Stream<QuerySnapshot> getActiveSessions() {
    return _db.collection('sessions')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .snapshots();
  }

  Future<void> closeSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).update({
      'expiresAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 1))),
    });
  }

  Stream<QuerySnapshot> getSessionAttendance(String sessionId) {
    return _db.collection('attendance').where('sessionId', isEqualTo: sessionId).snapshots();
  }

  // 14. MOT DE PASSE OUBLIÉ
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
