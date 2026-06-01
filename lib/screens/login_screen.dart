import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );

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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                          SnackBar(content: Text('Erreur : $err'), backgroundColor: Colors.red),
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
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Pas de retour vers l'accueil depuis la connexion
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
                    const Icon(Icons.lock, size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      ),
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
                    
                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir votre mot de passe.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    
                    // Bouton SE CONNECTER / Loading
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.blue)
                            : const Text(
                                'SE CONNECTER',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Créer un compte étudiant
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/student_register');
                      },
                      child: const Text(
                        'Créer un compte Étudiant',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    
                    // Mot de passe oublié (Optionnel)
                    TextButton(
                      onPressed: () async {
                        final emailController = TextEditingController();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Réinitialiser le mot de passe'),
                            content: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Votre adresse email',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Envoyer'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && emailController.text.isNotEmpty) {
                          try {
                            await _firebaseService.resetPassword(emailController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Email de réinitialisation envoyé ! Vérifiez votre boîte mail.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: Colors.white54),
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