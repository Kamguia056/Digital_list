import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TeacherRequestScreen extends StatefulWidget {
  const TeacherRequestScreen({super.key});

  @override
  State<TeacherRequestScreen> createState() => _TeacherRequestScreenState();
}

class _TeacherRequestScreenState extends State<TeacherRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _nom = '';
  String _email = '';
  String _telephone = '';
  String _diplome = '';
  File? _carteImage;
  
  Future<void> _prendrePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    
    if (photo != null) {
      setState(() {
        _carteImage = File(photo.path);
      });
    }
  }
  
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: const Text('Choisissez une source'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _prendrePhoto(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Appareil photo'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _prendrePhoto(ImageSource.gallery);
            },
            icon: const Icon(Icons.folder),
            label: const Text('Galerie'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Devenir Enseignant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add, size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Demande enseignant',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Un administrateur vérifiera votre dossier',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    
                    // Nom complet
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      ),
                      onChanged: (value) => _nom = value,
                      validator: (value) => value!.isEmpty ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email professionnel',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      ),
                      onChanged: (value) => _email = value,
                      validator: (value) => value!.isEmpty ? 'Email requis' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Téléphone
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                      ),
                      onChanged: (value) => _telephone = value,
                      validator: (value) => value!.isEmpty ? 'Téléphone requis' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Diplôme
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Diplôme / Titre',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.school, color: Colors.blue),
                      ),
                      onChanged: (value) => _diplome = value,
                      validator: (value) => value!.isEmpty ? 'Diplôme requis' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Section photo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.badge, size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text(
                            'Photo de votre carte professionnelle',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '(carte d\'identité ou carte d\'enseignant)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          
                          // Aperçu de l'image
                          if (_carteImage != null)
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.file(_carteImage!, fit: BoxFit.cover),
                            ),
                          
                          if (_carteImage == null)
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                              ),
                            ),
                          
                          const SizedBox(height: 12),
                          
                          ElevatedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Ajouter une photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Bouton Envoyer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'ENVOYER MA DEMANDE',
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
      ),
    );
  }
}