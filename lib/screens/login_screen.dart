import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final String uid = credential.user!.uid;
      final DocumentSnapshot userProfile = await _firebaseService.getUserProfile(uid);

      if (!userProfile.exists) {
        throw Exception("Profil utilisateur Firestore introuvable.");
      }

      final Map<String, dynamic> userData = userProfile.data() as Map<String, dynamic>;
      final String role = userData['role'] ?? 'student';

      if (mounted) {
        if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin_home', (route) => false);
        } else if (role == 'teacher') {
          Navigator.pushNamedAndRemoveUntil(context, '/teacher_home', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/student_home', (route) => false);
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'device-change-requested') {
        if (mounted) {
          setState(() { _isLoading = false; });
          _showDeviceChangeDialog();
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeviceChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Changement d\'appareil'),
        content: const Text(
          'Vous essayez de vous connecter sur un nouvel appareil.\n\nAttention : Si vous continuez, votre compte sera VERROUILLÉ sur ce nouveau téléphone pendant 30 jours, et l\'ancien ne fonctionnera plus.\n\nVoulez-vous vraiment lier ce téléphone à votre compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() { _isLoading = true; });
              try {
                await _firebaseService.bindNewDevice(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
                _login(); // Relancer la connexion
              } catch (err) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $err'), backgroundColor: AppTheme.error),
                  );
                  setState(() { _isLoading = false; });
                }
              }
            },
            child: const Text('Oui, lier ce téléphone', style: TextStyle(color: Colors.white)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Bon retour',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous à votre compte',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre adresse email.';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Veuillez saisir un email valide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Mot de passe',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe.';
                          }
                          return null;
                        },
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                             // Reset password logic
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      PrimaryButton(
                        text: 'Se connecter',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pas encore de compte ? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/student_register');
                            },
                            child: Text(
                              "S'inscrire",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}