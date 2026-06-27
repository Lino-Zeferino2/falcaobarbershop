import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/financial_stats_model.dart';

class StatsFiltersWidget extends StatefulWidget {
  final FilterModel currentFilter;
  final List<Map<String, String>> professionals;
  final List<Map<String, String>> barbershops;
  final Function(FilterModel) onFilterChanged;
  final VoidCallback onApplyFilters;

  const StatsFiltersWidget({
    super.key,
    required this.currentFilter,
    required this.professionals,
    required this.barbershops,
    required this.onFilterChanged,
    required this.onApplyFilters,
  });

  @override
  State<StatsFiltersWidget> createState() => _StatsFiltersWidgetState();
}

class _StatsFiltersWidgetState extends State<StatsFiltersWidget> {
  late FilterModel _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  void didUpdateWidget(StatsFiltersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilter != widget.currentFilter) {
      setState(() {
        _filter = widget.currentFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFFB22222)),
              const SizedBox(width: 8),
              const Text(
                'Filtros',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // View Mode Toggle
          _buildViewModeToggle(),
          const SizedBox(height: 20),

          // Filters Grid
          if (isMobile)
            Column(
              children: [
                _buildPeriodFilter(),
                const SizedBox(height: 16),
                if (_filter.periodFilter == PeriodFilter.custom) ...[
                  _buildCustomDateRange(),
                  const SizedBox(height: 16),
                ],
                _buildProfessionalFilter(),
                const SizedBox(height: 16),
                _buildBarbershopFilter(),
              ],
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: _buildPeriodFilter(),
                ),
                if (_filter.periodFilter == PeriodFilter.custom) ...[
                  SizedBox(
                    width: 200,
                    child: _buildCustomDatePicker(true),
                  ),
                  SizedBox(
                    width: 200,
                    child: _buildCustomDatePicker(false),
                  ),
                ],
                SizedBox(
                  width: 250,
                  child: _buildProfessionalFilter(),
                ),
                SizedBox(
                  width: 250,
                  child: _buildBarbershopFilter(),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onFilterChanged(_filter);
                widget.onApplyFilters();
              },
              icon: const Icon(Icons.check),
              label: const Text('Aplicar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modo de Visualização',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ViewMode>(
          segments: const [
            ButtonSegment<ViewMode>(
              value: ViewMode.real,
              label: Text('Valores Reais'),
              icon: Icon(Icons.check_circle),
            ),
            ButtonSegment<ViewMode>(
              value: ViewMode.estimated,
              label: Text('Valores Estimados'),
              icon: Icon(Icons.schedule),
            ),
          ],
          selected: {_filter.viewMode},
          onSelectionChanged: (Set<ViewMode> newSelection) {
            setState(() {
              _filter = _filter.copyWith(
                viewMode: newSelection.first,
                periodFilter: newSelection.first == ViewMode.real ? PeriodFilter.always : _filter.periodFilter,
              );
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFB22222);
                }
                return const Color(0xFF1A1A1A);
              },
            ),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _filter.viewMode == ViewMode.real
              ? 'Mostra serviços concluídos desde sempre (status = completed)'
              : 'Mostra serviços confirmados (status = confirmed)',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PeriodFilter>(
          value: _filter.periodFilter,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _filter = _filter.copyWith(
                  periodFilter: value,
                  clearCustomDates: value != PeriodFilter.custom,
                );
              });
            }
          },
          items: PeriodFilter.values.map((period) {
            String label;
            switch (period) {
              case PeriodFilter.today:
                label = 'Hoje';
                break;
              case PeriodFilter.thisWeek:
                label = 'Esta Semana';
                break;
              case PeriodFilter.thisMonth:
                label = 'Este Mês';
                break;
              case PeriodFilter.thisYear:
                label = 'Este Ano';
                break;
              case PeriodFilter.always:
                label = 'Sempre';
                break;
              case PeriodFilter.custom:
                label = 'Personalizado';
                break;
            }
            return DropdownMenuItem(
              value: period,
              child: Text(label),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildCustomDateRange() {
    return Column(
      children: [
        _buildCustomDatePicker(true),
        const SizedBox(height: 16),
        _buildCustomDatePicker(false),
      ],
    );
  }

  Widget _buildCustomDatePicker(bool isStart) {
    final date = isStart ? _filter.customStartDate : _filter.customEndDate;
    final label = isStart ? 'Data Inicial' : 'Data Final';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                if (isStart) {
                  _filter = _filter.copyWith(customStartDate: picked);
                } else {
                  _filter = _filter.copyWith(customEndDate: picked);
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Selecionar data',
                  style: TextStyle(
                    color: date != null ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profissional',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _filter.professionalId,
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(
                professionalId: value,
                clearProfessional: value == null,
              );
            });
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos', overflow: TextOverflow.ellipsis),
            ),
            ...widget.professionals.map((prof) {
              return DropdownMenuItem<String?>(
                value: prof['id'],
                child: Text(
                  prof['name']!,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildBarbershopFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Barbearia',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _filter.barbershopId,
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(
                barbershopId: value,
                clearBarbershop: value == null,
              );
            });
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas', overflow: TextOverflow.ellipsis),
            ),
            ...widget.barbershops.map((shop) {
              return DropdownMenuItem<String?>(
                value: shop['id'],
                child: Text(
                  shop['name']!,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white70,
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = FilterModel(
        viewMode: ViewMode.real,
        periodFilter: PeriodFilter.always,
      );
    });
    widget.onFilterChanged(_filter);
  }
}
