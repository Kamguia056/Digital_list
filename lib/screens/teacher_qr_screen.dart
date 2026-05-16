import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherQRScreen extends StatefulWidget {
  const TeacherQRScreen({super.key});

  @override
  State<TeacherQRScreen> createState() => _TeacherQRScreenState();
}

class _TeacherQRScreenState extends State<TeacherQRScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  String _generatedCode = '';
  DateTime? _expirationTime;
  List<String> _presentStudents = [];

  String _generateUniqueCode() {
    String date = DateTime.now().toString().substring(0, 19).replaceAll(':', '-').replaceAll(' ', '-');
    String random = DateTime.now().millisecondsSinceEpoch.toString().substring(9, 13);
    return 'SESS-$date-$random';
  }

  void _generateQR() {
    if (_courseController.text.isEmpty || _roomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir la matière et la salle')),
      );
      return;
    }

    setState(() {
      _generatedCode = _generateUniqueCode();
      _expirationTime = DateTime.now().add(const Duration(minutes: 30));
      _presentStudents = ['Alpha Diallo', 'Fatou Kane', 'Mamadou Diop'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Nouvelle séance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Créer une séance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                      onPressed: _generateQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'GÉNÉRER LE QR CODE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // QR Code généré
                  if (_generatedCode.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                          if (_expirationTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Expire à : ${_expirationTime!.hour}:${_expirationTime!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Code copié ! À partager')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('PARTAGER'),
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
                                      _presentStudents = [];
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
                  ],

                  const SizedBox(height: 20),

                  // Liste des présents
                  if (_presentStudents.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Liste des présents',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Se met à jour automatiquement',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ..._presentStudents.map((student) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(student),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}