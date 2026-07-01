// ignore_for_file: use_rethrow_when_possible

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../firestore_instance.dart';
import 'dart:async';
import '../model/user_model.dart';
import '../../admin/model/vip_subscription_model.dart';
import '../../services/push_notification_service.dart';

class AuthController {
  static AuthController? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = firestore;
  final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();
  StreamSubscription<User?>? _authSubscription;

  // Armazenar credenciais do admin para relogin após criação de profissional
  String? _adminEmail;
  String? _adminPassword;
  String? _currentPassword;

  // Singleton pattern
  AuthController._internal() {
    print('AuthController: Creating new instance');
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) async {
      print('userStream: Firebase user changed: ${firebaseUser?.uid}');
      if (firebaseUser != null) {
        try {
          final user = await _resolveUserDocument(firebaseUser.uid);
          if (!_userController.isClosed) {
            _userController.add(user);
          }
        } catch (e) {
          print('Error in userStream: $e');
          if (!_userController.isClosed) {
            _userController.add(null);
          }
        }
      } else {
        print('userStream: Firebase user is null');
        if (!_userController.isClosed) {
          _userController.add(null);
        }
      }
    });
  }

  factory AuthController() {
    _instance ??= AuthController._internal();
    return _instance!;
  }

  // Busca o documento do utilizador — primeiro em 'profissionais' (barbeiros),
  // depois em 'clientes' (onde também vivem os admins, diferenciados pelo
  // campo `role`). 'users' é mantido apenas como fallback legado. Não existe
  // coleção 'admins' neste projeto, por isso não é consultada.
  Future<UserModel?> _resolveUserDocument(String uid) async {
    try {
      DocumentSnapshot profDoc = await _firestore.collection('profissionais').doc(uid).get();
      if (profDoc.exists && profDoc.data() != null) {
        final data = profDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
          data['role'] = 'barbeiro';
        }
        print('AuthController: Found user in profissionais collection with role: ${data['role']}');
        return UserModel.fromMap(data);
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('AuthController: Permission denied for profissionais collection, skipping...');
      } else {
        rethrow;
      }
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('clientes').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
          data['role'] = 'cliente';
        }
        print('AuthController: Found user in clientes collection with role: ${data['role']}');
        return UserModel.fromMap(data);
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('AuthController: Permission denied for clientes collection, skipping...');
      } else {
        rethrow;
      }
    }

    // Fallback para dados antigos que ainda possam existir em 'users'.
    try {
      DocumentSnapshot oldUserDoc = await _firestore.collection('users').doc(uid).get();
      if (oldUserDoc.exists && oldUserDoc.data() != null) {
        final data = oldUserDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
          data['role'] = 'cliente';
        }
        print('AuthController: Found legacy user in users collection with role: ${data['role']}');
        return UserModel.fromMap(data);
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('AuthController: Permission denied for users collection, skipping...');
      } else {
        rethrow;
      }
    }

    print('AuthController: User document not found for uid: $uid');
    return null;
  }

  // Registrar usuário
  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        city: city,
        role: 'cliente', // Sempre 'cliente' por padrão
        createdAt: DateTime.now(),
      );

      await _firestore.collection('clientes').doc(newUser.uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao registrar usuário: $e';
    }
  }

  // Login do usuário
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthController: Starting login process for email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('AuthController: Firebase auth successful for uid: ${userCredential.user!.uid}');
      _currentPassword = password;

      final user = await _resolveUserDocument(userCredential.user!.uid);

      if (user == null) {
        print('AuthController: User data not found in any collection');
        throw 'Dados do usuário não encontrados';
      }

      // Guarda as credenciais quando for admin, para permitir relogin depois
      // de criar profissionais.
      if (user.role == 'admin') {
        storeAdminCredentials(email, password);
      }

      // Save FCM token for push notifications (only for web)
      if (kIsWeb) {
        try {
          await PushNotificationService().saveTokenForCurrentUser();
          print('AuthController: FCM token saved for user role ${user.role}');
        } catch (e) {
          print('AuthController: Error saving FCM token: $e');
        }
      }

      print('AuthController: Forcing stream update after login...');
      _userController.add(user);
      return user;
    } on FirebaseAuthException catch (e) {
      print('AuthController: Firebase auth error: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('AuthController: Login error: $e');
      throw 'Erro ao fazer login: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Método para armazenar credenciais do admin
  void storeAdminCredentials(String email, String password) {
    _adminEmail = email;
    _adminPassword = password;
  }

  // Método para relogar como admin após criação de profissional
  Future<void> reloginAsAdmin() async {
    if (_adminEmail != null && _adminPassword != null) {
      try {
        print('AuthController: Signing out current user before relogin');
        await _auth.signOut();
        print('AuthController: Relogging in as admin with email: $_adminEmail');
        await loginUser(email: _adminEmail!, password: _adminPassword!);
        print('AuthController: Successfully relogged in as admin');
      } catch (e) {
        print('AuthController: Failed to relogin as admin: $e');
        _adminEmail = null;
        _adminPassword = null;
      }
    }
  }

  // Obter usuário atual
  Future<UserModel?> getCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    try {
      return await _resolveUserDocument(firebaseUser.uid);
    } catch (e) {
      print('Error getting current user: $e');
      rethrow;
    }
  }

  // Stream do usuário atual
  Stream<UserModel?> get userStream {
    return _userController.stream;
  }

  // Criar subscrição VIP
  Future<void> createVipSubscription({
    required String planoId,
    required String planoNome,
    required double valorMensal,
  }) async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw 'Usuário não autenticado';
      }

      final subscription = VipSubscriptionModel(
        id: '', // Será gerado pelo Firestore
        userId: firebaseUser.uid,
        planoId: planoId,
        planoNome: planoNome,
        valorMensal: valorMensal,
        status: 'pendente_pagamento',
        dataSubscricao: DateTime.now(),
      );

      await _firestore.collection('subscricoes_vip').add(subscription.toMap());
    } catch (e) {
      throw 'Erro ao criar subscrição: $e';
    }
  }

  // Obter subscrição VIP do usuário atual
  Future<VipSubscriptionModel?> getCurrentUserVipSubscription() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final query = await _firestore
          .collection('subscricoes_vip')
          .where('userId', isEqualTo: firebaseUser.uid)
          .get();

      if (query.docs.isNotEmpty) {
        final sortedDocs = query.docs
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aDate = (aData['dataSubscricao'] as Timestamp).toDate();
            final bDate = (bData['dataSubscricao'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });

        return VipSubscriptionModel.fromMap(sortedDocs.first.id, sortedDocs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting current user VIP subscription: $e');
      return null;
    }
  }

  // Reset de senha
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao enviar email de recuperação: $e';
    }
  }

  // Tratamento de erros do Firebase Auth
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas de login. Tente novamente mais tarde.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _authSubscription?.cancel();
    _userController.close();
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado';
      }

      if (_currentPassword != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPassword!,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.updatePassword(newPassword);
      _currentPassword = newPassword;

      print('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao alterar senha: $e';
    }
  }
}