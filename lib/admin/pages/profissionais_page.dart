import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:typed_data';
import '../controller/admin_controller.dart';
import '../model/profissional_model.dart';
import '../model/barbearia_model.dart';
import '../model/service_model.dart';
import '../../user/controller/auth_controller.dart';

class AdminProfissionaisPage extends StatefulWidget {
  const AdminProfissionaisPage({super.key});

  @override
  State<AdminProfissionaisPage> createState() => _AdminProfissionaisPageState();
}

class _AdminProfissionaisPageState extends State<AdminProfissionaisPage> {
  final AdminController _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('AdminProfissionaisPage: initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('AdminProfissionaisPage: didChangeDependencies called');
  }

  @override
  Widget build(BuildContext context) {
    print('AdminProfissionaisPage: build called');
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Profissionais', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showProfissionalDialog(context),
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
                  hintText: 'Buscar profissionais...',
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
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A2A2A),
              child: Row(
                children: [
                  if (!isMobile) Expanded(flex: 1, child: Text('Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Nome', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  if (!isMobile) Expanded(flex: 2, child: Text('Barbearia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  if (!isMobile) Expanded(flex: 1, child: Text('Disponível', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  if (!isMobile) Expanded(flex: 1, child: Text('Dias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Ações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Table content
            Expanded(
              child: StreamBuilder<List<ProfissionalModel>>(
                stream: _adminController.getAllProfissionais(),
                builder: (context, snapshot) {
                  print('StreamBuilder: connectionState = ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('StreamBuilder error: ${snapshot.error}');
                    return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  final profissionais = snapshot.data ?? [];
                  print('StreamBuilder: received ${profissionais.length} profissionais');
                  final filteredProfissionais = profissionais.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.email.toLowerCase().contains(_searchQuery)
                  ).toList();

                  if (filteredProfissionais.isEmpty) {
                    return const Center(child: Text('Nenhum profissional encontrado', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    itemCount: filteredProfissionais.length,
                    itemBuilder: (context, index) {
                      final profissional = filteredProfissionais[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                        ),
                        child: Row(
                          children: [
                            if (!isMobile) Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white30, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: profissional.fotoUrl != null && profissional.fotoUrl!.isNotEmpty
                                      ? Image.network(
                                          profissional.fotoUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: const Color(0xFF2A2A2A),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xFF2A2A2A),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white70,
                                                size: 28,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: const Color(0xFF2A2A2A),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white70,
                                            size: 28,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profissional.name, style: const TextStyle(color: Colors.white)),
                                  Text(profissional.email, style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (!isMobile) Expanded(
                              flex: 2,
                              child: FutureBuilder<BarbeariaModel?>(
                                future: _getBarbeariaById(profissional.barbeariaId),
                                builder: (context, snapshot) {
                                  final barbeariaName = snapshot.data?.name ?? 'N/A';
                                  return Text(barbeariaName, style: const TextStyle(color: Colors.white));
                                },
                              ),
                            ),
                            if (!isMobile) Expanded(
                              flex: 1,
                              child: Text(
                                profissional.disponivel ? 'Sim' : 'Não',
                                style: TextStyle(color: profissional.disponivel ? Colors.green : Colors.red),
                              ),
                            ),
                            if (!isMobile) Expanded(
                              flex: 1,
                              child: Text(
                                profissional.diasAtendimento.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: isMobile
                                  ? PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white),
                                      color: const Color(0xFF2A2A2A),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'services':
                                            _showServicesDialog(context, profissional);
                                            break;
                                          case 'edit':
                                            _showProfissionalDialog(context, profissional: profissional);
                                            break;
                                          case 'delete':
                                            _confirmDeleteProfissional(context, profissional);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'services',
                                          child: Row(
                                            children: [
                                              Icon(Icons.room_service, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Gerenciar Serviços', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Editar', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Deletar', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.room_service, color: Colors.green),
                                          onPressed: () => _showServicesDialog(context, profissional),
                                          tooltip: 'Gerenciar Serviços',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showProfissionalDialog(context, profissional: profissional),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDeleteProfissional(context, profissional),
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }

  Future<BarbeariaModel?> _getBarbeariaById(String barbeariaId) async {
    return await _adminController.getBarbeariaById(barbeariaId);
  }

  void _showProfissionalDialog(BuildContext context, {ProfissionalModel? profissional}) {
    showDialog(
      context: context,
      builder: (context) => ProfissionalDialog(
        profissional: profissional,
        adminController: _adminController,
        onSave: () {
          Navigator.of(context).pop();
          if (mounted) {
            setState(() {});
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(profissional == null ? 'Profissional adicionado com sucesso!' : 'Profissional atualizado com sucesso!')),
          );
        },
      ),
    );
  }

  void _confirmDeleteProfissional(BuildContext context, ProfissionalModel profissional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir ${profissional.name}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminController.deleteProfissional(profissional.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profissional excluído com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir profissional: $e')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showServicesDialog(BuildContext context, ProfissionalModel profissional) {
    showDialog(
      context: context,
      builder: (context) => ProfissionalServicesDialog(
        profissional: profissional,
        adminController: _adminController,
      ),
    );
  }
}

class ProfissionalDialog extends StatefulWidget {
  final ProfissionalModel? profissional;
  final AdminController adminController;
  final VoidCallback onSave;

  const ProfissionalDialog({
    super.key,
    this.profissional,
    required this.adminController,
    required this.onSave,
  });

  @override
  State<ProfissionalDialog> createState() => _ProfissionalDialogState();
}

class _ProfissionalDialogState extends State<ProfissionalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _especialidadeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _manhaInicioController = TextEditingController();
  final _manhaFimController = TextEditingController();
  final _tardeInicioController = TextEditingController();
  final _tardeFimController = TextEditingController();

  // Novos campos para horários por dia
  Map<String, Map<String, dynamic>?> _horariosPorDia = {};
  final List<String> _diasSemana = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];
  final Map<String, TextEditingController> _exceptionDateControllers = {};
  final Map<String, TextEditingController> _exceptionManhaInicioControllers = {};
  final Map<String, TextEditingController> _exceptionManhaFimControllers = {};
  final Map<String, TextEditingController> _exceptionTardeInicioControllers = {};
  final Map<String, TextEditingController> _exceptionTardeFimControllers = {};

  String? _selectedBarbeariaId;
  List<String> _selectedDias = [];
  int _intervaloMinutos = 30;
  bool _disponivel = true;
  String? _fotoUrl;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.profissional != null) {
      _nameController.text = widget.profissional!.name;
      _emailController.text = widget.profissional!.email;
      _phoneController.text = widget.profissional!.phone;
      _selectedBarbeariaId = widget.profissional!.barbeariaId;
      _especialidadeController.text = widget.profissional!.especialidade ?? '';
      _selectedDias = List.from(widget.profissional!.diasAtendimento);
      _intervaloMinutos = widget.profissional!.intervaloMinutos > 30 ? 30 : widget.profissional!.intervaloMinutos;
      _fotoUrl = widget.profissional!.fotoUrl;
      _descricaoController.text = widget.profissional!.descricao ?? '';
      _disponivel = widget.profissional!.disponivel;
      _horariosPorDia = Map.from(widget.profissional!.horariosPorDia ?? {});

      if (widget.profissional!.turnos.containsKey('manha')) {
        _manhaInicioController.text = widget.profissional!.turnos['manha']!['inicio'] ?? '';
        _manhaFimController.text = widget.profissional!.turnos['manha']!['fim'] ?? '';
      }
      if (widget.profissional!.turnos.containsKey('tarde')) {
        _tardeInicioController.text = widget.profissional!.turnos['tarde']!['inicio'] ?? '';
        _tardeFimController.text = widget.profissional!.turnos['tarde']!['fim'] ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.profissional == null ? 'Adicionar Profissional' : 'Editar Profissional',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Seletor de imagem no cabeçalho
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Foto do Profissional',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.profissional?.fotoUrl != null && widget.profissional!.fotoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      widget.profissional!.fotoUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.person, size: 60, color: Colors.white70);
                                      },
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.white70),
                                      SizedBox(height: 8),
                                      Text(
                                        'Toque para adicionar foto',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library, color: Colors.white70),
                          label: const Text('Galeria', style: TextStyle(color: Colors.white70)),
                        ),
                        if (_selectedImageBytes != null) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              });
                            },
                            icon: const Icon(Icons.clear, color: Colors.red),
                            label: const Text('Remover', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        if (widget.profissional?.fotoUrl != null && widget.profissional!.fotoUrl!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDeletePhoto(),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Deletar Foto', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações gerais
                      const Text('Informações Gerais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          final parts = value.trim().split(RegExp(r'\s+'));
                          if (parts.length < 2) {
                            return 'Nome deve ter pelo menos dois nomes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),

                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          final phoneRegex = RegExp(r'^\d{9}$');
                          if (!phoneRegex.hasMatch(value)) {
                            return 'Telefone inválido. Deve conter 9 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (widget.profissional == null) // Only show password for new professionals
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            if (value.length < 6) {
                              return 'Senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      if (widget.profissional == null) const SizedBox(height: 8),
                      StreamBuilder<List<BarbeariaModel>>(
                        stream: widget.adminController.getAllBarbearias(),
                        builder: (context, snapshot) {
                          final barbearias = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            value: _selectedBarbeariaId,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF2A2A2A),
                            decoration: const InputDecoration(
                              labelText: 'Barbearia',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                            items: barbearias.map((barbearia) => DropdownMenuItem(
                              value: barbearia.id,
                              child: Text(barbearia.name, style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedBarbeariaId = value),
                            validator: (value) => value == null ? 'Campo obrigatório' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Horário de trabalho
                      const Text('Horário de Trabalho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Dias de atendimento:', style: TextStyle(color: Colors.white)),
                      Wrap(
                        children: _diasSemana.map((dia) => Container(
                          margin: const EdgeInsets.all(4),
                          child: FilterChip(
                            label: Text(dia, style: const TextStyle(color: Colors.white)),
                            selected: _selectedDias.contains(dia),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDias.add(dia);
                                } else {
                                  _selectedDias.remove(dia);
                                }
                              });
                            },
                            backgroundColor: const Color(0xFF1A1A1A),
                            selectedColor: Colors.blue,
                            checkmarkColor: Colors.white,
                          ),
                        )).toList(),
                      ),
                      if (_selectedDias.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Selecione pelo menos um dia de atendimento',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _manhaInicioController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Manhã - Início',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  _manhaInicioController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _manhaFimController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Manhã - Fim',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  _manhaFimController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tardeInicioController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Tarde - Início',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  _tardeInicioController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _tardeFimController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Tarde - Fim',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  _tardeFimController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _intervaloMinutos,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2A2A2A),
                        decoration: const InputDecoration(
                          labelText: 'Intervalo entre atendimentos (minutos)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        items: List.generate(31, (i) => i).map((interval) => DropdownMenuItem(
                          value: interval,
                          child: Text('$interval minutos', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (value) => setState(() => _intervaloMinutos = value ?? 30),
                      ),
                      const SizedBox(height: 16),

                      // Horários por dia específico
                      const Text('Horários por Dia Específico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Configure horários especiais para datas específicas (feriados, eventos, etc.)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addSpecificDaySchedule,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Horário Especial'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_horariosPorDia.isNotEmpty) ...[
                        const Text('Horários Especiais Configurados:', style: TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._horariosPorDia.entries.map((entry) {
                          final date = entry.key;
                          final schedule = entry.value;
                          return Card(
                            color: const Color(0xFF1A1A1A),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Data: $date',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeSpecificDaySchedule(date),
                                        tooltip: 'Remover horário especial',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (schedule != null && schedule.containsKey('manha')) ...[
                                    Text(
                                      'Manhã: ${schedule['manha']!['inicio']} - ${schedule['manha']!['fim']}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                  if (schedule != null && schedule.containsKey('tarde')) ...[
                                    Text(
                                      'Tarde: ${schedule['tarde']!['inicio']} - ${schedule['tarde']!['fim']}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),

                      // Outros detalhes
                      const Text('Outros Detalhes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _especialidadeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Especialidade / Função',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Descrição curta',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Disponível', style: TextStyle(color: Colors.white)),
                        value: _disponivel,
                        onChanged: (value) => setState(() => _disponivel = value),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveProfissional,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.profissional == null ? 'Adicionar' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfissional() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia de atendimento')),
      );
      return;
    }

    final turnos = <String, Map<String, String>>{};
    if (_manhaInicioController.text.isNotEmpty && _manhaFimController.text.isNotEmpty) {
      turnos['manha'] = {
        'inicio': _manhaInicioController.text,
        'fim': _manhaFimController.text,
      };
    }
    if (_tardeInicioController.text.isNotEmpty && _tardeFimController.text.isNotEmpty) {
      turnos['tarde'] = {
        'inicio': _tardeInicioController.text,
        'fim': _tardeFimController.text,
      };
    }

    if (turnos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina pelo menos um turno de trabalho')),
      );
      return;
    }

    try {
      String? finalImageUrl = _fotoUrl;

      // If an image is selected, upload it to Firebase Storage
      if (_selectedImage != null) {
        final random = Random();
        final fileName = 'profissionais/${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);

        final bytes = await _selectedImage!.readAsBytes();
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await storageRef.getDownloadURL();
      }

      final profissional = ProfissionalModel(
        id: widget.profissional?.id ?? '',
        userId: widget.profissional?.userId ?? '',
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        barbeariaId: _selectedBarbeariaId!,
        especialidade: _especialidadeController.text.isEmpty ? null : _especialidadeController.text,
        diasAtendimento: _selectedDias,
        turnos: turnos,
        horariosPorDia: _horariosPorDia,
        intervaloMinutos: _intervaloMinutos,
        fotoUrl: finalImageUrl,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        disponivel: _disponivel,
        createdAt: widget.profissional?.createdAt ?? DateTime.now(),
      );

      if (widget.profissional == null) {
        // Create new profissional
        await widget.adminController.addProfissional(profissional, _passwordController.text);
        // Relogin as admin after creating professional
        await AuthController().reloginAsAdmin();
      } else {
        // Update existing profissional
        await widget.adminController.updateProfissional(profissional);
      }

      if (widget.profissional == null) {
        // Clear the form for new professional to allow creating another
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _especialidadeController.clear();
        _descricaoController.clear();
        _manhaInicioController.clear();
        _manhaFimController.clear();
        _tardeInicioController.clear();
        _tardeFimController.clear();
        setState(() {
          _selectedBarbeariaId = null;
          _selectedDias = [];
          _intervaloMinutos = 30;
          _disponivel = true;
          _fotoUrl = null;
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profissional adicionado com sucesso!')),
        );
      } else {
        widget.onSave();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar profissional: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _confirmDeletePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja excluir a foto do profissional?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _fotoUrl = null;
                _selectedImage = null;
                _selectedImageBytes = null;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto excluída. Salve as alterações para confirmar.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addSpecificDaySchedule() {
    DateTime? selectedDate;
    final TextEditingController dateController = TextEditingController();
    final TextEditingController manhaInicioController = TextEditingController();
    final TextEditingController manhaFimController = TextEditingController();
    final TextEditingController tardeInicioController = TextEditingController();
    final TextEditingController tardeFimController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Adicionar Horário Especial', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Data',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  filled: true,
                  fillColor: Color(0xFF2A2A2A),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    // Format date as string
                    final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    dateController.text = formattedDate;
                  }
                },
                readOnly: true,
              ),
              const SizedBox(height: 16),
              const Text('Horários de Manhã (opcional)', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: manhaInicioController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Início',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          manhaInicioController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: manhaFimController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Fim',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          manhaFimController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Horários de Tarde (opcional)', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: tardeInicioController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Início',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          tardeInicioController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: tardeFimController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Fim',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          tardeFimController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
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
            onPressed: () {
              if (selectedDate != null) {
                final dateKey = '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';
                final schedule = <String, Map<String, String>>{};
                if (manhaInicioController.text.isNotEmpty && manhaFimController.text.isNotEmpty) {
                  schedule['manha'] = {
                    'inicio': manhaInicioController.text,
                    'fim': manhaFimController.text,
                  };
                }
                if (tardeInicioController.text.isNotEmpty && tardeFimController.text.isNotEmpty) {
                  schedule['tarde'] = {
                    'inicio': tardeInicioController.text,
                    'fim': tardeFimController.text,
                  };
                }
                setState(() {
                  _horariosPorDia[dateKey] = schedule.isNotEmpty ? schedule : null;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeSpecificDaySchedule(String date) {
    setState(() {
      _horariosPorDia.remove(date);
    });
  }
}

// Dialog para gerenciar serviços do profissional
class ProfissionalServicesDialog extends StatefulWidget {
  final ProfissionalModel profissional;
  final AdminController adminController;

  const ProfissionalServicesDialog({
    super.key,
    required this.profissional,
    required this.adminController,
  });

  @override
  State<ProfissionalServicesDialog> createState() => _ProfissionalServicesDialogState();
}

class _ProfissionalServicesDialogState extends State<ProfissionalServicesDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Serviços de ${widget.profissional.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showServiceFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Serviço'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: widget.adminController.getServicesByProfissional(widget.profissional.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  
                  final services = snapshot.data ?? [];
                  
                  if (services.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum serviço cadastrado para este profissional',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getIconData(service.iconName),
                            color: service.ativo ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          title: Text(
                            service.nome,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.descricao,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              MediaQuery.of(context).size.width < 768
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '€${service.preco.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              '${service.duracao} min',
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: service.ativo ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            service.ativo ? 'Ativo' : 'Inativo',
                                            style: TextStyle(
                                              color: service.ativo ? Colors.green : Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Text(
                                          '€${service.preco.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '${service.duracao} min',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: service.ativo ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            service.ativo ? 'Ativo' : 'Inativo',
                                            style: TextStyle(
                                              color: service.ativo ? Colors.green : Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                          trailing: MediaQuery.of(context).size.width < 768
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  color: const Color(0xFF2A2A2A),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'toggle':
                                        // Handle toggle status
                                        _toggleServiceStatus(service);
                                        break;
                                      case 'edit':
                                        _showServiceFormDialog(context, service: service);
                                        break;
                                      case 'delete':
                                        _confirmDeleteService(context, service);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Switch(
                                            value: service.ativo,
                                            onChanged: (value) {
                                              Navigator.of(context).pop(); // Close menu
                                              _toggleServiceStatus(service);
                                            },
                                            activeColor: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            service.ativo ? 'Desativar' : 'Ativar',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Editar', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Deletar', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: service.ativo,
                                      onChanged: (value) async {
                                        try {
                                          await widget.adminController.toggleServiceStatus(service.id, value);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Serviço ${value ? 'ativado' : 'desativado'} com sucesso!')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erro ao atualizar status: $e')),
                                          );
                                        }
                                      },
                                      activeColor: Colors.green,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showServiceFormDialog(context, service: service),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDeleteService(context, service),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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

  void _showServiceFormDialog(BuildContext context, {service}) {
    showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(
        profissional: widget.profissional,
        adminController: widget.adminController,
        service: service,
      ),
    );
  }

  void _toggleServiceStatus(dynamic service) async {
    try {
      await widget.adminController.toggleServiceStatus(service.id, !service.ativo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço ${!service.ativo ? 'ativado' : 'desativado'} com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  void _confirmDeleteService(BuildContext context, service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tem certeza que deseja excluir o serviço "${service.nome}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await widget.adminController.deleteServiceFromProfissional(service.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serviço excluído com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir serviço: $e')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Dialog para adicionar/editar serviço
class ServiceFormDialog extends StatefulWidget {
  final ProfissionalModel profissional;
  final AdminController adminController;
  final dynamic service;

  const ServiceFormDialog({
    super.key,
    required this.profissional,
    required this.adminController,
    this.service,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _duracaoController = TextEditingController();
  String _selectedIcon = 'content_cut';
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nomeController.text = widget.service.nome;
      _descricaoController.text = widget.service.descricao;
      _precoController.text = widget.service.preco.toString();
      _duracaoController.text = widget.service.duracao.toString();
      _selectedIcon = widget.service.iconName;
      _ativo = widget.service.ativo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text(
        widget.service == null ? 'Adicionar Serviço' : 'Editar Serviço',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF2A2A2A),
                decoration: const InputDecoration(
                  labelText: 'Ícone',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                items: const [
                  DropdownMenuItem(value: 'content_cut', child: Text('Corte', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'face', child: Text('Rosto', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'spa', child: Text('Spa', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'brush', child: Text('Pincel', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'local_bar', child: Text('Barba', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) => setState(() => _selectedIcon = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço (€)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _duracaoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duração (min)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (int.tryParse(value) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Ativo', style: TextStyle(color: Colors.white)),
                value: _ativo,
                onChanged: (value) => setState(() => _ativo = value),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _saveService,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.service == null ? 'Adicionar' : 'Salvar'),
        ),
      ],
    );
  }

  void _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final service = widget.service?.copyWith(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        preco: double.parse(_precoController.text),
        duracao: int.parse(_duracaoController.text),
        iconName: _selectedIcon,
        ativo: _ativo,
        atualizadoEm: DateTime.now(),
      ) ?? ServiceModel(
        id: '',
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        preco: double.parse(_precoController.text),
        duracao: int.parse(_duracaoController.text),
        iconName: _selectedIcon,
        ativo: _ativo,
        profissionalId: widget.profissional.id,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      if (widget.service == null) {
        await widget.adminController.addServiceToProfissional(service);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço adicionado com sucesso!')),
        );
      } else {
        await widget.adminController.updateServiceProfissional(service);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço atualizado com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar serviço: $e')),
      );
    }
  }
}
