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
    // Set up the stream listener once in the constructor
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) async {
      print('userStream: Firebase user changed: ${firebaseUser?.uid}');
      if (firebaseUser != null) {
        try {
          // Primeiro verificar se é um admin
          try {
            DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(firebaseUser.uid).get();
            if (adminDoc.exists && adminDoc.data() != null) {
              final data = adminDoc.data() as Map<String, dynamic>;
              // Forçar role 'admin' para admins
              data['role'] = 'admin';
              print('userStream: Found admin user with role: ${data['role']}');
              UserModel user = UserModel.fromMap(data);
              if (!_userController.isClosed) {
                _userController.add(user);
              }
              return;
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'permission-denied') {
              print('userStream: Permission denied for admins collection, skipping...');
            } else {
              rethrow;
            }
          }

          // Se não é admin, verificar se é um profissional (prioridade para barbeiros)
          try {
            DocumentSnapshot profDoc = await _firestore.collection('profissionais').doc(firebaseUser.uid).get();
            if (profDoc.exists && profDoc.data() != null) {
              final data = profDoc.data() as Map<String, dynamic>;
              // Forçar role 'barbeiro' para profissionais
              data['role'] = 'barbeiro';
              print('userStream: Found professional user with role: ${data['role']}');
              UserModel user = UserModel.fromMap(data);
              if (!_userController.isClosed) {
                _userController.add(user);
              }
              return;
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'permission-denied') {
              print('userStream: Permission denied for profissionais collection, skipping...');
            } else {
              rethrow;
            }
          }

          // Se não é profissional, tentar 'clientes'
          try {
            DocumentSnapshot userDoc = await _firestore.collection('clientes').doc(firebaseUser.uid).get();
            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data() as Map<String, dynamic>;
              // Ensure role is set, default to 'cliente' if not present
              if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
                data['role'] = 'cliente';
              }
              print('userStream: Found client user with role: ${data['role']}');
              UserModel user = UserModel.fromMap(data);
              if (!_userController.isClosed) {
                _userController.add(user);
              }
              return;
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'permission-denied') {
              print('userStream: Permission denied for clientes collection, skipping...');
            } else {
              rethrow;
            }
          }

          // Tentar na coleção 'users' para compatibilidade com dados antigos
          try {
            DocumentSnapshot oldUserDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (oldUserDoc.exists && oldUserDoc.data() != null) {
              final data = oldUserDoc.data() as Map<String, dynamic>;
              // Ensure role is set, default to 'cliente' if not present
              if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
                data['role'] = 'cliente';
              }
              print('userStream: Found legacy user with role: ${data['role']}');
              UserModel user = UserModel.fromMap(data);
              if (!_userController.isClosed) {
                _userController.add(user);
              }
              return;
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'permission-denied') {
              print('userStream: Permission denied for users collection, skipping...');
            } else {
              rethrow;
            }
          }

          print('userStream: No user document found for uid: ${firebaseUser.uid}');
          if (!_userController.isClosed) {
            _userController.add(null);
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

  // Registrar usuário
  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    try {
      // Criar usuário no Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Criar modelo do usuário
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        city: city,
        role: 'cliente', // Sempre 'cliente' por padrão
        createdAt: DateTime.now(),
      );

      // Salvar no Firestore
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
      _currentPassword = password; // Store current password for reauthentication

      // Buscar dados do usuário no Firestore - tentar primeiro 'admins', depois 'profissionais' (prioridade para barbeiros), depois 'clientes', depois 'users'
      print('AuthController: Checking admins collection...');
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(userCredential.user!.uid).get();
        if (adminDoc.exists) {
          final data = adminDoc.data() as Map<String, dynamic>;
          if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
            data['role'] = 'admin';
          }
      print('AuthController: Found user in admins collection with role: ${data['role']}');
          UserModel user = UserModel.fromMap(data);
          // Store admin credentials for relogin after creating professionals
          storeAdminCredentials(email, password);

          // Save FCM token for push notifications (only for web)
          if (kIsWeb) {
            try {
              await PushNotificationService().saveTokenForCurrentUser();
              print('AuthController: FCM token saved for admin user');
            } catch (e) {
              print('AuthController: Error saving FCM token: $e');
            }
          }

          print('AuthController: Forcing stream update after login...');
          // Forçar atualização do stream emitindo o usuário atual
          _userController.add(user);
          return user;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          print('AuthController: Permission denied for admins collection, skipping...');
        } else {
          rethrow;
        }
      }

      // Se não encontrou em admins, tentar 'profissionais'
      print('AuthController: Checking profissionais collection...');
      try {
        DocumentSnapshot profDoc = await _firestore.collection('profissionais').doc(userCredential.user!.uid).get();
        if (profDoc.exists) {
          final data = profDoc.data() as Map<String, dynamic>;
          if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
            data['role'] = 'barbeiro';
          }
          print('AuthController: Found user in profissionais collection with role: ${data['role']}');
          UserModel user = UserModel.fromMap(data);

          // Save FCM token for push notifications (only for web)
          if (kIsWeb) {
            try {
              await PushNotificationService().saveTokenForCurrentUser();
              print('AuthController: FCM token saved for professional user');
            } catch (e) {
              print('AuthController: Error saving FCM token: $e');
            }
          }

          print('AuthController: Forcing stream update after login...');
          // Forçar atualização do stream emitindo o usuário atual
          _userController.add(user);
          return user;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          print('AuthController: Permission denied for profissionais collection, skipping...');
        } else {
          rethrow;
        }
      }

      // Se não encontrou em profissionais, tentar 'clientes'
      print('AuthController: Checking clientes collection...');
      try {
        DocumentSnapshot userDoc = await _firestore.collection('clientes').doc(userCredential.user!.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
            data['role'] = 'cliente';
          }
          print('AuthController: Found user in clientes collection with role: ${data['role']}');
          UserModel user = UserModel.fromMap(data);

          // Save FCM token for push notifications (only for web)
          if (kIsWeb) {
            try {
              await PushNotificationService().saveTokenForCurrentUser();
              print('AuthController: FCM token saved for client user');
            } catch (e) {
              print('AuthController: Error saving FCM token: $e');
            }
          }

          print('AuthController: Forcing stream update after login...');
          // Forçar atualização do stream emitindo o usuário atual
          _userController.add(user);
          return user;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          print('AuthController: Permission denied for clientes collection, skipping...');
        } else {
          rethrow;
        }
      }

      // Tentar na coleção 'users' para compatibilidade com dados antigos
      print('AuthController: Checking users collection...');
      try {
        DocumentSnapshot oldUserDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (oldUserDoc.exists) {
          final data = oldUserDoc.data() as Map<String, dynamic>;
          if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
            data['role'] = 'cliente';
          }
          print('AuthController: Found user in users collection with role: ${data['role']}');
          UserModel user = UserModel.fromMap(oldUserDoc.data() as Map<String, dynamic>);
          print('AuthController: Forcing stream update after login...');
          // Forçar atualização do stream emitindo o usuário atual
          _userController.add(user);
          return user;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          print('AuthController: Permission denied for users collection, skipping...');
        } else {
          rethrow;
        }
      }

      print('AuthController: User data not found in any collection');
      throw 'Dados do usuário não encontrados';
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
        // Limpar credenciais se falhar
        _adminEmail = null;
        _adminPassword = null;
      }
    }
  }

  // Obter usuário atual
  Future<UserModel?> getCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        // Tentar primeiro 'admins', depois 'profissionais', depois 'clientes', depois 'users'
        try {
          DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(firebaseUser.uid).get();
          if (adminDoc.exists) {
            final data = adminDoc.data() as Map<String, dynamic>;
            if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
              data['role'] = 'admin';
            }
            return UserModel.fromMap(data);
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'permission-denied') {
            print('getCurrentUser: Permission denied for admins collection, skipping...');
          } else {
            rethrow;
          }
        }

        // Tentar na coleção 'profissionais'
        try {
          DocumentSnapshot profDoc = await _firestore.collection('profissionais').doc(firebaseUser.uid).get();
          if (profDoc.exists) {
            final data = profDoc.data() as Map<String, dynamic>;
            if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
              data['role'] = 'barbeiro';
            }
            return UserModel.fromMap(data);
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'permission-denied') {
            print('getCurrentUser: Permission denied for profissionais collection, skipping...');
          } else {
            rethrow;
          }
        }

        // Tentar na coleção 'clientes'
        try {
          DocumentSnapshot userDoc = await _firestore.collection('clientes').doc(firebaseUser.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
              data['role'] = 'cliente';
            }
            return UserModel.fromMap(data);
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'permission-denied') {
            print('getCurrentUser: Permission denied for clientes collection, skipping...');
          } else {
            rethrow;
          }
        }

        // Tentar na coleção 'users' para compatibilidade com dados antigos
        try {
          DocumentSnapshot oldUserDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (oldUserDoc.exists) {
            final data = oldUserDoc.data() as Map<String, dynamic>;
            if (!data.containsKey('role') || data['role'] == null || data['role'].toString().isEmpty) {
              data['role'] = 'cliente';
            }
            return UserModel.fromMap(data);
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'permission-denied') {
            print('getCurrentUser: Permission denied for users collection, skipping...');
          } else {
            rethrow;
          }
        }
      } catch (e) {
        print('Error getting current user: $e');
        throw e;
      }
    }
    return null;
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
        // Sort by dataSubscricao descending to get the most recent
        final sortedDocs = query.docs
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aDate = (aData['dataSubscricao'] as Timestamp).toDate();
            final bDate = (bData['dataSubscricao'] as Timestamp).toDate();
            return bDate.compareTo(aDate); // Descending order
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

      // Reauthenticate user before changing password
      if (_currentPassword != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPassword!,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Change password
      await user.updatePassword(newPassword);

      // Update stored password
      _currentPassword = newPassword;

      print('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao alterar senha: $e';
    }
  }
}
