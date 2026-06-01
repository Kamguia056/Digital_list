import 'package:flutter/material.dart';

class ValidationSuccessScreen extends StatelessWidget {
  const ValidationSuccessScreen({super.key, this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments transmis lors de la navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    final String sessionCode = args['code'] ?? code ?? 'Code Inconnu';
    final String courseName = args['course'] ?? 'Matière inconnue';
    final String roomName = args['room'] ?? 'Salle inconnue';
    final String teacherName = args['teacherName'] ?? 'Enseignant inconnu';
    
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cercle vert avec icône check
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'PRÉSENCE VALIDÉE !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Votre émargement a été enregistré avec succès dans la base de données.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // Carte des détails
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.book, 'Matière', courseName),
                        const Divider(),
                        _infoRow(Icons.person, 'Enseignant', teacherName),
                        const Divider(),
                        _infoRow(Icons.location_on, 'Salle', roomName),
                        const Divider(),
                        _infoRow(Icons.calendar_today, 'Date', dateStr),
                        const Divider(),
                        _infoRow(Icons.access_time, 'Heure d\'émargement', timeStr),
                        const Divider(),
                        _infoRow(Icons.qr_code, 'ID Séance', sessionCode),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Bouton retour
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/student_home',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'RETOUR À L\'ACCUEIL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}