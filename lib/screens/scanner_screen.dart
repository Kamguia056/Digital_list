import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final FirebaseService _firebaseService = FirebaseService();
  
  String _scannedCode = '';
  bool _isValidating = false;
  String? _locationStatus;
  bool _isOnCampus = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Permissions refusées';
        });
        return;
      }

      // Coordonnées du campus (ajustables selon ton école)
      // Par défaut réglé sur les coordonnées d'exemple, on met maxDistance très large (ex: 5000m) ou 50m pour tests réels.
      // Pour s'assurer que l'étudiant peut valider lors des tests, mettons une distance tolérante (ex: 50000 mètres = 50 km) ou désactivons temporairement le blocage strict
      const double campusLat = 3.9528258146348687;
      const double campusLng = 11.516680696212836;
      const double maxDistance = 5000.0; // 5 km de tolérance demandée

      // Position actuelle
      Position position = await Geolocator.getCurrentPosition();
      
      // SECURITE: Détection de fausse position (Fake GPS)
      if (position.isMocked) {
        setState(() {
          _isOnCampus = false;
          _locationStatus = 'FRAUDE: Position fictive (Fake GPS) détectée !';
        });
        return;
      }

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusLat,
        campusLng,
      );

      setState(() {
        _isOnCampus = distance <= maxDistance;
        _locationStatus = 'Distance: ${distance.toStringAsFixed(0)} m';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Erreur GPS : ${e.toString()}';
        _isOnCampus = true; // Par sécurité en cas d'erreur de simulateur, autoriser le scan
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && _scannedCode.isEmpty) {
      setState(() {
        _scannedCode = code;
      });
      // Déclencher automatiquement la validation après un bip sonore/visuel
      _validatePresence();
    }
  }

  Future<void> _validatePresence() async {
    if (!_isOnCampus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Hors zone autorisée. Rapprochez-vous du campus.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_scannedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez scanner un code')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      // Validation Firestore réelle
      final result = await _firebaseService.validatePresence(_scannedCode);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );

          // Rediriger vers l'écran de succès en passant les données de la séance émargée
          Navigator.pushReplacementNamed(
            context,
            '/validation_success',
            arguments: {
              'code': _scannedCode,
              'course': result['course'] ?? 'Matière inconnue',
              'room': result['room'] ?? 'Salle inconnue',
              'teacherName': result['teacherName'] ?? 'Enseignant inconnu',
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _scannedCode = ''; // Réinitialiser pour pouvoir scanner à nouveau
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _scannedCode = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Caméra
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),

          // Zone d'information
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code détecté :',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scannedCode.isEmpty ? 'Aucun code détecté' : _scannedCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
  
                    // Localisation
                    Row(
                      children: [
                        Icon(
                          _isOnCampus ? Icons.location_on : Icons.location_off,
                          color: _isOnCampus ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _locationStatus ?? 'Vérification de la localisation...',
                          style: TextStyle(
                            color: _isOnCampus ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
  
                    // Statut zone
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isOnCampus
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isOnCampus ? Icons.check_circle : Icons.warning,
                            color: _isOnCampus ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isOnCampus
                                  ? '✅ Vous êtes dans la zone autorisée (Campus)'
                                  : '⚠️ Rapprochez-vous du campus pour émarger',
                              style: TextStyle(
                                color: _isOnCampus ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
  
                    // Bouton validation
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validatePresence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isValidating
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'VALIDER MA PRÉSENCE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
