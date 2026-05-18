import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
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

    // Coordonnées du campus (à modifier selon ton école)
    const double campusLat = 3.9528258146348687;
    const double campusLng = 11.516680696212836;
    const double maxDistance = 50.0; // 200 mètres

    // Position actuelle
    Position position = await Geolocator.getCurrentPosition();
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
  }

  void _onDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && _scannedCode.isEmpty) {
      setState(() {
        _scannedCode = code;
      });
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

    // Simuler la validation (plus tard connecté à Firebase)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isValidating = false;
    });

    // Rediriger vers l'écran de succès
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/validation_success',
        arguments: {'code': _scannedCode},
      );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Code scanné :',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scannedCode.isEmpty ? 'Aucun code' : _scannedCode,
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
                        _locationStatus ?? 'Vérification...',
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
                                ? '✅ Vous êtes dans la zone autorisée'
                                : '⚠️ Vous devez être sur le campus pour valider',
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
        ],
      ),
    );
  }
}
