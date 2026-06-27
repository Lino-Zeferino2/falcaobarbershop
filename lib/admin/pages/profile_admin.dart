import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user/model/user_model.dart';
import '../../user/controller/auth_controller.dart';
import '../../user/pages/home_user.dart';
import '../../firestore_instance.dart';

class ProfileAdmin extends StatefulWidget {
  const ProfileAdmin({super.key});

  @override
  State<ProfileAdmin> createState() => _ProfileAdminState();
}

class _ProfileAdminState extends State<ProfileAdmin> {
  final AuthController _authController = AuthController();
  final FirebaseFirestore _firestore = firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _adminData;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _selectedImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('clientes').doc(user.uid).get();
        if (userDoc.exists) {
          _adminData = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          DocumentSnapshot oldUserDoc = await _firestore.collection('users').doc(user.uid).get();
          if (oldUserDoc.exists) {
            _adminData = UserModel.fromMap(oldUserDoc.data() as Map<String, dynamic>);
          }
        }
        if (_adminData != null) {
          _nameController.text = _adminData!.name;
          _emailController.text = _adminData!.email;
          _phoneController.text = _adminData!.phone;
          _cityController.text = _adminData!.city;
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alteração de foto não permitida para administradores')),
    );
  }

  Future<void> _saveChanges() async {
    if (_adminData == null) return;

    try {
      // Update Firestore
      await _firestore.collection('clientes').doc(_adminData!.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'city': _cityController.text,
      });

      // TODO: Update email if changed - requires reauthentication
      // if (_emailController.text != _adminData!.email) {
      //   await _auth.currentUser?.updateEmail(_emailController.text);
      // }

      setState(() {
        _isEditing = false;
        _adminData = _adminData!.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          city: _cityController.text,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool _isCurrentPasswordVisible = false;
    bool _isNewPasswordVisible = false;
    bool _isConfirmPasswordVisible = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Alterar Senha', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha Atual',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a senha atual')),
                  );
                  return;
                }
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a nova senha')),
                  );
                  return;
                }
                if (confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, confirme a nova senha')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('As senhas não coincidem')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
                  );
                  return;
                }
                if (currentPasswordController.text == newPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A nova senha deve ser diferente da atual')),
                  );
                  return;
                }

                try {
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    // Reauthenticate
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);

                    // Update password
                    await user.updatePassword(newPasswordController.text);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Senha alterada com sucesso')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  String errorMessage = 'Erro ao alterar senha: $e';
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'invalid-credential':
                        errorMessage = 'Credenciais incorretas. Verifique sua senha atual.';
                        break;
                      case 'weak-password':
                        errorMessage = 'A nova senha é muito fraca.';
                        break;
                      case 'requires-recent-login':
                        errorMessage = 'Reautenticação necessária. Faça login novamente.';
                        break;
                      default:
                        errorMessage = 'Erro de autenticação: ${e.message}';
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
              ),
              child: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeEmail() async {
    final currentPasswordController = TextEditingController();
    final newEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Alterar E-mail', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Senha Atual',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB22222)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Novo E-mail',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB22222)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmailController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-mail inválido')),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user != null && user.email != null) {
                  // Reauthenticate
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.reload();

                  // Update email
                  await user.verifyBeforeUpdateEmail(newEmailController.text);

                  // Update Firestore
                  await _firestore.collection('clientes').doc(user.uid).update({
                    'email': newEmailController.text,
                  });

                  setState(() {
                    _adminData = _adminData!.copyWith(email: newEmailController.text);
                    _emailController.text = newEmailController.text;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-mail alterado com sucesso')),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                String errorMessage = 'Erro ao alterar e-mail: $e';
                if (e is FirebaseAuthException) {
                  switch (e.code) {
                    case 'invalid-credential':
                      errorMessage = 'Credenciais incorretas. Verifique sua senha atual.';
                      break;
                    case 'email-already-in-use':
                      errorMessage = 'Este e-mail já está em uso.';
                      break;
                    case 'invalid-email':
                      errorMessage = 'E-mail inválido.';
                      break;
                    case 'requires-recent-login':
                      errorMessage = 'Reautenticação necessária. Faça login novamente.';
                      break;
                    default:
                      errorMessage = 'Erro de autenticação: ${e.message}';
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
            ),
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _authController.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeUser()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Perfil do Administrador', style: TextStyle(color: Colors.white)),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/images/default_admin.jpg'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _adminData?.name ?? 'Nome não disponível',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    'Administrador da Falcão Barbearia',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Main Info
            Card(
              color: const Color(0xFF1A1A1A),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoField('Nome completo', _nameController, _isEditing),
                    const Divider(color: Colors.white24),
                    _buildInfoField('Email', _emailController, _isEditing && false), // Email not editable here
                    const Divider(color: Colors.white24),
                    _buildInfoField('Telefone', _phoneController, _isEditing),
                    const Divider(color: Colors.white24),
                    _buildInfoField('Cidade', _cityController, _isEditing),
                    const Divider(color: Colors.white24),
                    _buildReadOnlyField('Data de criação', _adminData?.createdAt?.toString().split(' ')[0] ?? 'N/A'),
                    const Divider(color: Colors.white24),
                    _buildReadOnlyField('Função', _adminData?.role ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Settings
            const Text('Configurações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF1A1A1A),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.white),
                    title: const Text('Alterar senha', style: TextStyle(color: Colors.white)),
                    onTap: _changePassword,
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.white),
                    title: const Text('Alterar e-mail', style: TextStyle(color: Colors.white)),
                    onTap: _changeEmail,
                  ),

                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Terminar sessão', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, bool editable) {
    return TextField(
      controller: controller,
      enabled: editable,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(value, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }


}


