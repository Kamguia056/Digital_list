import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ValidationSuccessScreen extends StatelessWidget {
  const ValidationSuccessScreen({super.key, this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    final String sessionCode = args['code'] ?? code ?? 'Code Inconnu';
    final String courseName = args['course'] ?? 'Matière inconnue';
    final String roomName = args['room'] ?? 'Salle inconnue';
    final String teacherName = args['teacherName'] ?? 'Enseignant inconnu';
    
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, size: 64, color: AppTheme.success),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Présence Validée',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Votre émargement a été enregistré avec succès.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoRow(Icons.book_outlined, 'Matière', courseName),
                          const Divider(height: 1),
                          _infoRow(Icons.person_outline_rounded, 'Enseignant', teacherName),
                          const Divider(height: 1),
                          _infoRow(Icons.location_on_outlined, 'Salle', roomName),
                          const Divider(height: 1),
                          _infoRow(Icons.calendar_today_outlined, 'Date', dateStr),
                          const Divider(height: 1),
                          _infoRow(Icons.access_time_rounded, 'Heure', timeStr),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: PrimaryButton(
                      text: 'Retour à l\'accueil',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/student_home',
                          (route) => false,
                        );
                      },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}