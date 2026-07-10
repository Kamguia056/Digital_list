import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  final FirebaseService _firebaseService = FirebaseService();
  
  String _scannedCode = '';
  bool _isValidating = false;
  String? _locationStatus;
  bool _isOnCampus = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    try {
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

      const double campusLat = 3.9528258146348687;
      const double campusLng = 11.516680696212836;
      const double maxDistance = 5000.0; 

      Position position = await Geolocator.getCurrentPosition();
      
      if (position.isMocked) {
        setState(() {
          _isOnCampus = false;
          _locationStatus = 'FRAUDE: Position fictive détectée !';
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
        _isOnCampus = true; 
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isValidating) return;
    
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && _scannedCode.isEmpty) {
      setState(() {
        _scannedCode = code;
      });
      _validatePresence();
    }
  }

  Future<void> _validatePresence() async {
    if (!_isOnCampus) {
      _showCustomSnackbar('❌ Hors zone autorisée. Rapprochez-vous du campus.', AppTheme.error);
      setState(() => _scannedCode = '');
      return;
    }

    if (_scannedCode.isEmpty) {
      _showCustomSnackbar('Veuillez scanner un code valide', AppTheme.warning);
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      final result = await _firebaseService.validatePresence(_scannedCode);

      if (mounted) {
        if (result['success'] == true) {
          _showCustomSnackbar('✅ Présence validée avec succès !', AppTheme.success);
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
          _showCustomSnackbar('❌ ${result['message']}', AppTheme.error);
          setState(() => _scannedCode = '');
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackbar('Erreur: ${e.toString()}', AppTheme.error);
        setState(() => _scannedCode = '');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _showCustomSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scanner QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Caméra plein écran
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Overlay sombre avec découpe
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),

          // Ligne de scan animée synchronisée avec la découpe
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final double cutoutSize = 250.0;
              final double left = (MediaQuery.of(context).size.width - cutoutSize) / 2;
              final double top = (MediaQuery.of(context).size.height - cutoutSize) / 2 - 50;

              return Positioned(
                top: top + (_animationController.value * cutoutSize),
                left: left,
                width: cutoutSize,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          // Overlay Info (Bas)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isValidating)
                      Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Validation en cours...',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isOnCampus ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isOnCampus ? Icons.location_on_rounded : Icons.location_off_rounded,
                                  color: _isOnCampus ? AppTheme.success : AppTheme.error,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isOnCampus ? 'Zone Autorisée' : 'Hors Zone',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _isOnCampus ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _locationStatus ?? 'Vérification...',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Placez le code QR dans le cadre pour émarger automatiquement.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
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

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black54;
    final clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final double cutoutSize = 250.0;
    final double left = (size.width - cutoutSize) / 2;
    final double top = (size.height - cutoutSize) / 2 - 50; // Décalé un peu vers le haut

    final RRect cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
      const Radius.circular(20),
    );

    canvas.drawRRect(cutoutRect, clearPaint);
    
    // Draw corners
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final double cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    
    // Top Right
    canvas.drawLine(Offset(left + cutoutSize - cornerLength, top), Offset(left + cutoutSize, top), cornerPaint);
    canvas.drawLine(Offset(left + cutoutSize, top), Offset(left + cutoutSize, top + cornerLength), cornerPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(left, top + cutoutSize - cornerLength), Offset(left, top + cutoutSize), cornerPaint);
    canvas.drawLine(Offset(left, top + cutoutSize), Offset(left + cornerLength, top + cutoutSize), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(left + cutoutSize - cornerLength, top + cutoutSize), Offset(left + cutoutSize, top + cutoutSize), cornerPaint);
    canvas.drawLine(Offset(left + cutoutSize, top + cutoutSize), Offset(left + cutoutSize, top + cutoutSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
