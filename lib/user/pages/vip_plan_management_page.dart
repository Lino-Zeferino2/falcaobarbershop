import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/auth_controller.dart';
import '../../admin/model/vip_subscription_model.dart';
import '../../admin/model/vip_plan_model.dart';
import '../../admin/controller/admin_controller.dart';

class VipPlanManagementPage extends StatefulWidget {
  final VipSubscriptionModel subscription;

  const VipPlanManagementPage({super.key, required this.subscription});

  @override
  State<VipPlanManagementPage> createState() => _VipPlanManagementPageState();
}

class _VipPlanManagementPageState extends State<VipPlanManagementPage> {
  final AdminController _adminController = AdminController();
  VipPlanModel? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    try {
      _plan = await _adminController.getVipPlanById(widget.subscription.planoId);
    } catch (e) {
      print('Error loading plan details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Plano VIP'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
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
                                Icon(
                                  widget.subscription.status == 'ativo' ? Icons.check_circle : Icons.pending,
                                  color: widget.subscription.status == 'ativo' ? Colors.green : Colors.orange,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.subscription.status == 'ativo' ? 'Plano Ativo' : 'Pendente de Pagamento',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Plano: ${widget.subscription.planoNome}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Valor Mensal: €${widget.subscription.valorMensal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Data de Subscrição: ${DateFormat('dd/MM/yyyy').format(widget.subscription.dataSubscricao)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.subscription.status == 'ativo')
                              Text(
                                'Próxima Renovação: ${DateFormat('dd/MM/yyyy').format(widget.subscription.dataSubscricao.add(const Duration(days: 30)))}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Benefits Card
                    if (_plan != null)
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
                              const Text(
                                'Benefícios do Plano:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._plan!.benefits.map((benefit) => Padding(
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

                    const SizedBox(height: 24),

                    // Info Card
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
                            const Text(
                              'Informações Importantes:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '• O plano é renovado automaticamente a cada 30 dias\n• Você pode cancelar a qualquer momento\n• Para alterações, entre em contato com a barbearia',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Button
                    if (widget.subscription.status == 'pendente_pagamento')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF2A2A2A),
                                title: const Text(
                                  'Cancelar Subscrição',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Tem certeza que deseja cancelar esta subscrição? Esta ação não pode ser desfeita.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Voltar', style: TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Cancelar Subscrição'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              try {
                                await _adminController.cancelVipSubscription(widget.subscription.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Subscrição cancelada com sucesso.'),
                                  ),
                                );
                                Navigator.of(context).pop(); // Go back
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao cancelar subscrição: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar Subscrição',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
