import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedCity;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _cityError;

  final List<String> portugueseCities = [
    'Aveiro',
    'Beja',
    'Braga',
    'Bragança',
    'Castelo Branco',
    'Coimbra',
    'Évora',
    'Faro',
    'Guarda',
    'Leiria',
    'Lisboa',
    'Portalegre',
    'Porto',
    'Santarém',
    'Setúbal',
    'Viana do Castelo',
    'Vila Real',
    'Viseu',
    'Açores',
    'Madeira',
  ];

  Future<void> _validateAndRegister() async {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _cityError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Nome é obrigatório';
      }

      if (_phoneController.text.trim().isEmpty) {
        _phoneError = 'Número é obrigatório';
      } else if (!RegExp(r'^\d{9}$').hasMatch(_phoneController.text.trim())) {
        _phoneError = 'Número deve ter 9 dígitos';
      }

      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Email é obrigatório';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
        _emailError = 'Email inválido';
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Senha é obrigatória';
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Senha deve ter pelo menos 6 caracteres';
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'Confirmação de senha é obrigatória';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = 'Senhas não coincidem';
      }

      if (_selectedCity == null) {
        _cityError = 'Cidade é obrigatória';
      }
    });

    if (_nameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _cityError == null) {
      setState(() => _isLoading = true);

      try {
        UserModel? newUser = await _authController.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          city: _selectedCity!,
        );

        if (newUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro realizado com sucesso!')),
          );
          Navigator.of(context).pop(); // Go back to login
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no registro: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_falcao.png', height: 80),
                const SizedBox(height: 20),
                const Text(
                  'Crie sua conta!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Preencha os dados abaixo para se registrar.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _nameError,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Número',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _phoneError,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _emailError,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'Sua Cidade',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _cityError,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: portugueseCities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _passwordError,
                    errorStyle: const TextStyle(color: Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                    errorText: _confirmPasswordError,
                    errorStyle: const TextStyle(color: Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                      onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Já tem conta? Entre', style: TextStyle(color: Color(0xFFB22222))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
