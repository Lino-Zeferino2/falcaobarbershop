import 'dart:convert';
// Conditional import for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show Blob, Url;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../user/model/user_model.dart';
import '../controller/admin_controller.dart';
import '../model/appointment_model.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final AdminController _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedPointsRange;
  String? _selectedAppointmentsRange;
  String? _selectedStatus;
  String? _selectedInactivityRange;

  final List<String> _pointsRanges = ['0-10', '11-50', '51-100', '100+'];
  final List<String> _appointmentsRanges = ['0-5', '6-20', '21-50', '50+'];
  final List<String> _inactivityRanges = ['1+ mês', '2+ meses', '3+ meses'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final showCards = isMobile || isTablet;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Gestão de Clientes', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportToCSV,
            tooltip: 'Exportar para CSV',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar clientes...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  DropdownButton<String>(
                    value: _selectedCity,
                    hint: const Text('Cidade', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _getUniqueCities().map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCity = value),
                  ),
                  DropdownButton<String>(
                    value: _selectedPointsRange,
                    hint: const Text('Pontos', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _pointsRanges.map((range) => DropdownMenuItem(
                      value: range,
                      child: Text(range, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedPointsRange = value),
                  ),
                  DropdownButton<String>(
                    value: _selectedAppointmentsRange,
                    hint: const Text('Agendamentos', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _appointmentsRanges.map((range) => DropdownMenuItem(
                      value: range,
                      child: Text(range, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedAppointmentsRange = value),
                  ),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    hint: const Text('Status', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Ativo', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'blocked', child: Text('Bloqueado', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (value) => setState(() => _selectedStatus = value),
                  ),
                  DropdownButton<String>(
                    value: _selectedInactivityRange,
                    hint: const Text('Inatividade', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _inactivityRanges.map((range) => DropdownMenuItem(
                      value: range,
                      child: Text(range, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedInactivityRange = value),
                  ),
                  if (_selectedCity != null || _selectedPointsRange != null || _selectedAppointmentsRange != null || _selectedStatus != null || _selectedInactivityRange != null)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar Filtros', style: TextStyle(color: Colors.blue)),
                    ),
                ],
              ),
            ),
            // Client count display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: StreamBuilder<List<UserModel>>(
                stream: _adminController.getAllClientes(),
                builder: (context, snapshot) {
                  final clientes = snapshot.data ?? [];
                  final filteredCount = _filterClientes(clientes).length;
                  return Text(
                    '${_searchQuery.isNotEmpty ? "Procurando por '$_searchQuery'" : "Clientes"} ($filteredCount de ${clientes.length})',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  );
                },
              ),
            ),
            // Table header (only for desktop)
            if (!showCards)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF2A2A2A),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Nome', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Telefone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Cidade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Pontos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Último Agendamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Ações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            // Table content
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _adminController.getAllClientes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  final clientes = snapshot.data ?? [];
                  var filteredClientes = _filterClientes(clientes);

                  // Inactivity filter will be handled by separate FutureBuilder
                  if (_selectedInactivityRange != null) {
                    // Trigger rebuild with FutureBuilder for inactivity filter
                  }

                  if (filteredClientes.isEmpty) {
                    return const Center(child: Text('Nenhum cliente encontrado', style: TextStyle(color: Colors.white)));
                  }

                  if (isMobile) {
                    // Mobile: List of cards
                    return ListView.builder(
                      itemCount: filteredClientes.length,
                      itemBuilder: (context, index) {
                        final cliente = filteredClientes[index];
                        return Card(
                          color: const Color(0xFF2A2A2A),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cliente.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _infoRow(Icons.email, 'Email', cliente.email),
                                const SizedBox(height: 4),
                                _infoRow(Icons.phone, 'Telefone', cliente.phone),
                                const SizedBox(height: 4),
                                _infoRow(Icons.location_city, 'Cidade', cliente.city),
                                const SizedBox(height: 4),
                                _infoRow(Icons.star, 'Pontos', cliente.points.toString()),
                                const SizedBox(height: 4),
                                FutureBuilder<AppointmentModel?>(
                                  future: _adminController.getClienteLastAppointment(cliente.uid),
                                  builder: (context, snapshot) {
                                    final lastAppointment = snapshot.data;
                                    return _infoRow(Icons.calendar_today, 'Último Agendamento',
                                      lastAppointment != null
                                        ? '${lastAppointment.dateTime.day}/${lastAppointment.dateTime.month}/${lastAppointment.dateTime.year}'
                                        : 'N/A');
                                  },
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: isTablet ? 16 : 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.visibility, size: screenWidth >= 1024 ? 18 : (isTablet ? 20 : 16)),
                                      label: Text((isTablet && screenWidth < 1024) ? 'Ver' : ''),
                                      onPressed: () => _showClienteDetails(context, cliente),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: screenWidth >= 1024 ? 12 : (isTablet ? 16 : 8), vertical: screenWidth >= 1024 ? 10 : (isTablet ? 12 : 8)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.edit, size: screenWidth >= 1024 ? 18 : (isTablet ? 20 : 16)),
                                      label: Text((isTablet && screenWidth < 1024) ? 'Editar' : ''),
                                      onPressed: () => _showEditClienteDialog(context, cliente),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: screenWidth >= 1024 ? 12 : (isTablet ? 16 : 8), vertical: screenWidth >= 1024 ? 10 : (isTablet ? 12 : 8)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.delete, size: screenWidth >= 1024 ? 18 : (isTablet ? 20 : 16)),
                                      label: Text((isTablet && screenWidth < 1024) ? 'Excluir' : ''),
                                      onPressed: () => _confirmDeleteCliente(context, cliente),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: screenWidth >= 1024 ? 12 : (isTablet ? 16 : 8), vertical: screenWidth >= 1024 ? 10 : (isTablet ? 12 : 8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    // Desktop: Table rows
                    return ListView.builder(
                      itemCount: filteredClientes.length,
                      itemBuilder: (context, index) {
                        final cliente = filteredClientes[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(cliente.name, style: const TextStyle(color: Colors.white)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(cliente.email, style: const TextStyle(color: Colors.white)),
                              ),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () => _makePhoneCall(cliente.phone),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone, color: Colors.green, size: 14),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(cliente.phone, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(cliente.city, style: const TextStyle(color: Colors.white)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(cliente.points.toString(), style: const TextStyle(color: Colors.white)),
                              ),
                              Expanded(
                                flex: 1,
                                child: FutureBuilder<AppointmentModel?>(
                                  future: _adminController.getClienteLastAppointment(cliente.uid),
                                  builder: (context, snapshot) {
                                    final lastAppointment = snapshot.data;
                                    return Text(
                                      lastAppointment != null
                                        ? '${lastAppointment.dateTime.day}/${lastAppointment.dateTime.month}/${lastAppointment.dateTime.year}'
                                        : 'N/A',
                                      style: const TextStyle(color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.blue),
                                      onPressed: () => _showClienteDetails(context, cliente),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.green),
                                      onPressed: () => _showEditClienteDialog(context, cliente),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDeleteCliente(context, cliente),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueCities() {
    return ['Lisboa', 'Porto', 'Coimbra', 'Faro', 'Aveiro'];
  }

  List<UserModel> _filterClientes(List<UserModel> clientes) {
    // For inactivity filter, we need to handle it differently since it requires async data
    // For now, we'll apply basic filters only and let the inactivity filter be informational
    return clientes.where((cliente) {
      final matchesSearch = cliente.name.toLowerCase().contains(_searchQuery) ||
                            cliente.email.toLowerCase().contains(_searchQuery) ||
                            cliente.phone.contains(_searchQuery);

      final matchesCity = _selectedCity == null || cliente.city == _selectedCity;

      final matchesPoints = _selectedPointsRange == null || _matchesRange(cliente.points, _selectedPointsRange!);

      final matchesStatus = _selectedStatus == null || (cliente.toMap()['blocked'] == (_selectedStatus == 'blocked'));

      // Inactivity filter - for now we skip this in the sync filter since it requires async data
      // The display still shows the last appointment date from the FutureBuilder
      final matchesAppointments = _selectedAppointmentsRange == null;

      return matchesSearch && matchesCity && matchesPoints && matchesStatus && matchesAppointments;
    }).toList();
  }

  bool _matchesRange(double value, String range) {
    switch (range) {
      case '0-10': return value >= 0 && value <= 10;
      case '11-50': return value >= 11 && value <= 50;
      case '51-100': return value >= 51 && value <= 100;
      case '100+': return value > 100;
      default: return true;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedPointsRange = null;
      _selectedAppointmentsRange = null;
      _selectedStatus = null;
      _selectedInactivityRange = null;
    });
  }


  void _exportToCSV() async {
    try {
      final allClientes = await _adminController.getAllClientes().first;
      final filteredClientes = _filterClientes(allClientes);

      if (filteredClientes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum cliente encontrado para exportar')),
        );
        return;
      }

      if (kIsWeb) {
        try {
          final csv = await _generateClientesCSV(filteredClientes);
          final bytes = utf8.encode(csv);

          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);

          html.Url.revokeObjectUrl(url);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Relatório de clientes exportado com sucesso!')),
          );
        } catch (e) {
          print('Error exporting CSV: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao exportar CSV: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportação CSV disponível apenas na versão web')),
        );
      }
    } catch (e) {
      print('Error getting clients for export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao preparar dados para exportação: $e')),
      );
    }
  }

  Future<String> _generateClientesCSV(List<UserModel> clientes) async {
    final buffer = StringBuffer();

    buffer.writeln('RELATÓRIO DE CLIENTES');
    buffer.writeln('Gerado em: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('Total de Clientes: ${clientes.length}');
    buffer.writeln('');

    final totalPoints = clientes.fold<double>(0.0, (sum, c) => sum + c.points);
    final avgPoints = clientes.isNotEmpty ? totalPoints / clientes.length : 0.0;
    final activeClients = clientes.where((c) => !(c.toMap()['blocked'] ?? false)).length;
    final blockedClients = clientes.length - activeClients;

    buffer.writeln('RESUMO');
    buffer.writeln('Total de Pontos: ${totalPoints.toStringAsFixed(0)}');
    buffer.writeln('Pontos Médios: ${avgPoints.toStringAsFixed(2)}');
    buffer.writeln('Clientes Ativos: $activeClients');
    buffer.writeln('Clientes Bloqueados: $blockedClients');
    buffer.writeln('');

    buffer.writeln('Nome,Email,Telefone,Cidade,Pontos,Data de Criação,Status,Último Agendamento,Total de Agendamentos');

    for (var cliente in clientes) {
      final status = (cliente.toMap()['blocked'] ?? false) ? 'Bloqueado' : 'Ativo';
      final createdDate = cliente.createdAt.toLocal();
      final createdDateStr = '${createdDate.day.toString().padLeft(2, '0')}/${createdDate.month.toString().padLeft(2, '0')}/${createdDate.year}';

      String lastAppointmentStr = 'N/A';
      try {
        final lastAppointment = await _adminController.getClienteLastAppointment(cliente.uid);
        if (lastAppointment != null) {
          final date = lastAppointment.dateTime.toLocal();
          lastAppointmentStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
      } catch (e) {}

      int totalAppointments = 0;
      try {
        totalAppointments = await _adminController.getClienteAppointmentsCount(cliente.uid);
      } catch (e) {}

      buffer.writeln(
        '"${cliente.name}","${cliente.email}","${cliente.phone}","${cliente.city}","${cliente.points.toStringAsFixed(0)}","$createdDateStr","$status","$lastAppointmentStr","$totalAppointments"'
      );
    }

    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showClienteDetails(BuildContext context, UserModel cliente) {
    showDialog(
      context: context,
      builder: (context) => ClienteDetailsDialog(cliente: cliente, adminController: _adminController),
    );
  }

  void _showEditClienteDialog(BuildContext context, UserModel cliente) {
    showDialog(
      context: context,
      builder: (context) => EditClienteDialog(cliente: cliente, adminController: _adminController),
    );
  }

  void _confirmDeleteCliente(BuildContext context, UserModel cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir ${cliente.name}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminController.deleteCliente(cliente.uid);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente excluído com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir cliente: $e')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) {
    // Show a snackbar with the phone number (in a real app, you could use url_launcher)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ligar para: $phoneNumber')),
    );
  }
}

class ClienteDetailsDialog extends StatefulWidget {
  final UserModel cliente;
  final AdminController adminController;

  const ClienteDetailsDialog({super.key, required this.cliente, required this.adminController});

  @override
  State<ClienteDetailsDialog> createState() => _ClienteDetailsDialogState();
}

class _ClienteDetailsDialogState extends State<ClienteDetailsDialog> {
  late bool _isBlocked;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.cliente.toMap()['blocked'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Detalhes do Cliente', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                const Text('Informações Pessoais', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _infoRow(Icons.person, 'Nome', widget.cliente.name),
                            const SizedBox(height: 8),
                            _infoRow(Icons.email, 'Email', widget.cliente.email),
                            const SizedBox(height: 8),
                            _infoRow(Icons.phone, 'Telefone', widget.cliente.phone),
                            const SizedBox(height: 8),
                            _infoRow(Icons.location_city, 'Cidade', widget.cliente.city),
                            const SizedBox(height: 8),
                            _infoRow(Icons.calendar_today, 'Data de Criação', widget.cliente.createdAt.toLocal().toString().split(' ')[0]),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.block, color: _isBlocked ? Colors.red : Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text('Status: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                Text(_isBlocked ? 'Bloqueado' : 'Ativo', style: TextStyle(color: _isBlocked ? Colors.red : Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bar_chart, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text('Estatísticas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard('Pontos', widget.cliente.points.toString(), Icons.star, Colors.amber),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FutureBuilder<int>(
                                    future: widget.adminController.getClienteAppointmentsCount(widget.cliente.uid),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      return _statCard('Agendamentos', count.toString(), Icons.calendar_today, Colors.blue);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                const Text('Últimos Agendamentos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<List<AppointmentModel>>(
                              future: widget.adminController.getClienteAppointmentsHistory(widget.cliente.uid, limit: 5),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final appointments = snapshot.data ?? [];
                                if (appointments.isEmpty) {
                                  return const Text('Nenhum agendamento encontrado', style: TextStyle(color: Colors.white70));
                                }
                                return Column(
                                  children: appointments.map((appt) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cut, color: Colors.white70, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${appt.serviceName} - ${appt.barberName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              Text('${appt.dateTime.toLocal().toString().split(' ')[0]} - ${appt.status}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(appt.status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusText(appt.status),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _showFullHistoryDialog(context, widget.cliente, widget.adminController),
                                icon: const Icon(Icons.expand_more, color: Colors.blue),
                                label: const Text('Ver histórico completo', style: TextStyle(color: Colors.blue)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final isMobile = MediaQuery.of(context).size.width < 768;
                return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showAddPointsDialog(context, widget.cliente, widget.adminController),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Pontos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _confirmResetPoints(context, widget.cliente, widget.adminController),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resetar Pontos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _confirmBlockCliente(context, widget.cliente, widget.adminController, () => setState(() => _isBlocked = !_isBlocked)),
                          icon: const Icon(Icons.block),
                          label: Text(_isBlocked ? 'Desbloquear' : 'Bloquear'),
                          style: ElevatedButton.styleFrom(backgroundColor: _isBlocked ? Colors.green : Colors.red),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                          label: const Text('Fechar', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                          label: const Text('Fechar', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPointsDialog(context, widget.cliente, widget.adminController),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Pontos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _confirmResetPoints(context, widget.cliente, widget.adminController),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resetar Pontos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _confirmBlockCliente(context, widget.cliente, widget.adminController, () => setState(() => _isBlocked = !_isBlocked)),
                          icon: const Icon(Icons.block),
                          label: Text(_isBlocked ? 'Desbloquear' : 'Bloquear'),
                          style: ElevatedButton.styleFrom(backgroundColor: _isBlocked ? Colors.green : Colors.red),
                        ),
                      ],
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'completed': return Colors.green;
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

  void _showAddPointsDialog(BuildContext context, UserModel cliente, AdminController adminController) {
    int selectedPoints = 10;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text('Adicionar Pontos a ${cliente.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecione a quantidade de pontos a adicionar:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [10, 20, 30, 40, 50, 100].map((points) => ChoiceChip(
                  label: Text('$points', style: const TextStyle(color: Colors.white)),
                  selected: selectedPoints == points,
                  onSelected: (selected) {
                    if (selected) setState(() => selectedPoints = points);
                  },
                  backgroundColor: const Color(0xFF1A1A1A),
                  selectedColor: Colors.purple,
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await adminController.addPoints(cliente.uid, selectedPoints);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$selectedPoints pontos adicionados com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao adicionar pontos: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetPoints(BuildContext context, UserModel cliente, AdminController adminController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar Reset de Pontos', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja resetar os pontos de ${cliente.name}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await adminController.resetPoints(cliente.uid);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pontos resetados com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Resetar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmBlockCliente(BuildContext context, UserModel cliente, AdminController adminController, [VoidCallback? onBlockChanged]) {
    final isBlocked = _isBlocked;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(isBlocked ? 'Confirmar Desbloqueio' : 'Confirmar Bloqueio', style: TextStyle(color: Colors.white)),
        content: Text(isBlocked ? 'Tem certeza que deseja desbloquear ${cliente.name}?' : 'Tem certeza que deseja bloquear ${cliente.name}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await adminController.blockCliente(cliente.uid, !isBlocked);
                onBlockChanged?.call();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBlocked ? 'Cliente desbloqueado!' : 'Cliente bloqueado!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: Text(isBlocked ? 'Desbloquear' : 'Bloquear', style: TextStyle(color: isBlocked ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFullHistoryDialog(BuildContext context, UserModel cliente, AdminController adminController) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text('Histórico Completo', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<AppointmentModel>>(
                  future: adminController.getClienteAppointmentsHistory(cliente.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                    }
                    final appointments = snapshot.data ?? [];
                    if (appointments.isEmpty) {
                      return const Center(child: Text('Nenhum agendamento encontrado', style: TextStyle(color: Colors.white70)));
                    }
                    return ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appt = appointments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cut, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${appt.serviceName} - ${appt.barberName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text('${appt.dateTime.toLocal().toString().split(' ')[0]} - ${appt.status}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appt.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(appt.status),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                label: const Text('Fechar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditClienteDialog extends StatefulWidget {
  final UserModel cliente;
  final AdminController adminController;

  const EditClienteDialog({super.key, required this.cliente, required this.adminController});

  @override
  State<EditClienteDialog> createState() => _EditClienteDialogState();
}

class _EditClienteDialogState extends State<EditClienteDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cliente.name);
    _emailController = TextEditingController(text: widget.cliente.email);
    _phoneController = TextEditingController(text: widget.cliente.phone);
    _cityController = TextEditingController(text: widget.cliente.city);
    _isBlocked = widget.cliente.toMap()['blocked'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Editar Cliente: ${widget.cliente.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Telefone',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Cidade',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Bloqueado:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Switch(
                  value: _isBlocked,
                  onChanged: (value) => setState(() => _isBlocked = value),
                  activeColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    try {
      final updatedCliente = UserModel(
        uid: widget.cliente.uid,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        points: widget.cliente.points,
        createdAt: widget.cliente.createdAt,
        role: widget.cliente.role,
      );
      await widget.adminController.updateCliente(updatedCliente);
      if (_isBlocked != (widget.cliente.toMap()['blocked'] ?? false)) {
        await widget.adminController.blockCliente(widget.cliente.uid, _isBlocked);
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente atualizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar cliente: $e')),
      );
    }
  }
}
