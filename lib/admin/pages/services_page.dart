import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore_instance.dart';
import '../model/service_model.dart';
import '../model/appointment_model.dart';
import '../../services/email_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Gestão de Serviços', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showServiceDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar serviços...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: Text(_showActiveOnly ? 'Ativos' : 'Todos', style: const TextStyle(color: Colors.white)),
                  selected: _showActiveOnly,
                  onSelected: (selected) => setState(() => _showActiveOnly = selected),
                  backgroundColor: const Color(0xFF2A2A2A),
                  selectedColor: const Color(0xFFB22222),
                  checkmarkColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('servicos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final services = snapshot.data?.docs ?? [];
                final filteredServices = services.where((doc) {
                  final service = ServiceModel.fromMap(doc.data() as Map<String, dynamic>);
                  final matchesSearch = service.nome.toLowerCase().contains(_searchController.text.toLowerCase());
                  final matchesFilter = !_showActiveOnly || service.ativo;
                  return matchesSearch && matchesFilter;
                }).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 3 : (constraints.maxWidth > 350 ? 2 : 1);
                    final childAspectRatio = constraints.maxWidth < 450 ? 0.6 : 0.8;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final doc = filteredServices[index];
                        final service = ServiceModel.fromMap(doc.data() as Map<String, dynamic>);
                        return _buildServiceCard(service, doc.id, constraints.maxWidth);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB22222),
        onPressed: () => _showServiceDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service, String docId, double screenWidth) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: screenWidth < 350 ? 60 : (screenWidth < 400 ? 80 : 120),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: const Color(0xFFB22222),
            ),
            child: Icon(
              _getIconData(service.iconName),
              color: Colors.white,
              size: screenWidth < 350 ? 30 : (screenWidth < 400 ? 40 : 60),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  service.descricao,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '€${service.preco.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFB22222),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${service.duracao} min',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: service.ativo,
                      onChanged: (value) => _toggleServiceStatus(docId, value),
                      activeColor: const Color(0xFFB22222),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.white70, size: screenWidth < 400 ? 16 : 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showServiceDialog(service: service, docId: docId),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: screenWidth < 400 ? 16 : 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteService(docId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut;
      case 'face':
        return Icons.face;
      case 'spa':
        return Icons.spa;
      case 'brush':
        return Icons.brush;
      case 'local_bar':
        return Icons.local_bar;
      case 'local_drink':
        return Icons.local_drink;
      default:
        return Icons.content_cut;
    }
  }

  void _showServiceDialog({ServiceModel? service, String? docId}) {
    final isEditing = service != null;
    final nomeController = TextEditingController(text: service?.nome ?? '');
    final descricaoController = TextEditingController(text: service?.descricao ?? '');
    final precoController = TextEditingController(text: service?.preco.toString() ?? '');
    final duracaoController = TextEditingController(text: service?.duracao.toString() ?? '');
    String selectedIconName = service?.iconName ?? 'content_cut';
    bool ativo = service?.ativo ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            isEditing ? 'Editar Serviço' : 'Novo Serviço',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedIconName,
                  items: const [
                    DropdownMenuItem(value: 'content_cut', child: Text('Corte de Cabelo', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'face', child: Text('Tratamento Facial', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'spa', child: Text('Spa', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'brush', child: Text('Penteado', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'local_bar', child: Text('Barba', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'local_drink', child: Text('Bebida', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (value) => setState(() => selectedIconName = value!),
                  decoration: const InputDecoration(
                    labelText: 'Ícone',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descricaoController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: precoController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Preço (€)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB22222)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: duracaoController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duração (min)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB22222)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ativo', style: TextStyle(color: Colors.white)),
                  value: ativo,
                  onChanged: (value) => setState(() => ativo = value),
                  activeColor: const Color(0xFFB22222),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => _saveService(
                nomeController.text,
                descricaoController.text,
                double.tryParse(precoController.text) ?? 0.0,
                int.tryParse(duracaoController.text) ?? 0,
                selectedIconName,
                ativo,
                docId: docId,
                oldService: service,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveService(
    String nome,
    String descricao,
    double preco,
    int duracao,
    String iconName,
    bool ativo, {
    String? docId,
    ServiceModel? oldService,
  }) async {
    if (nome.isEmpty || preco <= 0 || duracao <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    try {
      final serviceData = {
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'duracao': duracao,
        'iconName': iconName,
        'ativo': ativo,
        'atualizadoEm': DateTime.now().toIso8601String(),
      };

      if (docId != null) {
        // Update existing
        List<AppointmentModel> affectedAppointments = [];
        if (oldService != null && duracao > oldService.duracao) {
          // Check for affected appointments
          affectedAppointments = await _getAffectedAppointments(docId);
          if (affectedAppointments.isNotEmpty) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                title: const Text('Atenção: Duração aumentada', style: TextStyle(color: Colors.white)),
                content: Text(
                  'A duração do serviço foi aumentada. ${affectedAppointments.length} agendamento(s) futuro(s) será(ão) afetado(s). Você precisa reagendar estes agendamentos manualmente.\n\nDeseja continuar com a atualização?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            );
            if (confirm != true) {
              return;
            }
          }
        }
        await firestore.collection('servicos').doc(docId).update(serviceData);

        // Send notification emails to affected clients
        if (affectedAppointments.isNotEmpty) {
          await _sendServiceUpdateEmails(affectedAppointments, nome, duracao);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço atualizado com sucesso!')),
        );
      } else {
        // Create new
        serviceData['id'] = firestore.collection('servicos').doc().id;
        serviceData['criadoEm'] = DateTime.now().toIso8601String();
        await firestore.collection('servicos').add(serviceData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço criado com sucesso!')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar serviço: $e')),
      );
    }
  }

  Future<void> _toggleServiceStatus(String docId, bool ativo) async {
    try {
      await firestore.collection('servicos').doc(docId).update({
        'ativo': ativo,
        'atualizadoEm': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e') ),
      );
    }
  }

  Future<void> _deleteService(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja excluir este serviço? Essa ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firestore.collection('servicos').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir serviço: $e')),
        );
      }
    }
  }

  Future<List<AppointmentModel>> _getAffectedAppointments(String serviceId) async {
    try {
      final serviceDoc = await firestore.collection('servicos').doc(serviceId).get();
      if (!serviceDoc.exists) return [];

      final service = ServiceModel.fromMap(serviceDoc.data()!);
      final now = DateTime.now();

      final querySnapshot = await firestore
          .collection('agendamentos')
          .where('serviceName', isEqualTo: service.nome)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('dateTime', isGreaterThan: now.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendServiceUpdateEmails(List<AppointmentModel> appointments, String newServiceName, int newDuration) async {
    final emailService = EmailService();

    for (final appointment in appointments) {
      try {
        // Get client email from users collection
        final userDoc = await firestore.collection('users').doc(appointment.clientId).get();
        if (!userDoc.exists) {
          print('Usuário não encontrado para clientId: ${appointment.clientId}');
          continue;
        }
        final userData = userDoc.data()!;
        final clientEmail = userData['email'] as String?;

        if (clientEmail == null || clientEmail.isEmpty) {
          print('Email não encontrado para usuário: ${appointment.clientName}');
          continue;
        }

        // Format date and time for email
        final date = appointment.dateTime.toLocal();
        final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        final formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        await emailService.sendAppointmentUpdateEmail(
          service: newServiceName,
          professional: appointment.barberName,
          date: formattedDate,
          time: formattedTime,
          barbearia: 'Falcao Barbearia',
          name: appointment.clientName,
          phone: appointment.clientPhone,
          email: clientEmail,
          updateType: 'service',
        );
      } catch (e) {
        print('Erro ao enviar email para ${appointment.clientName}: $e');
      }
    }
  }
}
