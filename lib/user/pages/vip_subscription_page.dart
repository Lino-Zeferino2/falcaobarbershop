// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controller/auth_controller.dart';
import '../../admin/model/vip_plan_model.dart';
import '../../admin/model/vip_subscription_model.dart';
import '../../admin/controller/admin_controller.dart';
import 'login_page.dart';
import 'vip_plan_management_page.dart';

class VipSubscriptionPage extends StatefulWidget {
  final VipPlanModel plan;

  const VipSubscriptionPage({super.key, required this.plan});

  @override
  State<VipSubscriptionPage> createState() => _VipSubscriptionPageState();
}

class _VipSubscriptionPageState extends State<VipSubscriptionPage> {
  final AuthController _authController = AuthController();
  final AdminController _adminController = AdminController();
  bool _isLoading = false;
  User? _currentUser;
  VipSubscriptionModel? _userSubscription;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _loadUserSubscription();
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      if (user != null) {
        _loadUserSubscription();
      }
    });
  }

  Future<void> _loadUserSubscription() async {
    setState(() => _isLoadingSubscription = true);
    try {
      if (_currentUser != null) {
        _userSubscription = await _authController.getCurrentUserVipSubscription();
      } else {
        _userSubscription = null;
      }
    } catch (e) {
      print('Error loading user subscription: $e');
      _userSubscription = null;
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  Future<void> _confirmSubscription() async {
    if (_currentUser == null) {
      // Show login modal
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Autenticação Necessária',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Para subscrever um plano VIP, precisa de uma conta. Faça login ou crie uma conta em poucos segundos.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
                _checkAuthState(); // Refresh auth state
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
              ),
              child: const Text('Fazer Login'),
            ),
          ],
        ),
      );
      return;
    }

    // Show subscription confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Confirmar Subscrição - ${widget.plan.name}',
          style:  TextStyle(color: Colors.white, fontWeight:   FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valor mensal: €${widget.plan.price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Benefícios incluídos:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.plan.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFFB22222), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Política de cancelamento:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Pode cancelar a qualquer momento\n• Válido por 30 dias após ativação\n• O pagamento é feito diretamente na barbearia',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'O pagamento será feito diretamente na barbearia. Após o pagamento, o seu plano será ativado pelo administrador.',
                  style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
            ),
            child: const Text('Confirmar Subscrição'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _authController.createVipSubscription(
          planoId: widget.plan.id,
          planoNome: widget.plan.name,
          valorMensal: widget.plan.price,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obrigado! O seu pedido de subscrição foi registado. Dirija-se à barbearia para concluir o pagamento e ativar o plano.'),
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.of(context).pop(); // Go back
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar subscrição: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscrição VIP - ${widget.plan.name}'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
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
                // Current Subscription Status (if exists)
                if (_isLoadingSubscription)
                  const CircularProgressIndicator(color: Color(0xFFB22222))
                else if (_userSubscription != null)
                  Card(
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFB22222),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Plano Ativo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Plano: ${_userSubscription!.planoNome}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${_userSubscription!.status == 'ativo' ? 'Ativo' : _userSubscription!.status == 'pendente_pagamento' ? 'Pendente de Pagamento' : _userSubscription!.status}',
                            style: TextStyle(
                              color: _userSubscription!.status == 'ativo' ? Colors.green : Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data de Subscrição: ${DateFormat('dd/MM/yyyy').format(_userSubscription!.dataSubscricao)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (_userSubscription!.status == 'ativo')
                            Text(
                              'Próxima Renovação: ${DateFormat('dd/MM/yyyy').format(_userSubscription!.dataSubscricao.add(const Duration(days: 30)))}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Você já possui um plano VIP ativo. Se deseja alterar o plano, entre em contato com a barbearia.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Plan Details Card
                  Card(
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.plan.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '€${widget.plan.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFB22222),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'por mês',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Benefícios:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.plan.benefits.map((benefit) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFB22222),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Subscription Button
                if (_userSubscription == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Subscrever Agora',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_userSubscription!.status == 'ativo') {
                          // Navigate to management page for active plans
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VipPlanManagementPage(subscription: _userSubscription!),
                            ),
                          );
                        } else if (_userSubscription!.status == 'pendente_pagamento') {
                          // Show modal with options for pending payment
                          final action = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2A2A2A),
                              title: const Text(
                                'Subscrição Pendente',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Sua subscrição está pendente de pagamento. O que deseja fazer?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop('close'),
                                  child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop('cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancelar Subscrição'),
                                ),
                              ],
                            ),
                          );

                          if (action == 'cancel') {
                            try {
                              await _adminController.cancelVipSubscription(_userSubscription!.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Subscrição cancelada com sucesso.'),
                                ),
                              );
                              // Refresh subscription status
                              _loadUserSubscription();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao cancelar subscrição: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userSubscription!.status == 'ativo' ? Colors.green : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _userSubscription!.status == 'ativo' ? 'Gerenciar Plano VIP' : 'Subscrição Pendente',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Text(
                  'Ao confirmar, será criado um pedido de subscrição que será ativado após o pagamento na barbearia.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
