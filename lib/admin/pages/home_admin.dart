// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names, unused_element, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../firestore_instance.dart';
import '../controller/admin_controller.dart';
import '../model/appointment_model.dart';
import '../model/profissional_model.dart';
import 'profile_admin.dart';

import 'barbearias_page.dart';
import 'profissionais_page.dart';
import 'clientes_page.dart';
import 'retencao_clientes_page.dart';
import 'vip_offers_page.dart';
import 'settings_page.dart';
import 'notifications_page.dart';
import 'posts_page.dart';
import 'financial_stats_page.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final AdminController _adminController = AdminController();
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardStats;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sections = [
    'Dashboard',
    'Agendamentos',
    'Estatísticas Financeiras',
    'Profissionais',
    'Ofertas VIP',
    'Clientes',
    'Retenção Cliente',
    'Barbearia',
    'Posts',
    'Configurações',
  ];

  final List<IconData> _sectionIcons = [
    Icons.dashboard,
    Icons.calendar_today,
    Icons.analytics,
    Icons.people,
    Icons.local_offer,
    Icons.person,
    Icons.person_off,
    Icons.store,
    Icons.post_add,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    final stats = await _adminController.getDashboardStats();
    if (mounted) {
      setState(() {
        _dashboardStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Row(
          children: [
            Image.asset('assets/images/logo_falcao.png', height: 40),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isMobile ? 'Admin' : 'Painel do Administrador',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right:  8),
            child: StreamBuilder<int>(
              stream: _adminController.getUnreadNotificationsCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsPage(
                              onNavigateToAppointments: () {
                                Navigator.of(context).pop(); // Close notifications page
                                setState(() {
                                  _selectedIndex = 1; // Switch to appointments tab
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'perfil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileAdmin()),
                  );
                } else if (value == 'sair') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'perfil', child: Text('Perfil')),
                const PopupMenuItem(value: 'sair', child: Text('Sair')),
              ],
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/default_admin.jpg'),
              ),
            ),
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(_sectionIcons[index], color: Colors.white),
                          title: Text(_sections[index], style: const TextStyle(color: Colors.white)),
                          selected: _selectedIndex == index,
                          selectedTileColor: const Color(0xFFB22222).withOpacity(0.2),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            Navigator.pop(context); // Close drawer
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sair', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      _logout();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar (only show on desktop)
          if (!isMobile)
            Container(
              width: 250,
              color: const Color(0xFF1A1A1A),
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(_sectionIcons[index], color: Colors.white),
                    title: Text(_sections[index], style: const TextStyle(color: Colors.white)),
                    selected: _selectedIndex == index,
                    selectedTileColor: const Color(0xFFB22222).withOpacity(0.2),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          // Content
          Expanded(
            child: Container(
              color: const Color(0xFF0D0D0D),
              padding: EdgeInsets.all(isMobile ? 10 : 20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled by AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildFinancialStats();
      case 3:
        return _buildBarbers();
      case 4:
        return _buildOffers();
      case 5:
        return _buildClients();
      case 6:
        return _buildRetencaoClientes();
      case 7:
        return _buildBarberShop();
      case 8:
        return _buildPosts();
      case 9:
        return _buildSettings();
      default:
        return const Center(child: Text('Seção não encontrada', style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildDashboard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final crossAxisCount = isMobile ? 2 : 4;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _metricCard('💈 Agendamentos Hoje', _dashboardStats?['todayAppointments']?.toString() ?? '0'),
              _metricCard('👥 Clientes Ativos', _dashboardStats?['activeBarbers']?.toString() ?? '0'),
              _metricCard('💵 Receita Estimada (Hoje)', '€${_dashboardStats?['estimatedRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
              _metricCard('✂️ Total de Cortes', _dashboardStats?['totalCuts']?.toString() ?? '0'),
              _metricCard('💰 Receita Total', '€${_dashboardStats?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
          const SizedBox(height: 20),
          // Top Services Chart
          _buildTopServicesChart(),
        ],
      ),
    );
  }

  Widget _buildTopServicesChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminController.getDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.pie_chart, color: Color(0xFFB22222)),
                  SizedBox(width: 8),
                  Text(
                    'Serviços Mais Vendidos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getTopServicesData(),
                builder: (context, servicesSnapshot) {
                  if (servicesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: Color(0xFFB22222)),
                      ),
                    );
                  }

                  final services = servicesSnapshot.data ?? [];
                  if (services.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'Sem dados disponíveis',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  return _buildServicesLegend(services);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesLegend(List<Map<String, dynamic>> services) {
    final total = services.fold<int>(0, (sum, s) => sum + (s['count'] as int));
    
    return Column(
      children: services.take(5).map((service) {
        final count = service['count'] as int;
        final percentage = total > 0 ? (count / total * 100) : 0.0;
        final color = _getServiceColor(services.indexOf(service));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${count}x (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getServiceColor(int index) {
    const colors = [
      Color(0xFFB22222),
      Color(0xFFFF6B6B),
      Color(0xFFFF8E53),
      Color(0xFFFFA07A),
      Color(0xFFFFB6C1),
    ];
    return colors[index % colors.length];
  }

  Future<List<Map<String, dynamic>>> _getTopServicesData() async {
    try {
      final allAppointments = await firestore.collection('agendamentos').get();
      final serviceCount = <String, int>{};

      for (var doc in allAppointments.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final serviceName = data['service'] ?? 'Desconhecido';

        if (status == 'completed') {
          serviceCount[serviceName] = (serviceCount[serviceName] ?? 0) + 1;
        }
      }

      final services = serviceCount.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList();
      
      services.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return services;
    } catch (e) {
      print('Error getting top services: $e');
      return [];
    }
  }


  Widget _metricCard(String title, String value) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Color(0xFFB22222), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointments() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de pesquisa
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar por cliente, serviço ou barbeiro...',
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
        const SizedBox(height: 20),

        // Filtros de status
        if (isMobile)
          DropdownButtonFormField<String>(
            value: _selectedStatusFilter,
            onChanged: (value) {
              setState(() {
                _selectedStatusFilter = value!;
              });
            },
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos')),
              DropdownMenuItem(value: 'pending', child: Text('Pendente')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmado')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
              DropdownMenuItem(value: 'completed', child: Text('Concluído')),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white70,
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 0,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _selectedStatusFilter == 'Todos',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = 'Todos';
                  });
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                checkmarkColor: const Color(0xFFB22222),
                labelStyle: TextStyle(
                  color: _selectedStatusFilter == 'Todos' ? const Color(0xFFB22222) : Colors.white,
                ),
              ),
              FilterChip(
                label: const Text('Pendente'),
                selected: _selectedStatusFilter == 'pending',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = 'pending';
                  });
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                checkmarkColor: const Color(0xFFB22222),
                labelStyle: TextStyle(
                  color: _selectedStatusFilter == 'pending' ? const Color(0xFFB22222) : Colors.white,
                ),
              ),
              FilterChip(
                label: const Text('Confirmado'),
                selected: _selectedStatusFilter == 'confirmed',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = 'confirmed';
                  });
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                checkmarkColor: const Color(0xFFB22222),
                labelStyle: TextStyle(
                  color: _selectedStatusFilter == 'confirmed' ? const Color(0xFFB22222) : Colors.white,
                ),
              ),
              FilterChip(
                label: const Text('Cancelado'),
                selected: _selectedStatusFilter == 'cancelled',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = 'cancelled';
                  });
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                checkmarkColor: const Color(0xFFB22222),
                labelStyle: TextStyle(
                  color: _selectedStatusFilter == 'cancelled' ? const Color(0xFFB22222) : Colors.white,
                ),
              ),
              FilterChip(
                label: const Text('Concluído'),
                selected: _selectedStatusFilter == 'completed',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = 'completed';
                  });
                },
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                checkmarkColor: const Color(0xFFB22222),
                labelStyle: TextStyle(
                  color: _selectedStatusFilter == 'completed' ? const Color(0xFFB22222) : Colors.white,
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Filtros de data
        if (isMobile)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDateFilter ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDateFilter = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                  label: Text(
                    _startDateFilter != null
                        ? '${_startDateFilter!.day}/${_startDateFilter!.month}/${_startDateFilter!.year}'
                        : 'De',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDateFilter ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDateFilter = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                  label: Text(
                    _endDateFilter != null
                        ? '${_endDateFilter!.day}/${_endDateFilter!.month}/${_endDateFilter!.year}'
                        : 'Até',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
                onPressed: () {
                  setState(() {
                    _startDateFilter = null;
                    _endDateFilter = null;
                  });
                },
                tooltip: 'Limpar filtros de data',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDateFilter ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDateFilter = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white70),
                  label: Text(
                    _startDateFilter != null
                        ? 'De: ${_startDateFilter!.day}/${_startDateFilter!.month}/${_startDateFilter!.year}'
                        : 'Data Inicial',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDateFilter ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDateFilter = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white70),
                  label: Text(
                    _endDateFilter != null
                        ? 'Até: ${_endDateFilter!.day}/${_endDateFilter!.month}/${_endDateFilter!.year}'
                        : 'Data Final',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _startDateFilter = null;
                    _endDateFilter = null;
                  });
                },
                tooltip: 'Limpar filtros de data',
              ),
            ],
          ),
        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: _adminController.getAllAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              final allAppointments = snapshot.data ?? [];

              // Aplicar filtros
              final filteredAppointments = allAppointments.where((appointment) {
                final matchesSearch = _searchQuery.isEmpty ||
                    appointment.clientName.toLowerCase().contains(_searchQuery) ||
                    appointment.serviceName.toLowerCase().contains(_searchQuery) ||
                    appointment.barberName.toLowerCase().contains(_searchQuery);

                final matchesStatus = _selectedStatusFilter == 'Todos' ||
                    appointment.status == _selectedStatusFilter;

                final matchesDate = (_startDateFilter == null || appointment.dateTime.isAfter(_startDateFilter!.subtract(const Duration(days: 1)))) &&
                    (_endDateFilter == null || appointment.dateTime.isBefore(_endDateFilter!.add(const Duration(days: 1))));

                return matchesSearch && matchesStatus && matchesDate;
              }).toList();

              return Column(
                children: [
                  Text(
                    'Agendamentos (${filteredAppointments.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: filteredAppointments.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum agendamento encontrado',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = filteredAppointments[index];
                            final endTime = _calculateEndTime(appointment.dateTime, appointment.duration);

                            return Card(
                              color: const Color(0xFF2A2A2A),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                onTap: () => _showAppointmentDetails(appointment),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${appointment.clientName} - ${appointment.serviceName}',
                                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Barbeiro: ${appointment.barberName}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time, size: 16, color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${_formatTime(appointment.dateTime)} - ${_formatTime(endTime)} (${appointment.duration}min)',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${appointment.dateTime.day.toString().padLeft(2, '0')}/${appointment.dateTime.month.toString().padLeft(2, '0')}/${appointment.dateTime.year}',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.euro, size: 16, color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '€${appointment.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(appointment.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(appointment.status),
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (appointment.status == 'pending')
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.check, color: Colors.green),
                                                  onPressed: () => _confirmAppointment(appointment.id),
                                                  tooltip: 'Confirmar',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                                  onPressed: () => _cancelAppointment(appointment.id),
                                                  tooltip: 'Cancelar',
                                                ),
                                              ],
                                            ),
                                          if (appointment.status == 'confirmed') ...[
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              onPressed: () => _cancelAppointment(appointment.id),
                                              tooltip: 'Cancelar',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.blue),
                                              onPressed: () => _completeAppointment(appointment.id),
                                              tooltip: 'Marcar como concluído',
                                            ),
                                          ],
                                          if (appointment.status == 'cancelled') ...[
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteAppointment(appointment.id),
                                              tooltip: 'Deletar agendamento',
                                            ),
                                          ],
                                          if (appointment.status == 'completed') ...[
                                            IconButton(
                                              icon: const Icon(Icons.star, color: Colors.amber),
                                              onPressed: () => _sendReviewRequest(appointment),
                                              tooltip: 'Solicitar avaliação',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }


  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  DateTime _calculateEndTime(DateTime startTime, int durationMinutes) {
    return startTime.add(Duration(minutes: durationMinutes));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }



  Future<void> _confirmAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Agendamento'),
        content: const Text('Tem certeza que deseja confirmar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.confirmAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento confirmado com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao confirmar agendamento: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text('Tem certeza que deseja cancelar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.cancelAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento cancelado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar agendamento: $e')),
          );
        }
      }
    }
  }

  Future<void> _completeAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Concluído'),
        content: const Text('Tem certeza que deseja marcar este agendamento como concluído?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.completeAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento marcado como concluído')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao marcar como concluído: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Agendamento'),
        content: const Text('Tem certeza que deseja deletar este agendamento? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.deleteAppointment(appointmentId);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento deletado com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar agendamento: $e')),
        );
      }
    }
  }

  Future<void> _sendReviewRequest(AppointmentModel appointment) async {
    try {
      // Get client email and review request count
      final email = await _adminController.getAppointmentClientEmail(appointment.id);
      final reviewCount = email.isNotEmpty ? await _adminController.getReviewRequestCount(email) : 0;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Solicitar Avaliação'),
          content: Text(
            reviewCount == 0
                ? 'Esta será a primeira solicitação de avaliação enviada para este cliente. Tem certeza que deseja prosseguir?'
                : 'Já foi enviada $reviewCount solicitação(ões) de avaliação para este cliente anteriormente. Tem certeza que deseja enviar outra?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _adminController.sendReviewRequest(appointment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitação de avaliação enviada com sucesso')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar solicitação de avaliação: $e')),
        );
      }
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    final endTime = _calculateEndTime(appointment.dateTime, appointment.duration);
    final isMobile = MediaQuery.of(context).size.width < 768;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: isMobile ? double.maxFinite : 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB22222).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFFB22222),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes do Agendamento',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(appointment.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Content - Cards Layout
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Cliente Card
                      _buildDetailCard(
                        icon: Icons.person,
                        title: 'Cliente',
                        children: [
                          _buildDetailRow('Nome', appointment.clientName),
                          if (appointment.clientPhone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Telefone:',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final Uri launchUri = Uri(
                                          scheme: 'tel',
                                          path: appointment.clientPhone,
                                        );
                                        await launchUrl(launchUri);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB22222).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          appointment.clientPhone,
                                          style: const TextStyle(
                                            color: Color(0xFFB22222),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 16),

                      // Serviço Card
                      _buildDetailCard(
                        icon: Icons.content_cut,
                        title: 'Serviço',
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFB22222)),
                          onPressed: () => _showEditServiceDialog(appointment),
                          tooltip: 'Editar Serviço',
                        ),
                        children: [
                          _buildDetailRow('Serviço', appointment.serviceName),
                          _buildDetailRow('Barbeiro', appointment.barberName),
                          _buildDetailRow('Duração', '${appointment.duration} minutos'),
                          _buildDetailRow('Preço', '€${appointment.price.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Horário Card
                      _buildDetailCard(
                        icon: Icons.access_time,
                        title: 'Horário',
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFB22222)),
                          onPressed: () => _showEditTimeDialog(appointment),
                          tooltip: 'Editar Horário',
                        ),
                        children: [
                          _buildDetailRow(
                            'Data',
                            '${appointment.dateTime.day.toString().padLeft(2, '0')}/${appointment.dateTime.month.toString().padLeft(2, '0')}/${appointment.dateTime.year}',
                          ),
                          _buildDetailRow('Início', _formatTime(appointment.dateTime)),
                          _buildDetailRow('Término Previsto', _formatTime(endTime)),
                          _buildDetailRow('Duração Total', '${appointment.duration} minutos'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (appointment.status == 'pending') ...[
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _cancelAppointment(appointment.id);
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _confirmAppointment(appointment.id);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirmar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    if (appointment.status == 'confirmed') ...[
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _cancelAppointment(appointment.id);
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _completeAppointment(appointment.id);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Marcar como Concluído'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    if (appointment.status == 'completed' || appointment.status == 'cancelled') ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB22222), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFB22222),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB22222), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB22222),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _showEditServiceDialog(AppointmentModel appointment) async {
    Map<String, dynamic>? selectedService;
    ProfissionalModel? selectedProfessional;
    List<Map<String, dynamic>> availableServices = [];
    List<ProfissionalModel> availableProfessionals = [];

    // Load available professionals
    try {
      final professionalsSnapshot = await firestore.collection('profissionais').where('disponivel', isEqualTo: true).get();
      availableProfessionals = professionalsSnapshot.docs
          .map((doc) => ProfissionalModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading professionals: $e');
    }

    // Load services for the current professional initially
    try {
      final servicesSnapshot = await firestore.collection('servicos')
          .where('profissionalId', isEqualTo: appointment.barberId)
          .where('ativo', isEqualTo: true)
          .get();
      availableServices = servicesSnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error loading services: $e');
    }

    // Set initial values
    if (availableProfessionals.isNotEmpty) {
      selectedProfessional = availableProfessionals.firstWhere(
        (p) => p.userId == appointment.barberId,
        orElse: () => availableProfessionals[0],
      );
    } else {
      selectedProfessional = null;
    }
    if (availableServices.isNotEmpty) {
      selectedService = availableServices.firstWhere(
        (s) => s['nome'] == appointment.serviceName,
        orElse: () => availableServices[0],
      );
    } else {
      selectedService = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Editar Serviço',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione o novo barbeiro:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProfissionalModel>(
                  value: selectedProfessional,
                  onChanged: (ProfissionalModel? newValue) async {
                    if (newValue != null) {
                      setState(() {
                        selectedProfessional = newValue;
                        selectedService = null;
                      });
                      // Load services for the new professional
                      try {
                        final servicesSnapshot = await firestore.collection('servicos')
                            .where('profissionalId', isEqualTo: newValue.userId)
                            .where('ativo', isEqualTo: true)
                            .get();
                        setState(() {
                          availableServices = servicesSnapshot.docs
                              .map((doc) => doc.data())
                              .toList();
                        });
                      } catch (e) {
                        print('Error loading services for professional: $e');
                      }
                    }
                  },
                  items: availableProfessionals.map((professional) {
                    return DropdownMenuItem<ProfissionalModel>(
                      value: professional,
                      child: Text(
                        professional.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecione o novo serviço:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 80,
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedService,
                    onChanged: (Map<String, dynamic>? newValue) {
                      setState(() {
                        selectedService = newValue;
                      });
                    },
                    items: availableServices.map((service) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: service,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 120, // Account for dropdown arrow and padding
                          ),
                          child: Text(
                            '${service['nome'] as String} - €${(service['preco'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    isDense: true,
                    isExpanded: true,
                  ),
                ),
                if (selectedService != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo das alterações:',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Barbeiro: ${selectedProfessional?.name ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Serviço: ${selectedService!['nome'] as String}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Preço: €${(selectedService!['preco'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Duração: ${selectedService!['duracao'] as int} minutos',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: selectedService != null && selectedProfessional != null
                  ? () async {
                      try {
                        await _adminController.updateAppointmentService(
                          appointment.id,
                          selectedService!['nome'],
                          selectedProfessional!.userId,
                          (selectedService!['preco'] as num).toDouble(),
                          selectedService!['duracao'] as int,
                        );

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Serviço atualizado com sucesso')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar serviço: $e')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTimeDialog(AppointmentModel appointment) {
    DateTime? selectedDate = appointment.dateTime;
    TimeOfDay? selectedTime;
    ProfissionalModel? professional;
    List<Map<String, TimeOfDay>> bookedTimes = [];
    int calendarKey = DateTime.now().millisecondsSinceEpoch;

    // Load professional data
    Future<void> loadProfessional() async {
      try {
        final profDoc = await firestore.collection('profissionais').doc(appointment.barberId).get();
        if (profDoc.exists) {
          professional = ProfissionalModel.fromMap(profDoc.data()!, profDoc.id);
        }
      } catch (e) {
        print('Error loading professional: $e');
      }
    }

    // Load booked times for selected date
    Future<void> loadBookedTimes(DateTime date) async {
      if (professional == null) return;

      try {
        String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        QuerySnapshot snapshot = await firestore.collection('agendamentos')
            .where('professional', isEqualTo: professional!.userId)
            .where('date', isEqualTo: dateString)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        bookedTimes = snapshot.docs
            .where((doc) => doc.id != appointment.id) // Exclude current appointment
            .map((doc) {
          String timeStr = doc['time'];
          List<String> parts = timeStr.split(':');
          TimeOfDay start = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          int duration = doc['duracao'] ?? appointment.duration;
          int intervalo = doc['intervalo'] ?? professional!.intervaloMinutos;
          int endTotalMinutes = start.hour * 60 + start.minute + duration + intervalo;
          TimeOfDay end = TimeOfDay(hour: endTotalMinutes ~/ 60, minute: endTotalMinutes % 60);
          return {'start': start, 'end': end};
        }).toList();
      } catch (e) {
        print('Error loading booked times: $e');
      }
    }

    // Check if day is available
    bool isDayAvailable(DateTime day) {
      if (professional == null) return false;

      const weekdayMap = {
        1: "segunda",
        2: "terça",
        3: "quarta",
        4: "quinta",
        5: "sexta",
        6: "sábado",
        7: "domingo"
      };
      final dayName = weekdayMap[day.weekday];
      return professional!.diasAtendimento.contains(dayName);
    }

    // Get available times for selected date
    List<TimeOfDay> getAvailableTimes() {
      if (professional == null || selectedDate == null) return [];

      List<TimeOfDay> times = [];
      final turnos = professional!.turnos;

      // Generate times from morning shift
      if (turnos.containsKey('manha')) {
        final manha = turnos['manha']!;
        final start = _parseTime(manha['inicio']!);
        final end = _parseTime(manha['fim']!);
        TimeOfDay current = start;
        int endTotalMinutes = end.hour * 60 + end.minute;
        while (current.hour * 60 + current.minute + appointment.duration <= endTotalMinutes) {
          times.add(current);
          int nextTotalMinutes = current.hour * 60 + current.minute + appointment.duration + professional!.intervaloMinutos;
          current = TimeOfDay(hour: nextTotalMinutes ~/ 60, minute: nextTotalMinutes % 60);
        }
      }

      // Generate times from afternoon shift
      if (turnos.containsKey('tarde')) {
        final tarde = turnos['tarde']!;
        final start = _parseTime(tarde['inicio']!);
        final end = _parseTime(tarde['fim']!);
        TimeOfDay current = start;
        int endTotalMinutes = end.hour * 60 + end.minute;
        while (current.hour * 60 + current.minute + appointment.duration <= endTotalMinutes) {
          times.add(current);
          int nextTotalMinutes = current.hour * 60 + current.minute + appointment.duration + professional!.intervaloMinutos;
          current = TimeOfDay(hour: nextTotalMinutes ~/ 60, minute: nextTotalMinutes % 60);
        }
      }

      // Filter out booked times
      times = times.where((time) {
        int proposedStartMinutes = time.hour * 60 + time.minute;
        int proposedEndMinutes = proposedStartMinutes + appointment.duration;
        for (var booked in bookedTimes) {
          TimeOfDay bookedStart = booked['start']!;
          TimeOfDay bookedEnd = booked['end']!;
          int bookedStartMinutes = bookedStart.hour * 60 + bookedStart.minute;
          int bookedEndMinutes = bookedEnd.hour * 60 + bookedEnd.minute;
          // Check for overlap
          if (proposedStartMinutes < bookedEndMinutes && proposedEndMinutes > bookedStartMinutes) {
            return false;
          }
        }
        return true;
      }).toList();

      // Filter out past times if selected date is today
      if (isSameDay(selectedDate, DateTime.now())) {
        final now = TimeOfDay.now();
        final bufferTime = TimeOfDay(hour: now.hour, minute: now.minute + 30);
        final adjustedNow = bufferTime.hour > now.hour || (bufferTime.hour == now.hour && bufferTime.minute > now.minute)
            ? bufferTime : TimeOfDay(hour: now.hour + 1, minute: now.minute);
        times = times.where((time) => time.hour > adjustedNow.hour ||
            (time.hour == adjustedNow.hour && time.minute > adjustedNow.minute)).toList();
      }

      return times;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Editar Horário',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione uma nova data e horário:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: TableCalendar(
                    key: ValueKey(calendarKey),
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: selectedDate ?? DateTime.now(),
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    enabledDayPredicate: isDayAvailable,
                    onDaySelected: (selectedDay, focusedDay) async {
                      setState(() {
                        selectedDate = selectedDay;
                        selectedTime = null;
                      });
                      await loadBookedTimes(selectedDay);
                      setState(() {});
                    },
                    calendarFormat: CalendarFormat.week,
                    availableCalendarFormats: const {
                      CalendarFormat.week: 'Semana',
                    },
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: Colors.white),
                      weekendTextStyle: TextStyle(color: Colors.white),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFFB22222),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(color: Colors.grey),
                    ),
                    headerStyle: const HeaderStyle(
                      titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                      formatButtonTextStyle: TextStyle(color: Colors.white),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.white),
                      weekendStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedDate != null) ...[
                  Text(
                    'Data selecionada: ${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Horários disponíveis:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: getAvailableTimes().map((time) {
                      return ElevatedButton(
                        onPressed: () => setState(() => selectedTime = time),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedTime == time ? const Color(0xFFB22222) : Colors.grey,
                          foregroundColor: selectedTime == time ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
                      );
                    }).toList(),
                  ),
                ],
                if (selectedDate != null && getAvailableTimes().isEmpty) ...[
                  const Text(
                    'Nenhum horário disponível para esta data.',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: selectedDate != null && selectedTime != null
                  ? () async {
                      try {
                        final newDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );

                        await _adminController.updateAppointmentTime(appointment.id, newDateTime);

                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Horário atualizado com sucesso')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar horário: $e')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    // Load initial data
    loadProfessional().then((_) async {
      if (selectedDate != null) {
        await loadBookedTimes(selectedDate!);
        setState(() {});
      }
    });
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildFinancialStats() {
    return const FinancialStatsPage();
  }

  Widget _buildBarbers() {
    return const AdminProfissionaisPage();
  }



  Widget _buildOffers() {
    return const VipOffersPage();
  }

  Widget _buildClients() {
    return const ClientesPage();
  }

  Widget _buildRetencaoClientes() {
    return const RetencaoClientesPage();
  }

  Widget _buildBarberShop() {
    return const BarbeariasPage();
  }

  Widget _buildPosts() {
    return const PostsPage();
  }

  Widget _buildSettings() {
    return const SettingsPage();
  }
  

}
