import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/financial_stats_model.dart';

class StatsCardsWidget extends StatelessWidget {
  final FinancialStatsModel stats;

  const StatsCardsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
    
    final cards = [
      _buildStatCard(
        icon: Icons.euro,
        title: 'Total Faturado',
        value: '€${stats.totalRevenue.toStringAsFixed(2)}',
        color: const Color(0xFFB22222),
        subtitle: 'Receita total do período',
      ),
      _buildStatCard(
        icon: Icons.content_cut,
        title: 'Serviços Realizados',
        value: stats.totalServices.toString(),
        color: Colors.blue,
        subtitle: 'Total de atendimentos',
      ),
      _buildStatCard(
        icon: Icons.trending_up,
        title: 'Ticket Médio',
        value: '€${stats.averageTicket.toStringAsFixed(2)}',
        color: Colors.green,
        subtitle: 'Valor médio por serviço',
      ),
      _buildStatCard(
        icon: Icons.person_outline,
        title: 'Profissional Destaque',
        value: stats.mostProfitableProfessional,
        color: Colors.orange,
        subtitle: '€${stats.mostProfitableProfessionalRevenue.toStringAsFixed(2)} faturados',
        isTextValue: true,
      ),
      _buildStatCard(
        icon: Icons.calendar_today,
        title: 'Dia Mais Lucrativo',
        value: _formatDate(stats.mostProfitableDay),
        color: Colors.purple,
        subtitle: '€${stats.mostProfitableDayRevenue.toStringAsFixed(2)} faturados',
        isTextValue: true,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: card,
        )).toList(),
      );
    } else {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: cards.map((card) => SizedBox(
          width: isTablet 
              ? (MediaQuery.of(context).size.width - 32 - 16) / 2
              : (MediaQuery.of(context).size.width - 40 - 32) / 3,
          child: card,
        )).toList(),
      );
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr == 'N/A') return 'N/A';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: isTextValue ? 16 : 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
