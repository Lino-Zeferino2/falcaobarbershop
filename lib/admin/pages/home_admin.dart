// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names, unused_element, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../firestore_instance.dart';
import '../controller/admin_controller.dart';
import '../model/appointment_model.dart';
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
import 'package:url_launcher/url_launcher.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final AdminController _adminController = AdminController();
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardStats;
  List<int> _weeklyData = List.filled(7, 0);
  List<Map<String, dynamic>> _topServices = [];
  List<Map<String, dynamic>> _recentClients = [];
  bool _loadingStats = true;

  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  final TextEditingController _searchController = TextEditingController();

  static const _red = Color(0xFFB22222);
  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _card2 = Color(0xFF222222);

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Agendamentos'),
    _NavItem(Icons.analytics_outlined, Icons.analytics, 'Financeiro'),
    _NavItem(Icons.people_outline, Icons.people, 'Profissionais'),
    _NavItem(Icons.local_offer_outlined, Icons.local_offer, 'Ofertas VIP'),
    _NavItem(Icons.person_outline, Icons.person, 'Clientes'),
    _NavItem(Icons.person_off_outlined, Icons.person_off, 'Retenção'),
    _NavItem(Icons.storefront_outlined, Icons.storefront, 'Barbearia'),
    _NavItem(Icons.post_add_outlined, Icons.post_add, 'Posts'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Configurações'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loadingStats = true);
    await Future.wait([
      _loadDashboardStats(),
      _loadWeeklyData(),
      _loadTopServices(),
      _loadRecentClients(),
    ]);
    setState(() => _loadingStats = false);
  }

  Future<void> _loadDashboardStats() async {
    final stats = await _adminController.getDashboardStats();
    if (mounted) setState(() => _dashboardStats = stats);
  }

  Future<void> _loadWeeklyData() async {
    final data = await _adminController.getWeeklyAppointmentsData();
    if (mounted) setState(() => _weeklyData = data);
  }

  Future<void> _loadTopServices() async {
    try {
      final snap = await firestore.collection('agendamentos').get();
      final Map<String, int> count = {};
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['status'] == 'completed') {
          final name = d['service'] ?? 'Desconhecido';
          count[name] = (count[name] ?? 0) + 1;
        }
      }
      final sorted = count.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) {
        setState(() {
          _topServices = sorted.take(5).map((e) => {'name': e.key, 'count': e.value}).toList();
        });
      }
    } catch (_) {}
  }

Future<void> _loadRecentClients() async {
  try {
    final snap = await firestore
        .collection('clientes')
        .where('role', isEqualTo: 'cliente')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    if (mounted) {
      setState(() {
        _recentClients = snap.docs.map((d) => d.data()).toList();
      });
    }
  } catch (e) {
    debugPrint('Erro ao carregar clientes recentes: $e');
    // Opcional: mostrar um SnackBar ou estado de erro visível no card,
    // em vez de simplesmente ficar vazio sem explicação.
  }
}
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isMobile),
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Container(
              color: _bg,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.white.withOpacity(0.08)),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(4),
            child: Image.asset('assets/images/logo_falcao.png'),
          ),
          const SizedBox(width: 10),
          Text(
            isMobile ? 'Admin' : 'Falcão Admin',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        StreamBuilder<int>(
          stream: _adminController.getUnreadNotificationsCount(),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NotificationsPage(onNavigateToAppointments: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 1);
                    }),
                  )),
                ),
                if (count > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            color: _card2,
            onSelected: (v) {
              if (v == 'perfil') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileAdmin()));
              if (v == 'sair') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'perfil', child: Text('Perfil', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'sair', child: Text('Sair', style: TextStyle(color: Colors.redAccent))),
            ],
            child: const CircleAvatar(
              radius: 17,
              backgroundImage: AssetImage('assets/images/default_admin.jpg'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: _card,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _red.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? _red.withOpacity(0.4) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected ? _red : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white54,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_outlined, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Sair', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _card,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return ListTile(
                  leading: Icon(selected ? item.activeIcon : item.icon,
                      color: selected ? _red : Colors.white54, size: 20),
                  title: Text(item.label,
                      style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13)),
                  selected: selected,
                  selectedTileColor: _red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.redAccent, size: 18),
            title: const Text('Sair', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            onTap: () { Navigator.pop(context); _logout(); },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return _buildAppointments();
      case 2: return _buildFinancialStats();
      case 3: return _buildBarbers();
      case 4: return _buildOffers();
      case 5: return _buildClients();
      case 6: return _buildRetencaoClientes();
      case 7: return _buildBarberShop();
      case 8: return _buildPosts();
      case 9: return _buildSettings();
      default: return const SizedBox.shrink();
    }
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  Widget _buildDashboard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return RefreshIndicator(
      color: _red,
      backgroundColor: _card,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardHeader(),
            const SizedBox(height: 24),
            _statsGrid(isMobile),
            const SizedBox(height: 24),
            isMobile
                ? Column(children: [_weeklyChart(), const SizedBox(height: 16), _servicesDonut()])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _weeklyChart()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _servicesDonut()),
                  ]),
            const SizedBox(height: 24),
            isMobile
                ? Column(children: [_recentAppointmentsWidget(), const SizedBox(height: 16), _recentClientsWidget()])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _recentAppointmentsWidget()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _recentClientsWidget()),
                  ]),
          ],
        ),
      ),
    );
  }

  Widget _dashboardHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting 👋', style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        _loadingStats
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _red, strokeWidth: 2))
            : IconButton(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_outlined, color: Colors.white54),
                tooltip: 'Actualizar',
              ),
      ],
    );
  }

Widget _statsGrid(bool isMobile) {
  final stats = [
    _StatData('Agendamentos hoje', '${_dashboardStats?['todayAppointments'] ?? 0}',
        Icons.calendar_today_outlined, const Color(0xFF3B82F6)),
    _StatData('Total Clientes', '${_dashboardStats?['activeBarbers'] ?? 0}',
        Icons.people_outline, const Color(0xFF10B981)),
    _StatData('Receita estimada hoje', '€${(_dashboardStats?['estimatedRevenue'] ?? 0.0).toStringAsFixed(2)}',
        Icons.euro_outlined, const Color(0xFFB22222)),
    _StatData('Total de cortes', '${_dashboardStats?['totalCuts'] ?? 0}',
        Icons.content_cut_outlined, const Color(0xFF8B5CF6)),
    _StatData('Receita total', '€${(_dashboardStats?['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
        Icons.bar_chart_outlined, const Color(0xFFF59E0B)),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Em telas muito estreitas (ex: 344px), 2 colunas com aspect ratio mais
      // baixo (cards mais altos) dão espaço suficiente para o texto de 2 linhas.
      final crossAxisCount = isMobile ? 2 : 5;
      final aspectRatio = width < 380 ? 1.05 : (isMobile ? 1.3 : 1.4);

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => _statCard(stats[i]),
      );
    },
  );
}
Widget _statCard(_StatData s) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // 👈 deixa de "esticar" para um tamanho fixo
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: s.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(s.icon, color: s.color, size: 18),
        ),
        const SizedBox(height: 10), // 👈 espaço fixo em vez do spaceBetween
        Text(s.value,
            style: TextStyle(color: s.color, fontSize: 20, fontWeight: FontWeight.w800), // 22 → 20
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(s.label,
            style: const TextStyle(color: Colors.white38, fontSize: 10.5), // 11 → 10.5
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
  Widget _weeklyChart() {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final maxY = (_weeklyData.isEmpty ? 1 : _weeklyData.reduce((a, b) => a > b ? a : b)).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agendamentos por semana',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Todos os agendamentos desta semana',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 5 : maxY * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY == 0 ? 5 : maxY * 1.3) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          days[v.toInt()],
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(_weeklyData.length, (i) {
                  final today = DateTime.now().weekday - 1;
                  final isToday = i == today;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyData[i].toDouble(),
                        color: isToday ? _red : _red.withOpacity(0.35),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _card2,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()} agendamentos',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesDonut() {
    final colors = [_red, const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6), const Color(0xFFF59E0B)];
    final total = _topServices.fold<int>(0, (s, e) => s + (e['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Serviços mais vendidos',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Com base nos agendamentos concluídos',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),
          if (_topServices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('Sem dados ainda', style: TextStyle(color: Colors.white38)),
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(_topServices.length, (i) {
                    final pct = total > 0 ? (_topServices[i]['count'] as int) / total * 100 : 0.0;
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: _topServices[i]['count'].toDouble(),
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_topServices.length, (i) {
              final s = _topServices[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s['name'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text('${s['count']}x',
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _recentAppointmentsWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Agendamentos recentes',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('todos →', style: TextStyle(color: _red, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AppointmentModel>>(
            stream: _adminController.getRecentAppointments(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _red, strokeWidth: 2),
                ));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Sem agendamentos', style: TextStyle(color: Colors.white38)),
                ));
              }
              return Column(
                children: items.take(5).map((a) => _recentApptRow(a)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentApptRow(AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _getStatusColor(a.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.content_cut, color: _getStatusColor(a.status), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.clientName,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${a.serviceName} · ${a.dateTime.day.toString().padLeft(2, '0')}/${a.dateTime.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getStatusColor(a.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(a.status),
              style: TextStyle(color: _getStatusColor(a.status), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentClientsWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clientes recentes',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 5),
                child: const Text('Ver todos →', style: TextStyle(color: _red, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentClients.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sem clientes', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            ..._recentClients.map((c) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _red.withOpacity(0.2),
                    child: Text(
                      (c['name'] as String? ?? '?').isNotEmpty
                          ? (c['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: _red, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] ?? 'Sem nome',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(c['email'] ?? '',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(
                    '${(c['points'] ?? 0).toStringAsFixed(0)} pts',
                    style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // ─── AGENDAMENTOS ─────────────────────────────────────────────────────────

  Widget _buildAppointments() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agendamentos',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildStatusFilters(isMobile),
          const SizedBox(height: 12),
          _buildDateFilters(isMobile),
          const SizedBox(height: 16),
          Expanded(child: _buildAppointmentsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Pesquisar cliente, serviço ou barbeiro...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
              )
            : null,
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStatusFilters(bool isMobile) {
    final statuses = ['Todos', 'pending', 'confirmed', 'completed', 'cancelled'];
    final labels = {'Todos': 'Todos', 'pending': 'Pendente', 'confirmed': 'Confirmado', 'completed': 'Concluído', 'cancelled': 'Cancelado'};

    if (isMobile) {
      return DropdownButtonFormField<String>(
        value: _selectedStatusFilter,
        onChanged: (v) => setState(() => _selectedStatusFilter = v!),
        items: statuses.map((s) => DropdownMenuItem(
          value: s,
          child: Text(labels[s]!, style: const TextStyle(color: Colors.white, fontSize: 13)),
        )).toList(),
        dropdownColor: _card2,
        style: const TextStyle(color: Colors.white),
        iconEnabledColor: Colors.white54,
        decoration: InputDecoration(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final selected = _selectedStatusFilter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatusFilter = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _red : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _red : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  labels[s]!,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFilters(bool isMobile) {
    Widget dateBtn(String label, DateTime? date, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: date != null ? _red.withOpacity(0.1) : _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: date != null ? _red.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: date != null ? _red : Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? _red : Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        dateBtn('Data início', _startDateFilter, () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _startDateFilter ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2030),
          );
          if (picked != null) setState(() => _startDateFilter = picked);
        }),
        const SizedBox(width: 8),
        dateBtn('Data fim', _endDateFilter, () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _endDateFilter ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2030),
          );
          if (picked != null) setState(() => _endDateFilter = picked);
        }),
        if (_startDateFilter != null || _endDateFilter != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() { _startDateFilter = null; _endDateFilter = null; }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.close, color: Colors.white38, size: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _adminController.getAllAppointments(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _red));
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}', style: const TextStyle(color: Colors.white54)));
        }
        final all = snap.data ?? [];
        final filtered = all.where((a) {
          final q = _searchQuery;
          final matchesQ = q.isEmpty ||
              a.clientName.toLowerCase().contains(q) ||
              a.serviceName.toLowerCase().contains(q) ||
              a.barberName.toLowerCase().contains(q);
          final matchesS = _selectedStatusFilter == 'Todos' || a.status == _selectedStatusFilter;
          final matchesD = (_startDateFilter == null || a.dateTime.isAfter(_startDateFilter!.subtract(const Duration(days: 1)))) &&
              (_endDateFilter == null || a.dateTime.isBefore(_endDateFilter!.add(const Duration(days: 1))));
          return matchesQ && matchesS && matchesD;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.white24, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Nenhum agendamento encontrado',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${filtered.length} agendamento${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _appointmentCard(filtered[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _appointmentCard(AppointmentModel a) {
    final end = a.dateTime.add(Duration(minutes: a.duration));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(a),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(a.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.content_cut, color: _getStatusColor(a.status), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a.clientName} · ${a.serviceName}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(a.barberName,
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(a.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_getStatusText(a.status),
                      style: TextStyle(color: _getStatusColor(a.status), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
           SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _apptInfoChip(Icons.calendar_today_outlined,
          '${a.dateTime.day.toString().padLeft(2, '0')}/${a.dateTime.month.toString().padLeft(2, '0')}/${a.dateTime.year}'),
      const SizedBox(width: 8),
      _apptInfoChip(Icons.access_time_outlined,
          '${_fmt(a.dateTime)} – ${_fmt(end)}'),
      const SizedBox(width: 8),
      _apptInfoChip(Icons.euro_outlined,
          '€${a.price.toStringAsFixed(2)}'),
    ],
  ),
),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (a.status == 'pending') ...[
                  _actionBtn(Icons.check, Colors.green, 'Confirmar', () => _confirmAppointment(a.id)),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.close, Colors.red, 'Cancelar', () => _cancelAppointment(a.id)),
                ],
                if (a.status == 'confirmed') ...[
                  _actionBtn(Icons.close, Colors.red, 'Cancelar', () => _cancelAppointment(a.id)),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.check_circle_outline, Colors.blue, 'Concluir', () => _completeAppointment(a.id)),
                ],
                if (a.status == 'cancelled')
                  _actionBtn(Icons.delete_outline, Colors.red, 'Apagar', () => _deleteAppointment(a.id)),
                if (a.status == 'completed')
                  _actionBtn(Icons.star_outline, Colors.amber, 'Pedir avaliação', () => _sendReviewRequest(a)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _apptInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ─── HELPERS E RESTANTES ──────────────────────────────────────────────────

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return const Color(0xFF3B82F6);
      case 'completed': return const Color(0xFF10B981);
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pendente';
      case 'confirmed': return 'Confirmado';
      case 'completed': return 'Concluído';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconhecido';
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _confirmAppointment(String id) async {
    final ok = await _confirmDialog('Confirmar agendamento?', 'O cliente receberá email de confirmação.', 'Confirmar', Colors.green);
    if (ok != true) return;
    try {
      await _adminController.confirmAppointment(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento confirmado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final ok = await _confirmDialog('Cancelar agendamento?', 'O cliente receberá email de cancelamento.', 'Cancelar', Colors.red);
    if (ok != true) return;
    try {
      await _adminController.cancelAppointment(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento cancelado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _completeAppointment(String id) async {
    final ok = await _confirmDialog('Marcar como concluído?', 'Pontos serão creditados ao cliente.', 'Concluir', Colors.blue);
    if (ok != true) return;
    try {
      await _adminController.completeAppointment(id);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento concluído')));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _deleteAppointment(String id) async {
    final ok = await _confirmDialog('Apagar agendamento?', 'Esta acção não pode ser desfeita.', 'Apagar', Colors.red);
    if (ok != true) return;
    try {
      await _adminController.deleteAppointment(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento apagado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _sendReviewRequest(AppointmentModel a) async {
    final email = await _adminController.getAppointmentClientEmail(a.id);
    final count = email.isNotEmpty ? await _adminController.getReviewRequestCount(email) : 0;
    final ok = await _confirmDialog(
      'Solicitar avaliação?',
      count == 0 ? 'Primeira solicitação para este cliente.' : 'Já foram enviadas $count solicitações anteriormente.',
      'Enviar',
      Colors.amber,
    );
    if (ok != true) return;
    try {
      await _adminController.sendReviewRequest(a.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<bool?> _confirmDialog(String title, String content, String action, Color actionColor) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  // Appointment details dialog — mantém lógica existente com novo visual
  void _showAppointmentDetails(AppointmentModel a) {
    final end = a.dateTime.add(Duration(minutes: a.duration));
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(a.status).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detalhes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(a.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_getStatusText(a.status),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _detailSection('Cliente', [
                        _detailRow('Nome', a.clientName),
                        _detailRow('Telefone', a.clientPhone),
                      ]),
                      const SizedBox(height: 12),
                      _detailSection('Serviço', [
                        _detailRow('Serviço', a.serviceName),
                        _detailRow('Barbeiro', a.barberName),
                        _detailRow('Duração', '${a.duration} min'),
                        _detailRow('Preço', '€${a.price.toStringAsFixed(2)}'),
                      ]),
                      const SizedBox(height: 12),
                      _detailSection('Horário', [
                        _detailRow('Data', '${a.dateTime.day.toString().padLeft(2, '0')}/${a.dateTime.month.toString().padLeft(2, '0')}/${a.dateTime.year}'),
                        _detailRow('Início', _fmt(a.dateTime)),
                        _detailRow('Fim', _fmt(end)),
                      ]),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (a.status == 'pending') ...[
                      _actionBtn(Icons.close, Colors.red, 'Cancelar', () { Navigator.pop(context); _cancelAppointment(a.id); }),
                      const SizedBox(width: 8),
                      _actionBtn(Icons.check, Colors.green, 'Confirmar', () { Navigator.pop(context); _confirmAppointment(a.id); }),
                    ],
                    if (a.status == 'confirmed') ...[
                      _actionBtn(Icons.close, Colors.red, 'Cancelar', () { Navigator.pop(context); _cancelAppointment(a.id); }),
                      const SizedBox(width: 8),
                      _actionBtn(Icons.check_circle_outline, Colors.blue, 'Concluir', () { Navigator.pop(context); _completeAppointment(a.id); }),
                    ],
                    if (a.status != 'pending' && a.status != 'confirmed')
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final isPhoneRow = label.toLowerCase().contains('telefone');
    if (isPhoneRow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
            Expanded(
              child: InkWell(
                onTap: () => _makePhoneCall(value),
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final raw = phoneNumber.trim();
    if (raw.isEmpty) return;

    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    final telUri = Uri(scheme: 'tel', path: cleaned);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback cross-platform: opens a call-like web/desktop handler via WhatsApp.
    // (On web/desktop this typically opens in browser; on mobile it may open WhatsApp.)
    final waUri = Uri.parse('https://wa.me/$cleaned');
    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }


  // ─── SECÇÕES EXISTENTES (mantém lógica, melhora wrapper) ──────────────────

  Widget _buildFinancialStats() => const FinancialStatsPage();
  Widget _buildBarbers() => const AdminProfissionaisPage();
  Widget _buildOffers() => const VipOffersPage();
  Widget _buildClients() => const ClientesPage();
  Widget _buildRetencaoClientes() => const RetencaoClientesPage();
  Widget _buildBarberShop() => const BarbeariasPage();
  Widget _buildPosts() => const PostsPage();
  Widget _buildSettings() => const SettingsPage();

  // ─── HELPERS RESTANTES (mantidos do original) ─────────────────────────────

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── DATA CLASSES ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}