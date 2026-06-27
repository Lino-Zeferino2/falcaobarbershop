import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../../../user/model/user_model.dart';

class ClientesFilterWidget extends StatefulWidget {
  final List<UserModel> allClientes;
  final Function(List<UserModel>) onFilteredClientesChanged;
  
  const ClientesFilterWidget({
    super.key, 
    required this.allClientes,
    required this.onFilteredClientesChanged,
  });

  @override
  State<ClientesFilterWidget> createState() => _ClientesFilterWidgetState();
}

class _ClientesFilterWidgetState extends State<ClientesFilterWidget> {
  final AdminController _adminController = AdminController();
  String _searchQuery = '';
  String? _selectedInactivityRange;

  final List<String> _inactivityRanges = ['1+ mês', '2+ meses', '3+ meses'];

  int _calculateMonthsSince(DateTime? lastAppointment) {
    if (lastAppointment == null) return 999;
    
    final now = DateTime.now();
    int months = (now.year - lastAppointment.year) * 12 + (now.month - lastAppointment.month);
    if (now.day < lastAppointment.day) months--;
    return months;
  }

  Future<List<UserModel>> _getFilteredClientes() async {
    var filtered = widget.allClientes.where((cliente) {
      final matchesSearch = cliente.name.toLowerCase().contains(_searchQuery) ||
                            cliente.email.toLowerCase().contains(_searchQuery) ||
                            cliente.phone.contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (_selectedInactivityRange != null) {
      final clienteIds = filtered.map((c) => c.uid).toList();
      final lastAppointmentsMap = await _adminController.getClientesLastAppointmentsMap(clienteIds);
      
      filtered = filtered.where((cliente) {
        final lastAppointment = lastAppointmentsMap[cliente.uid];
        final months = _calculateMonthsSince(lastAppointment);
        
        switch (_selectedInactivityRange) {
          case '1+ mês':
            return months >= 1;
          case '2+ meses':
            return months >= 2;
          case '3+ meses':
            return months >= 3;
          default:
            return true;
        }
      }).toList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFilteredClientesChanged(filtered);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _getFilteredClientes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            DropdownButton<String>(
              hint: const Text('Inatividade', style: TextStyle(color: Colors.white70)),
              value: _selectedInactivityRange,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: _inactivityRanges.map((range) => DropdownMenuItem(
                value: range,
                child: Text(range, style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInactivityRange = value;
                });
              },
            ),
            Text(
              '${snapshot.data?.length ?? 0} clientes filtrados',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}
