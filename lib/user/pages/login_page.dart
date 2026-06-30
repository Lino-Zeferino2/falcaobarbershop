// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';
import 'forgot_password_page.dart';

// Paleta central do app — mude aqui se precisar ajustar o tema em um só lugar.
class _Palette {
  static const background = Color(0xFF0B0B0D);
  static const surface = Color(0xFF161617);
  static const surfaceLight = Color(0xFF1F1F21);
  static const primary = Color(0xFFB22222);
  static const primaryDark = Color(0xFF8C1A1A);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA8A8AC);
  static const error = Color(0xFFFF5C5C);
  static const success = Color(0xFF3DDC84);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedCity;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const List<String> _cities = [
    'Aveiro', 'Beja', 'Braga', 'Bragança', 'Castelo Branco', 'Coimbra',
    'Évora', 'Faro', 'Guarda', 'Leiria', 'Lisboa', 'Portalegre', 'Porto',
    'Santarém', 'Setúbal', 'Viana do Castelo', 'Vila Real', 'Viseu',
    'Açores', 'Madeira',
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _switchTab(bool toLogin) {
    if (_isLogin == toLogin) return;
    setState(() {
      _isLogin = toLogin;
      _errorMessage = null;
    });
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca. Use ao menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return e.message ?? 'Ocorreu um erro de autenticação.';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        final UserModel? user = await _authController.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (user != null) {
          Navigator.of(context).pop();
        }
      } else {
        final UserModel? user = await _authController.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          city: _selectedCity ?? '',
        );
        if (user != null) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is FirebaseAuthException
            ? _mapFirebaseError(e)
            : 'Não foi possível concluir. Tente novamente.';
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
          // Glow decorativo no topo, dá profundidade sem poluir
          Positioned(
            top: -120,
            left: -60,
            child: _Glow(color: _Palette.primary.withOpacity(0.25), size: 280),
          ),
          Positioned(
            top: 60,
            right: -80,
            child: _Glow(color: _Palette.primaryDark.withOpacity(0.18), size: 220),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              _Logo(),
                              const SizedBox(height: 28),
                              Text(
                                _isLogin ? 'Bem-vindo de volta' : 'Crie a sua conta',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _Palette.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLogin
                                    ? 'Entre para continuar de onde parou.'
                                    : 'Leva menos de um minuto para começar.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 28),
                              _TabSwitcher(isLogin: _isLogin, onChanged: _switchTab),
                              const SizedBox(height: 24),

                              if (_errorMessage != null) ...[
                                _ErrorBanner(message: _errorMessage!),
                                const SizedBox(height: 16),
                              ],

                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOut,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: _isLogin ? _loginFields() : _registerFields(),
                                ),
                              ),

                              const SizedBox(height: 8),
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _Palette.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    child: const Text(
                                      'Esqueceu a senha?',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),
                              _PrimaryButton(
                                label: _isLogin ? 'Entrar' : 'Criar conta',
                                isLoading: _isLoading,
                                onPressed: _submit,
                              ),

                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin ? 'Não tem conta?' : 'Já tem conta?',
                                    style: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () => _switchTab(!_isLogin),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _Palette.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    child: Text(
                                      _isLogin ? 'Registre-se' : 'Faça login',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  List<Widget> _loginFields() {
    return [
      _AppTextField(
        key: const ValueKey('login-email'),
        controller: _emailController,
        label: 'E-mail',
        icon: Icons.alternate_email_rounded,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Informe o seu e-mail';
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'E-mail inválido';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _AppTextField(
        key: const ValueKey('login-password'),
        controller: _passwordController,
        label: 'Senha',
        icon: Icons.lock_outline_rounded,
        obscureText: !_isPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _Palette.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Informe a sua senha' : null,
      ),
    ];
  }

  List<Widget> _registerFields() {
    return [
      _AppTextField(
        key: const ValueKey('reg-name'),
        controller: _nameController,
        label: 'Nome completo',
        icon: Icons.person_outline_rounded,
        textCapitalization: TextCapitalization.words,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o seu nome' : null,
      ),
      const SizedBox(height: 14),
      _AppTextField(
        key: const ValueKey('reg-email'),
        controller: _emailController,
        label: 'E-mail',
        icon: Icons.alternate_email_rounded,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Informe o seu e-mail';
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'E-mail inválido';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _AppTextField(
        key: const ValueKey('reg-phone'),
        controller: _phoneController,
        label: 'Telemóvel',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Informe o seu número';
          if (!RegExp(r'^\d{9}$').hasMatch(v.trim())) return 'Deve ter 9 dígitos';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _CityDropdown(
        cities: _cities,
        selected: _selectedCity,
        onChanged: (v) => setState(() => _selectedCity = v),
        validator: (v) => v == null ? 'Selecione a sua cidade' : null,
      ),
      const SizedBox(height: 14),
      _AppTextField(
        key: const ValueKey('reg-password'),
        controller: _passwordController,
        label: 'Senha',
        icon: Icons.lock_outline_rounded,
        obscureText: !_isPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _Palette.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Informe uma senha';
          if (v.length < 6) return 'Mínimo de 6 caracteres';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _AppTextField(
        key: const ValueKey('reg-confirm-password'),
        controller: _confirmPasswordController,
        label: 'Confirmar senha',
        icon: Icons.lock_outline_rounded,
        obscureText: !_isConfirmPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _Palette.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirme a sua senha';
          if (v != _passwordController.text) return 'As senhas não coincidem';
          return null;
        },
      ),
    ];
  }
}

// ---------- Componentes visuais reutilizáveis ----------

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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
          errorBuilder: (_, __, ___) => const Icon(Icons.flutter_dash, color: _Palette.primary, size: 64),
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  const _TabSwitcher({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: segmentWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _Palette.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _TabLabel(text: 'Entrar', selected: isLogin, onTap: () => onChanged(true)),
                  _TabLabel(text: 'Registrar', selected: !isLogin, onTap: () => onChanged(false)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _TabLabel({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: selected ? Colors.white : _Palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(
              message,
              style: const TextStyle(color: _Palette.error, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: _Palette.textPrimary, fontSize: 15),
      cursorColor: _Palette.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _Palette.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final List<String> cities;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _CityDropdown({
    required this.cities,
    required this.selected,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _Palette.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textSecondary),
      style: const TextStyle(color: _Palette.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Cidade',
        labelStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
        prefixIcon: const Icon(Icons.location_on_outlined, color: _Palette.textSecondary, size: 20),
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
        errorStyle: const TextStyle(color: _Palette.error, fontSize: 12),
      ),
      items: cities
          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
          .toList(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.primary,
          disabledBackgroundColor: _Palette.primary.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(Colors.black.withOpacity(0.08)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                ),
        ),
      ),
    );
  }
}