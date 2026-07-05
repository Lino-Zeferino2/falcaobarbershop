import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Note: tipo auxiliar originalmente privado causava warning em public API.
// Mantemos público para evitar library_private_types_in_public_api.

class ProfessionalRevenueByDayData {
  final List<ProfessionalDataPoint> points;
  const ProfessionalRevenueByDayData(this.points);
}

class ProfessionalDataPoint {
  final DateTime date;
  final double value;
  const ProfessionalDataPoint({required this.date, required this.value});
}

class ProfessionalTopServicesData {
  final List<ProfessionalServicePoint> points;
  const ProfessionalTopServicesData(this.points);
}

class ProfessionalServicePoint {
  final String label;
  final double value;
  const ProfessionalServicePoint({required this.label, required this.value});
}



class ProfessionalChartsSectionWidget extends StatelessWidget {
  final ProfessionalRevenueByDayData revenueByDay;
  final ProfessionalTopServicesData topServices;
  const ProfessionalChartsSectionWidget({
    super.key,
    required this.revenueByDay,
    required this.topServices,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        _buildChartCard(
          title: 'Receita por Dia',
          icon: Icons.show_chart,
          child: _buildRevenueByDayChart(),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          title: 'Top Serviços (Receita)',
          icon: Icons.star,
          child: _buildTopServicesPieChart(),
        ),
        if (!isMobile) const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB22222)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRevenueByDayChart() {
    if (revenueByDay.points.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

final maxY = revenueByDay.points
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

final safeMaxY = (maxY <= 0 ? 1 : maxY * 1.15).toDouble();

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= revenueByDay.points.length) return const Text('');
                  final d = revenueByDay.points[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '€${value.toInt()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
          minX: 0,
          maxX: (revenueByDay.points.length - 1).toDouble(),
          minY: 0,
          maxY: safeMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: revenueByDay.points.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
              isCurved: true,
              color: const Color(0xFFB22222),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFB22222).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopServicesPieChart() {
    if (topServices.points.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final total = topServices.points.fold<double>(0, (sum, p) => sum + p.value);
    final points = topServices.points;

    final colors = [
      const Color(0xFFB22222),
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];

    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: points.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  final percent = total == 0 ? 0 : (p.value / total) * 100;
                  return PieChartSectionData(
                    color: colors[idx % colors.length],
value: p.value.toDouble(),
                    radius: 90,
                    title: '${percent.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: points.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  final c = colors[idx % colors.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                              Text(
                                '€${p.value.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

