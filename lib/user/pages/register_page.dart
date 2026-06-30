// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';

class _Palette {
  static const background = Color(0xFF0B0B0D);
  static const surface = Color(0xFF161617);
  static const surfaceLight = Color(0xFF1F1F21);
  static const primary = Color(0xFFB22222);
  static const primaryDark = Color(0xFF8C1A1A);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA8A8AC);
  static const error = Color(0xFFFF5C5C);
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedCity;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _cities = [
    'Aveiro', 'Beja', 'Braga', 'Bragança', 'Castelo Branco', 'Coimbra',
    'Évora', 'Faro', 'Guarda', 'Leiria', 'Lisboa', 'Portalegre', 'Porto',
    'Santarém', 'Setúbal', 'Viana do Castelo', 'Vila Real', 'Viseu',
    'Açores', 'Madeira',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return e.message ?? 'Erro de autenticação.';
    }
  }

  Future<void> _validateAndRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserModel? newUser = await _authController.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        city: _selectedCity!,
      );

      if (newUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registo realizado com sucesso!'),
            backgroundColor: _Palette.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is FirebaseAuthException
            ? _mapFirebaseError(e)
            : 'Não foi possível concluir o registo. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _Palette.primary.withOpacity(0.22),
                    _Palette.primary.withOpacity(0),
                  ]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _Palette.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _Palette.primary.withOpacity(0.25),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo_falcao.png',
                                height: 64,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.flutter_dash, color: _Palette.primary, size: 64),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Crie a sua conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Preencha os dados abaixo para começar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _Palette.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 28),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _Palette.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _Palette.error.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: _Palette.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                        style: const TextStyle(color: _Palette.error, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _field(
                            controller: _nameController,
                            label: 'Nome completo',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _phoneController,
                            label: 'Número',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Número é obrigatório';
                              if (!RegExp(r'^\d{9}$').hasMatch(v.trim())) return 'Deve ter 9 dígitos';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email é obrigatório';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            onChanged: (v) => setState(() => _selectedCity = v),
                            validator: (v) => v == null ? 'Cidade é obrigatória' : null,
                            dropdownColor: _Palette.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textSecondary),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: _decoration(label: 'Sua cidade', icon: Icons.location_on_outlined),
                            items: _cities
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _passwordController,
                            label: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_passwordVisible,
                            suffix: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: _Palette.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Senha é obrigatória';
                              if (v.length < 6) return 'Mínimo de 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _confirmPasswordController,
                            label: 'Confirmar senha',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_confirmPasswordVisible,
                            suffix: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: _Palette.textSecondary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirme a sua senha';
                              if (v != _passwordController.text) return 'As senhas não coincidem';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _validateAndRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _Palette.primary,
                                disabledBackgroundColor: _Palette.primary.withOpacity(0.6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                    )
                                  : const Text('Registar',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(foregroundColor: _Palette.primary),
                              child: const Text('Já tem conta? Entre',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration({required String label, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: _Palette.textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _Palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.error, width: 1.4),
      ),
      errorStyle: const TextStyle(color: _Palette.error, fontSize: 12),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: _Palette.primary,
      decoration: _decoration(label: label, icon: icon, suffix: suffix),
    );
  }
}