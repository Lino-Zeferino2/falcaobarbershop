// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../model/vip_plan_model.dart';
import '../model/vip_subscription_model.dart';

class VipOffersPage extends StatefulWidget {
  const VipOffersPage({super.key});

  @override
  State<VipOffersPage> createState() => _VipOffersPageState();
}

class _VipOffersPageState extends State<VipOffersPage> with SingleTickerProviderStateMixin {
  final AdminController _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subscriptionSearchController = TextEditingController();
  String _searchQuery = '';
  String _subscriptionSearchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _subscriptionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestão de Ofertas VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showVipPlanDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    isMobile ? ' Novo' : ' Adicionar Novo Plano',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // TabBar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Planos'),
                Tab(text: 'Assinaturas'),
              ],
              labelColor: const Color(0xFFB22222),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFB22222),
            ),
            const SizedBox(height: 24),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansTab(),
                  _buildSubscriptionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansTab() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        // Search
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar planos...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),

        // Plans List
        Expanded(
          child: StreamBuilder<List<VipPlanModel>>(
            stream: _adminController.getAllVipPlans(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final allPlans = snapshot.data ?? [];
              final filteredPlans = allPlans.where((plan) {
                return plan.name.toLowerCase().contains(_searchQuery) ||
                       plan.description.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredPlans.isEmpty) {
                return const Center(
                  child: Text(
                    'Sem planos cadastrados',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredPlans.length,
                itemBuilder: (context, index) {
                  final plan = filteredPlans[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPlanCard(plan),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsTab() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        // Search
        TextField(
          controller: _subscriptionSearchController,
          onChanged: (value) {
            setState(() {
              _subscriptionSearchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar assinaturas...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _subscriptionSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _subscriptionSearchController.clear();
                      setState(() {
                        _subscriptionSearchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),

        // Subscriptions List
        Expanded(
          child: StreamBuilder<List<VipSubscriptionModel>>(
            stream: _adminController.getAllVipSubscriptions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final allSubscriptions = snapshot.data ?? [];
              final filteredSubscriptions = allSubscriptions.where((subscription) {
                return subscription.userId.toLowerCase().contains(_subscriptionSearchQuery) ||
                       subscription.planoNome.toLowerCase().contains(_subscriptionSearchQuery);
              }).toList();

              if (filteredSubscriptions.isEmpty) {
                return const Center(
                  child: Text(
                    'Sem assinaturas cadastradas',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredSubscriptions.length,
                itemBuilder: (context, index) {
                  final subscription = filteredSubscriptions[index];
                  return _buildSubscriptionCard(subscription);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(VipPlanModel plan) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: plan.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.isActive ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              '€${plan.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFB22222),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              plan.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Benefits
            if (plan.benefits.isNotEmpty) ...[
              const Text(
                'Benefícios:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(maxHeight: isMobile ? 80 : 100),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: plan.benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFB22222),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Stats
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                FutureBuilder<int>(
                  future: _adminController.getVipPlanSubscribersCount(plan.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count assinantes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${plan.createdAt.day}/${plan.createdAt.month}/${plan.createdAt.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showVipPlanDialog(plan: plan),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB22222)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(color: Color(0xFFB22222)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteVipPlan(plan.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(VipSubscriptionModel subscription) {
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _adminController.getUserNameById(subscription.userId),
                        builder: (context, snapshot) {
                          final userName = snapshot.data ?? 'Carregando...';
                          return Text(
                            'Cliente: $userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.planoNome,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(subscription.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(subscription.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Iniciado em: ${subscription.dataSubscricao.day}/${subscription.dataSubscricao.month}/${subscription.dataSubscricao.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expira em: ${subscription.dataRenovacao?.day ?? 'N/A'}/${subscription.dataRenovacao?.month ?? 'N/A'}/${subscription.dataRenovacao?.year ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            Text(
              '€${subscription.valorMensal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFB22222),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: subscription.status,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: ['pendente_pagamento', 'ativo', 'cancelado', 'expirado'].map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != subscription.status) {
                        _changeSubscriptionStatus(subscription, newStatus);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendente_pagamento':
        return Colors.yellow;
      case 'ativo':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'expirado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendente_pagamento':
        return 'Pendente de Pagamento';
      case 'ativo':
        return 'Ativa';
      case 'cancelado':
        return 'Cancelada';
      case 'expirado':
        return 'Expirada';
      default:
        return 'Desconhecido';
    }
  }

  Future<void> _changeSubscriptionStatus(VipSubscriptionModel subscription, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Confirmar Alteração',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja alterar o status desta assinatura para "${_getStatusText(newStatus)}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.updateVipSubscriptionStatus(subscription.id, newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status da assinatura alterado para "${_getStatusText(newStatus)}"')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alterar status: $e')),
        );
      }
    }
  }

  void _showVipPlanDialog({VipPlanModel? plan}) {
    final isEditing = plan != null;
    final nameController = TextEditingController(text: plan?.name ?? '');
    final priceController = TextEditingController(text: plan?.price.toString() ?? '');
    final descriptionController = TextEditingController(text: plan?.description ?? '');
    final benefitsController = TextEditingController(text: plan?.benefits.join('\n') ?? '');
    bool isActive = plan?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            isEditing ? 'Editar Plano VIP' : 'Novo Plano VIP',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do plano',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preço (€)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição breve',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: benefitsController,
                  decoration: const InputDecoration(
                    labelText: 'Benefícios (um por linha)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Ativo',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                  activeColor: const Color(0xFFB22222),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveVipPlan(
                isEditing: isEditing,
                planId: plan?.id,
                name: nameController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0.0,
                description: descriptionController.text.trim(),
                benefits: benefitsController.text.split('\n').where((b) => b.trim().isNotEmpty).toList(),
                isActive: isActive,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
              ),
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVipPlan({
    required bool isEditing,
    String? planId,
    required String name,
    required double price,
    required String description,
    required List<String> benefits,
    required bool isActive,
  }) async {
    if (name.isEmpty || price <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    try {
      final vipPlan = VipPlanModel(
        id: planId ?? '',
        name: name,
        price: price,
        description: description,
        benefits: benefits,
        isActive: isActive,
        createdAt: isEditing ? DateTime.now() : DateTime.now(),
      );

      if (isEditing) {
        await _adminController.updateVipPlan(vipPlan);
      } else {
        await _adminController.addVipPlan(vipPlan);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Plano atualizado com sucesso' : 'Plano criado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar plano: $e')),
      );
    }
  }

  Future<void> _deleteVipPlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este plano VIP? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.deleteVipPlan(planId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano excluído com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir plano: $e')),
        );
      }
    }
  }
}
