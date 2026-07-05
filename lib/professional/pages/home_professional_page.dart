// ignore_for_file: use_build_context_synchronously, unused_element

import 'dart:async';
import 'package:falcaobarbershopv2/professional/controller/professional_controller.dart';
import 'package:falcaobarbershopv2/professional/widgets/professional_charts_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../admin/model/appointment_model.dart';
import '../../admin/model/notification_model.dart';
import '../../admin/model/profissional_model.dart';
import '../../admin/model/service_model.dart';
import '../../user/model/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

class HomeProfessionalPage extends StatefulWidget {
  const HomeProfessionalPage({super.key});

  @override
  State<HomeProfessionalPage> createState() => _HomeProfessionalPageState();
}

class _HomeProfessionalPageState extends State<HomeProfessionalPage> {
  final ProfessionalController _controller = ProfessionalController();
  int _selectedIndex = 0;
  UserModel? _barberProfile;
  bool _isEditing = false;
  ProfissionalModel? _professionalData;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  final List<String> _pageTitles = [
    'Dashboard',
    'Agendamentos',
    'Perfil',
    'Notificações',
  ];

  final List<IconData> _pageIcons = [
    Icons.dashboard,
    Icons.calendar_today,
    Icons.person,
    Icons.notifications,
    Icons.history,
    Icons.settings,
  ];

  int _unreadNotificationsCount = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadBarberProfile();
    _loadProfessionalData();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = _controller.getBarberNotifications().listen((notifications) {
      final unreadCount = notifications.where((n) => !n.lida).length;
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = unreadCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarberProfile() async {
    final profile = await _controller.getCurrentBarberProfile();
    if (mounted) {
      setState(() {
        _barberProfile = profile;
      });
    }
  }

  Future<void> _loadProfessionalData() async {
    final data = await _controller.getCurrentBarberProfessionalData();
    if (mounted) {
      setState(() {
        _professionalData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                _buildAvatar(size: 64, fontSize: 24),
                const SizedBox(height: 12),
                Text(
                  _barberProfile?.name.split(' ').first ?? 'Barbeiro',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'BarberPro',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pageTitles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        _pageIcons[index],
                        color: _selectedIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      if (index == 3 && _unreadNotificationsCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
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
                              _unreadNotificationsCount > 99 ? '99+' : _unreadNotificationsCount.toString(),
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
                  ),
                  title: Text(
                    _pageTitles[index],
                    style: TextStyle(
                      color: _selectedIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                  selected: _selectedIndex == index,
                  selectedTileColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(),
              icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onPrimary),
              label: Text('Sair', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => _showMobileMenu(),
            ),
          Expanded(
            child: Text(
              _pageTitles[_selectedIndex],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _buildAvatar(size: 40, fontSize: 15),
              const SizedBox(width: 12),
              Text(
                'Olá, ${_barberProfile?.name.split(' ').first ?? 'Barbeiro'}!',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildAgendamentos(isMobile);
      case 2:
        return _buildPerfil();
      case 3:
        return _buildNotificacoes();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Olá, ${_barberProfile?.name.split(' ').first ?? 'Barbeiro'}! Pronto para mais um dia de cortes?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<AppointmentModel>>(
                  stream: _controller.getTodayAppointments(),
                  builder: (context, snapshot) {
                    final todayAppointments = snapshot.data?.length ?? 0;
                    return _buildSummaryCard('Agendamentos Hoje', todayAppointments.toString(), Icons.calendar_today);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<AppointmentModel?>(
                  future: _controller.getNextAppointment(),
                  builder: (context, snapshot) {
                    final nextAppointment = snapshot.data;
                    return _buildSummaryCard(
                      'Próximo Cliente',
                      nextAppointment != null
                          ? '${nextAppointment.clientName}\n${DateFormat('HH:mm').format(nextAppointment.dateTime)}'
                          : 'Nenhum',
                      Icons.access_time,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: _controller.getMonthlyCompletedAppointments(),
                  builder: (context, snapshot) {
                    final monthlyCount = snapshot.data ?? 0;
                    return _buildSummaryCard('Atendidos no Mês', monthlyCount.toString(), Icons.people);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // >>> GRÁFICOS (fix)
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _controller.getRevenueByDayLastNDays(days: 14),
              _controller.getTopServicesByRevenue(limit: 7),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.only(top: 24), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Erro ao carregar gráficos: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                );
              }

              final revenueRaw = (snapshot.data?.first as List?) ?? [];
              final topServicesRaw = (snapshot.data?.last as List?) ?? [];

              final revenuePoints = revenueRaw
                  .map((e) {
                    final date = e is Map ? (e['date'] as DateTime?) : null;
                    final value = e is Map ? (e['value'] as num?) : null;
                    if (date == null || value == null) return null;
                    return ProfessionalDataPoint(date: date, value: value.toDouble());
                  })
                  .whereType<ProfessionalDataPoint>()
                  .toList();

              final topPoints = topServicesRaw
                  .map((e) {
                    final label = e is Map ? e['label'] as String? : null;
                    final value = e is Map ? (e['value'] as num?) : null;
                    if (label == null || value == null) return null;
                    return ProfessionalServicePoint(label: label, value: value.toDouble());
                  })
                  .whereType<ProfessionalServicePoint>()
                  .toList();

              return ProfessionalChartsSectionWidget(
                revenueByDay: ProfessionalRevenueByDayData(revenuePoints),
                topServices: ProfessionalTopServicesData(topPoints),
              );
            },
          ),

          const SizedBox(height: 20),
          Text(
            'Ações Rápidas',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickAction('Ver Agendamentos Completa', Icons.calendar_view_day, () {
                if (mounted) {
                  setState(() => _selectedIndex = 1);
                }
              }),
              const SizedBox(width: 12),
              _buildQuickAction('Notificações', Icons.notifications, () {
                if (mounted) {
                  setState(() => _selectedIndex = 3);
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFB22222).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFB22222), size: 20),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB22222).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFB22222), size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentos(bool isMobile) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _controller.getBarberAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
        }

        final allAppointments = snapshot.data ?? [];
        final filteredAppointments = _filterAppointments(allAppointments);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome do cliente...',
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  isMobile
                      ? Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedStatusFilter,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: [
                                const DropdownMenuItem(value: 'Todos', child: Text('Todos os Status')),
                                const DropdownMenuItem(value: 'pending', child: Text('Pendente')),
                                const DropdownMenuItem(value: 'confirmed', child: Text('Confirmado')),
                                const DropdownMenuItem(value: 'completed', child: Text('Concluído')),
                                const DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatusFilter = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _selectDateRange(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Período',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                                ),
                                child: Text(
                                  _startDateFilter != null && _endDateFilter != null
                                      ? '${DateFormat('dd/MM').format(_startDateFilter!)} - ${DateFormat('dd/MM').format(_endDateFilter!)}'
                                      : 'Selecionar período',
                                  style: TextStyle(
                                    color: _startDateFilter != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: _clearFilters,
                                icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.primary),
                                tooltip: 'Limpar filtros',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatusFilter,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'Todos', child: Text('Todos os Status')),
                                  const DropdownMenuItem(value: 'pending', child: Text('Pendente')),
                                  const DropdownMenuItem(value: 'confirmed', child: Text('Confirmado')),
                                  const DropdownMenuItem(value: 'completed', child: Text('Concluído')),
                                  const DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatusFilter = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDateRange(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Período',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  child: Text(
                                    _startDateFilter != null && _endDateFilter != null
                                        ? '${DateFormat('dd/MM').format(_startDateFilter!)} - ${DateFormat('dd/MM').format(_endDateFilter!)}'
                                        : 'Selecionar período',
                                    style: TextStyle(
                                      color: _startDateFilter != null
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _clearFilters,
                              icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.primary),
                              tooltip: 'Limpar filtros',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  Text(
                    '${filteredAppointments.length} agendamento${filteredAppointments.length != 1 ? 's' : ''} encontrado${filteredAppointments.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredAppointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum agendamento encontrado',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente ajustar os filtros de pesquisa',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = filteredAppointments[index];
                        return InkWell(
                          onTap: () => _showAppointmentDetails(appointment),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.clientName,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        appointment.serviceName,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime),
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(appointment.status),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusText(appointment.status),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  onSelected: (value) => _updateAppointmentStatus(appointment.id, value),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'confirmed', child: Text('Confirmar')),
                                    PopupMenuItem(value: 'completed', child: Text('Concluir')),
                                    PopupMenuItem(value: 'cancelled', child: Text('Cancelar')),
                                  ],
                                  child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerfil() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipOval(child: SizedBox(width: 120, height: 120, child: _buildAvatar(size: 120, fontSize: 48))),
                              if (_isUploadingPhoto)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isUploadingPhoto)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB22222),
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _barberProfile?.name ?? 'Barbeiro',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _barberProfile?.role ?? 'Profissional',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
                      label: Text('Editar Perfil', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),

            if (_barberProfile != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informações Pessoais',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isEditing) ...[
                          _buildModernEditableProfileField('Nome', _barberProfile!.name, Icons.person, (value) {
                            setState(() {
                              _barberProfile = _barberProfile!.copyWith(name: value);
                            });
                          }),
                          const SizedBox(height: 16),
                          _buildModernEditableProfileField('Email', _barberProfile!.email, Icons.email, (value) {
                            setState(() {
                              _barberProfile = _barberProfile!.copyWith(email: value);
                            });
                          }),
                          const SizedBox(height: 16),
                          _buildModernEditableProfileField('Telefone', _barberProfile!.phone, Icons.phone, (value) {
                            setState(() {
                              _barberProfile = _barberProfile!.copyWith(phone: value);
                            });
                          }),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Salvar Alterações',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _isEditing = false),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildModernReadOnlyProfileField('Nome', _barberProfile!.name, Icons.person),
                          const SizedBox(height: 16),
                          _buildModernReadOnlyProfileField('Email', _barberProfile!.email, Icons.email),
                          const SizedBox(height: 16),
                          _buildModernReadOnlyProfileField('Telefone', _barberProfile!.phone, Icons.phone),
                          const SizedBox(height: 16),
                          _buildModernReadOnlyProfileField('Cidade', _barberProfile!.city, Icons.location_city),
                          const SizedBox(height: 16),
                          _buildModernReadOnlyProfileField('Função', _barberProfile!.role, Icons.work),
                          const SizedBox(height: 16),
                          _buildModernReadOnlyProfileField('Dias de Atendimento', _professionalData?.diasAtendimento.join(', ') ?? '', Icons.calendar_today),
                          const SizedBox(height: 16),
                          Builder(builder: (context) {
                            String turnosText = '';
                            if (_professionalData?.turnos != null) {
                              _professionalData!.turnos.forEach((key, value) {
                                final inicio = value['inicio'] ?? '';
                                final fim = value['fim'] ?? '';
                                final turnoName = key == 'manha' ? 'Manhã' : key == 'tarde' ? 'Tarde' : key;
                                turnosText += '$turnoName: $inicio - $fim, ';
                              });
                              turnosText = turnosText.trim().replaceAll(RegExp(r',$'), '');
                            }
                            return _buildModernReadOnlyProfileField('Horários de Atendimento', turnosText, Icons.access_time);
                          }),
                        ],
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurações da Conta',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildModernActionButton('Alterar Senha', Icons.lock, _showPasswordChangeDialog),
                          const SizedBox(height: 12),
                          _buildModernActionButton('Alterar Email', Icons.email, _showEmailChangeDialog),
                        ],
                      ),
                    ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacoes() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _controller.getBarberNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
        }

        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return Center(child: Text('Nenhuma notificação', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return InkWell(
              onTap: () {
                if (!notification.lida) {
                  _controller.markNotificationAsRead(notification.id);
                }
                setState(() => _selectedIndex = 1);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      notification.lida ? Icons.notifications_none : Icons.notifications_active,
                      color: notification.lida
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.titulo,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            notification.mensagem,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          Text(
                            _getTimeAgo(notification.createdAt),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.lida)
                      IconButton(
                        icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _controller.markNotificationAsRead(notification.id),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: List.generate(
        _pageTitles.length,
        (index) => BottomNavigationBarItem(
          icon: Icon(_pageIcons[index]),
          label: _pageTitles[index],
        ),
      ),
    );
  }

  Widget _buildModernEditableProfileField(String label, String value, IconData icon, Function(String) onChanged) {
    final TextEditingController controller = TextEditingController(text: value);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              hintText: 'Digite $label',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildModernReadOnlyProfileField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 20),
        label: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showPasswordChangeDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Atual')),
            TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Nova Senha')),
            TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar Nova Senha')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem')));
                return;
              }
              try {
                await _controller.changePassword(currentPasswordController.text, newPasswordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar senha: $e')));
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  void _showEmailChangeDialog() {
    final TextEditingController newEmailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: newEmailController, decoration: const InputDecoration(labelText: 'Novo Email')),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Atual')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _controller.changeEmail(newEmailController.text, passwordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email alterado com sucesso!')));
                await _loadBarberProfile();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar email: $e')));
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await pickedFile.readAsBytes();
      final random = Random();
      final fileName = 'profissionais/${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await storageRef.getDownloadURL();

      await _controller.updateProfilePhoto(downloadUrl);
      await _loadProfessionalData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _saveProfile() async {
    if (_barberProfile == null) return;
    try {
      await _controller.updateBarberProfile(_barberProfile!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!')));
      await _loadBarberProfile();
      _isEditing = false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar perfil: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'pending':
        return 'Pendente';
      case 'cancelled':
        return 'Cancelado';
      case 'completed':
        return 'Concluído';
      default:
        return 'Desconhecido';
    }
  }

  void _updateAppointmentStatus(String appointmentId, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Alteração'),
        content: Text('Tem certeza que deseja alterar o status para "${_getStatusText(newStatus)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _controller.updateAppointmentStatus(appointmentId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status atualizado com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar status: $e')));
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${appointment.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Serviço: ${appointment.serviceName}')),
                IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {
                  Navigator.pop(context);
                  _showEditServiceDialog(appointment);
                }, tooltip: 'Editar serviço'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Data e Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}')),
                IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {
                  Navigator.pop(context);
                  _showEditTimeDialog(appointment);
                }, tooltip: 'Editar horário'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Telefone: ${appointment.clientPhone}'),
            const SizedBox(height: 8),
            Text('Status: ${_getStatusText(appointment.status)}'),
            const SizedBox(height: 8),
            Text('Valor: R\$ ${appointment.price.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                _pageTitles.length,
                (index) => ListTile(
                  leading: Icon(_pageIcons[index], color: Colors.white),
                  title: Text(_pageTitles[index], style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Sair', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await _controller.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }

  List<AppointmentModel> _filterAppointments(List<AppointmentModel> appointments) {
    return appointments.where((appointment) {
      final matchesSearch = _searchQuery.isEmpty || appointment.clientName.toLowerCase().contains(_searchQuery);
      final matchesStatus = _selectedStatusFilter == 'Todos' || appointment.status == _selectedStatusFilter;
      final matchesDate = (_startDateFilter == null && _endDateFilter == null) ||
          (appointment.dateTime.isAfter(_startDateFilter!.subtract(const Duration(days: 1))) &&
              appointment.dateTime.isBefore(_endDateFilter!.add(const Duration(days: 1))));
      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDateFilter != null && _endDateFilter != null
          ? DateTimeRange(start: _startDateFilter!, end: _endDateFilter!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDateFilter = picked.start;
        _endDateFilter = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatusFilter = 'Todos';
      _startDateFilter = null;
      _endDateFilter = null;
      _searchController.clear();
    });
  }

  void _showEditServiceDialog(AppointmentModel appointment) async {
    try {
      final services = await _controller.getBarberServices();
      if (services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum serviço disponível para alteração')));
        return;
      }

      ServiceModel? selectedService;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Editar Serviço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecione o novo serviço:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServiceModel>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text('${service.nome} - R\$ ${service.preco.toStringAsFixed(2)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedService = value;
                },
                hint: const Text('Selecione um serviço'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (selectedService == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um serviço')));
                  return;
                }

                try {
                  await _controller.updateAppointmentService(
                    appointment.id,
                    selectedService!.nome,
                    selectedService!.preco,
                    selectedService!.duracao,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviço atualizado com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar serviço: $e')));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar serviços: $e')));
    }
  }

  void _showEditTimeDialog(AppointmentModel appointment) async {
    DateTime selectedDate = appointment.dateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appointment.dateTime);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      selectedDate = pickedDate;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );

      if (pickedTime != null) {
        selectedTime = pickedTime;
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Alteração'),
            content: Text('Alterar horário para ${DateFormat('dd/MM/yyyy HH:mm').format(newDateTime)}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await _controller.updateAppointmentTime(appointment.id, newDateTime);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horário atualizado com sucesso!')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar horário: $e')));
          }
        }
      }
    }
  }

  Widget _buildAvatar({double size = 40, double fontSize = 16}) {
    final photoUrl = _professionalData?.fotoUrl;
    final initial = _barberProfile?.name.trim().isNotEmpty == true ? _barberProfile!.name.trim().substring(0, 1).toUpperCase() : 'B';

    if (photoUrl != null && photoUrl.isNotEmpty) {
    return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: const Color(0xFFB22222).withOpacity(0.15),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB22222)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _avatarFallback(size, fontSize, initial),
        ),
      );
    }

    return _avatarFallback(size, fontSize, initial);
  }

  Widget _avatarFallback(double size, double fontSize, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB22222), Color(0xFF7A0000)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

