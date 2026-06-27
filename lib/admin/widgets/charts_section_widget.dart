import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../model/financial_stats_model.dart';

class ChartsSectionWidget extends StatelessWidget {
  final RevenueByDayData revenueByDay;
  final RevenueByProfessionalData revenueByProfessional;
  final TopServicesData topServices;

  const ChartsSectionWidget({
    super.key,
    required this.revenueByDay,
    required this.revenueByProfessional,
    required this.topServices,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        // Revenue by Day Chart
        _buildChartContainer(
          title: 'Faturação por Dia',
          icon: Icons.show_chart,
          child: _buildRevenueByDayChart(),
        ),
        const SizedBox(height: 20),

        // Revenue by Professional and Top Services
        if (isMobile)
          Column(
            children: [
              _buildChartContainer(
                title: 'Receita por Profissional',
                icon: Icons.person,
                child: _buildRevenueByProfessionalChart(),
              ),
              const SizedBox(height: 20),
              _buildChartContainer(
                title: 'Serviços Mais Vendidos',
                icon: Icons.star,
                child: _buildTopServicesChart(),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartContainer(
                  title: 'Receita por Profissional',
                  icon: Icons.person,
                  child: _buildRevenueByProfessionalChart(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildChartContainer(
                  title: 'Serviços Mais Vendidos',
                  icon: Icons.star,
                  child: _buildTopServicesChart(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChartContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRevenueByDayChart() {
    if (revenueByDay.dataPoints.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white10,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < revenueByDay.dataPoints.length) {
                    final date = revenueByDay.dataPoints[value.toInt()].date!;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white10),
          ),
          minX: 0,
          maxX: (revenueByDay.dataPoints.length - 1).toDouble(),
          minY: 0,
          maxY: revenueByDay.dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: revenueByDay.dataPoints.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
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

  Widget _buildRevenueByProfessionalChart() {
    if (revenueByProfessional.dataPoints.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // Take top 10 professionals
    final topProfessionals = revenueByProfessional.dataPoints.take(10).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topProfessionals.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topProfessionals[group.x.toInt()].label}\n€${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < topProfessionals.length) {
                    final name = topProfessionals[value.toInt()].label;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          name.length > 15 ? '${name.substring(0, 15)}...' : name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  }
                  return const Text('');
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white10),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white10,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: topProfessionals.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: const Color(0xFFB22222),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopServicesChart() {
    if (topServices.dataPoints.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final total = topServices.dataPoints.fold<double>(0, (sum, item) => sum + item.value);

    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: topServices.dataPoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage = (data.value / total * 100);
                  
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

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: data.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 80,
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
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topServices.dataPoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '€${data.value.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
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
