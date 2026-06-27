import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../controller/financial_stats_controller.dart';
import '../model/financial_stats_model.dart';
import '../widgets/stats_filters_widget.dart';
import '../widgets/stats_cards_widget.dart';
import '../widgets/charts_section_widget.dart';

// Conditional import for web
import 'dart:html' as html show Blob, Url, AnchorElement;

class FinancialStatsPage extends StatefulWidget {
  const FinancialStatsPage({super.key});

  @override
  State<FinancialStatsPage> createState() => _FinancialStatsPageState();
}

class _FinancialStatsPageState extends State<FinancialStatsPage> {
  final FinancialStatsController _controller = FinancialStatsController();

  FilterModel _currentFilter = FilterModel(
    viewMode: ViewMode.real,
    periodFilter: PeriodFilter.always,
  );
  FinancialStatsModel? _stats;
  RevenueByDayData? _revenueByDay;
  RevenueByProfessionalData? _revenueByProfessional;
  TopServicesData? _topServices;
  
  List<Map<String, String>> _professionals = [];
  List<Map<String, String>> _barbershops = [];
  
  bool _isLoading = true;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load filter options
      final professionals = await _controller.getAllProfessionals();
      final barbershops = await _controller.getAllBarbershops();
      
      setState(() {
        _professionals = professionals;
        _barbershops = barbershops;
      });
      
      // Load initial stats
      await _loadStats();
    } catch (e) {
      print('Error loading initial data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingData = true);
    
    try {
      final stats = await _controller.getFinancialStats(_currentFilter);
      final revenueByDay = await _controller.getRevenueByDayData(_currentFilter);
      final revenueByProfessional = await _controller.getRevenueByProfessionalData(_currentFilter);
      final topServices = await _controller.getTopServicesData(_currentFilter);
      
      setState(() {
        _stats = stats;
        _revenueByDay = revenueByDay;
        _revenueByProfessional = revenueByProfessional;
        _topServices = topServices;
      });
    } catch (e) {
      print('Error loading stats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estatísticas: $e')),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  void _exportToCSV() {
    if (_stats == null || _stats!.bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar')),
      );
      return;
    }

    // Check if running on web platform
    if (kIsWeb) {
      try {
        final csv = _controller.exportToCSV(_stats!.bookings, _currentFilter);
        final bytes = utf8.encode(csv);

        // Web-specific code using dart:html
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Generate filename with filter info
        final viewMode = _currentFilter.viewMode == ViewMode.real ? 'reais' : 'estimados';
        final period = _currentFilter.getPeriodLabel().toLowerCase().replaceAll(' ', '_');
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'relatorio_financeiro_${viewMode}_${period}_$timestamp.csv')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório CSV exportado com sucesso!')),
        );
      } catch (e) {
        print('Error exporting CSV: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar CSV: $e')),
        );
      }
    } else {
      // Mobile platforms - show message that export is web-only
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exportação CSV disponível apenas na versão web')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFB22222),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Color(0xFFB22222),
                size: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas Financeiras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Análise detalhada de receitas e serviços',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: _stats != null && _stats!.bookings.isNotEmpty
                      ? _exportToCSV
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          StatsFiltersWidget(
            currentFilter: _currentFilter,
            professionals: _professionals,
            barbershops: _barbershops,
            onFilterChanged: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            onApplyFilters: _loadStats,
          ),
          const SizedBox(height: 24),

          // Export button for mobile
          if (isMobile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stats != null && _stats!.bookings.isNotEmpty
                    ? _exportToCSV
                    : null,
                icon: const Icon(Icons.download),
                label: const Text('Exportar CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (isMobile) const SizedBox(height: 24),

          // Loading indicator
          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  color: Color(0xFFB22222),
                ),
              ),
            )
          else if (_stats != null) ...[
            // Stats Cards
            StatsCardsWidget(stats: _stats!),
            const SizedBox(height: 24),

            // Charts
            if (_revenueByDay != null &&
                _revenueByProfessional != null &&
                _topServices != null)
              ChartsSectionWidget(
                revenueByDay: _revenueByDay!,
                revenueByProfessional: _revenueByProfessional!,
                topServices: _topServices!,
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum dado encontrado',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajuste os filtros para visualizar as estatísticas',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
