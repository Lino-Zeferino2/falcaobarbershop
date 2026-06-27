import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../model/settings_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AdminController _adminController = AdminController();
  SettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for form fields
  final _barbeariaNomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();
  final _horarioFuncionamentoController = TextEditingController();
  final _descricaoCurtaController = TextEditingController();
  final _subDescricaoController = TextEditingController();
  final _whatsAppController = TextEditingController();

  // Novos campos para dias e horários
  List<String> _diasAtendimento = [];
  Map<String, Map<String, String>> _turnos = {};
  final _manhaInicioController = TextEditingController();
  final _manhaFimController = TextEditingController();
  final _tardeInicioController = TextEditingController();
  final _tardeFimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _adminController.getOrCreateDefaultSettings();
      setState(() {
        _settings = settings;
        _populateControllers(settings);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar configurações: $e')),
      );
    }
  }

  void _populateControllers(SettingsModel settings) {
    _barbeariaNomeController.text = settings.barbeariaNome;
    _emailController.text = settings.email;
    _instagramController.text = settings.instagram;
    _horarioFuncionamentoController.text = settings.horarioFuncionamento;
    _descricaoCurtaController.text = settings.descricaoCurta;
    _subDescricaoController.text = settings.subDescricao;
    _whatsAppController.text = settings.whatsApp;

    // Novos campos
    _diasAtendimento = List.from(settings.diasAtendimento);
    _turnos = Map.from(settings.turnos);

    // Preencher controllers dos turnos
    if (_turnos.containsKey('manha')) {
      _manhaInicioController.text = _turnos['manha']!['inicio'] ?? '';
      _manhaFimController.text = _turnos['manha']!['fim'] ?? '';
    }
    if (_turnos.containsKey('tarde')) {
      _tardeInicioController.text = _turnos['tarde']!['inicio'] ?? '';
      _tardeFimController.text = _turnos['tarde']!['fim'] ?? '';
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Alterações'),
        content: const Text('Tem certeza que deseja salvar as alterações nas configurações?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Atualizar turnos com os valores dos controllers
      final updatedTurnos = Map<String, Map<String, String>>.from(_turnos);
      if (_manhaInicioController.text.isNotEmpty && _manhaFimController.text.isNotEmpty) {
        updatedTurnos['manha'] = {
          'inicio': _manhaInicioController.text,
          'fim': _manhaFimController.text,
        };
      }
      if (_tardeInicioController.text.isNotEmpty && _tardeFimController.text.isNotEmpty) {
        updatedTurnos['tarde'] = {
          'inicio': _tardeInicioController.text,
          'fim': _tardeFimController.text,
        };
      }

      final updatedSettings = _settings!.copyWith(
        barbeariaNome: _barbeariaNomeController.text,
        email: _emailController.text,
        instagram: _instagramController.text,
        horarioFuncionamento: _horarioFuncionamentoController.text,
        descricaoCurta: _descricaoCurtaController.text,
        subDescricao: _subDescricaoController.text,
        whatsApp: _whatsAppController.text,
        diasAtendimento: _diasAtendimento,
        turnos: updatedTurnos,
        updatedAt: DateTime.now(),
      );

      await _adminController.updateSettings(updatedSettings);

      setState(() {
        _settings = updatedSettings;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    } catch (e) {
      print('Error saving settings: $e');
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e')),
      );
    }
  }

  void _restoreDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Padrões'),
        content: const Text('Tem certeza que deseja restaurar todas as configurações para os valores padrão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadSettings(); // Reload default settings
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Configurações', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.white),
            onPressed: _restoreDefaults,
            tooltip: 'Restaurar padrões',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 10 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('🏠 Informações da Barbearia'),
              _buildBarbeariaSection(),

              const SizedBox(height: 32),
              _buildSectionTitle('📅 Dias e Horários de Funcionamento'),
              _buildHorariosSection(isMobile),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Alterações'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBarbeariaSection() {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_barbeariaNomeController, 'Nome da Barbearia'),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email comercial'),
            const SizedBox(height: 16),
            _buildTextField(_whatsAppController, 'WhatsApp'),
            const SizedBox(height: 16),
            _buildTextField(_instagramController, 'Instagram'),
            const SizedBox(height: 16),
            _buildTextField(_horarioFuncionamentoController, 'Horário de funcionamento'),
            const SizedBox(height: 16),
            _buildTextField(_descricaoCurtaController, 'Descrição curta'),
            const SizedBox(height: 16),
            _buildTextField(_subDescricaoController, 'Sub descrição'),
          ],
        ),
      ),
    );
  }

  Widget _buildHorariosSection(bool isMobile) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dias de Atendimento',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: isMobile ? 12 : 8.0,
              runSpacing: isMobile ? 12 : 8.0,
              children: ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'].map((dia) {
                final isSelected = _diasAtendimento.contains(dia);
                return FilterChip(
                  label: Text(dia, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _diasAtendimento.add(dia);
                      } else {
                        _diasAtendimento.remove(dia);
                      }
                    });
                  },
                  backgroundColor: const Color(0xFF3A3A3A),
                  selectedColor: Colors.blue,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Turnos',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manhã',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(_manhaInicioController, 'Início'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(_manhaFimController, 'Fim'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tarde',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(_tardeInicioController, 'Início'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(_tardeFimController, 'Fim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
        hintText: 'HH:MM',
        hintStyle: const TextStyle(color: Colors.white38),
        suffixIcon: const Icon(Icons.access_time, color: Colors.white70),
      ),
      keyboardType: TextInputType.datetime,
      readOnly: true,
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: Color(0xFF2A2A2A),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF1A1A1A),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          controller.text = formattedTime;
        }
      },
    );
  }
}
