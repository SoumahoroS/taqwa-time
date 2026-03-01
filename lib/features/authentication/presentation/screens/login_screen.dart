import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_text_field.dart';
import '../../../../shared/widgets/glass/gradient_mesh_background.dart';
import '../../../../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationAfterLogin() async {
    if (!mounted) return;
    try {
      await _locationService.requestLocationOnLogin(context);
    } catch (e) {
      print('Erreur lors de la demande de localisation: $e');
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        await _requestLocationAfterLogin();
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'authentification: ${e.toString()}'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final user = await authService.signInWithGoogle();
      if (user != null && mounted) {
        await _requestLocationAfterLogin();
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion Google: ${e.toString()}'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signInWithGoogle,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Google
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _GoogleLogoPainter(),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuer avec Google',
              style: TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.spacingLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                        child: Image.asset(
                          'assets/images/logos/taqwaTime-logo.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                              ),
                              child: const Icon(Icons.timer, size: 50, color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingLG),

                    const Text(
                      'TaqwaTime',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingSM),
                    Text(
                      'Connectez-vous à votre compte',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingXL),

                    // Form card
                    GlassCard(
                      padding: const EdgeInsets.all(AppTokens.spacingLG),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            GlassTextField(
                              controller: _emailController,
                              label: 'Email',
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTokens.spacingMD),

                            GlassTextField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              prefixIcon: Icons.lock,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTokens.spacingLG),

                            GlassButton(
                              label: 'Se connecter',
                              onPressed: _isLoading ? null : _authenticate,
                              variant: GlassButtonVariant.primary,
                              icon: Icons.login,
                              isLoading: _isLoading,
                              width: double.infinity,
                            ),
                            const SizedBox(height: AppTokens.spacingMD),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMD),
                                  child: Text(
                                    'OU',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spacingMD),

                            _buildGoogleButton(),
                            const SizedBox(height: AppTokens.spacingLG),

                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                              child: const Text(
                                'Pas de compte? S\'inscrire',
                                style: TextStyle(
                                  color: AppColors.accentLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                              icon: Icon(Icons.arrow_back, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                              label: Text(
                                'Retour à l\'accueil',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                              ),
                            ),
                          ],
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.45;

    // Bleu (haut droit)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.6, 1.8, true, bluePaint,
    );

    // Vert (bas droit)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.2, 1.1, true, greenPaint,
    );

    // Jaune (bas gauche)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.3, 1.0, true, yellowPaint,
    );

    // Rouge (haut gauche)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.3, 1.5, true, redPaint,
    );

    // Cercle blanc interieur
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, whitePaint);

    // Barre horizontale bleue (le "G")
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r * 0.95, r * 0.3),
      bluePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r * 0.5, r * 0.3),
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
