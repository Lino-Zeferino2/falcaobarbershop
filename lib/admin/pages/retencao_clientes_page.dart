import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/retencao_clientes_controller.dart';
import '../controller/campanhas_controller.dart';

class RetencaoClientesPage extends StatefulWidget {
  const RetencaoClientesPage({super.key});

  @override
  State<RetencaoClientesPage> createState() => _RetencaoClientesPageState();
}

class _RetencaoClientesPageState extends State<RetencaoClientesPage> {
  final RetencaoClientesController _controller = RetencaoClientesController();
  final CampanhasController _campanhasController = CampanhasController();

  bool _showPromocoes = false;

  Future<List<RetencaoClientesItem>>? _futureClientes;

  // Filtros por inatividade
  String _selectedInactivityRange = '2+ meses';
  final List<String> _ranges = ['1+ mês', '2+ meses', '3+ meses'];

  int _minMonthsFromSelectedRange() {
    switch (_selectedInactivityRange) {
      case '1+ mês':
        return 1;
      case '2+ meses':
        return 2;
      case '3+ meses':
        return 3;
      default:
        return 2;
    }
  }

  Future<List<RetencaoClientesItem>> _loadFiltered() {
    return _controller.getRetencaoClientes(
      minMonthsSinceLastAppointment: _minMonthsFromSelectedRange(),
    );
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() {
      _futureClientes = _loadFiltered();
    });
  }

  @override
  void initState() {
    super.initState();
    _futureClientes = _loadFiltered();
  }

  String _formatDateDDMMYYYY(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _shortDesc(String? s, {int maxChars = 120}) {
    final value = (s ?? '').trim();
    if (value.isEmpty) return 'Sem descrição.';
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars)}...';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===== Campanhas dialogs =====

  Future<void> _showCreateCampaignDialog() async {
    String titulo = '';
    String descricao = '';

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text('Criar Campanha', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => titulo = v,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => descricao = v,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titulo.trim().isEmpty || descricao.trim().isEmpty) return;

                    try {
                      await _campanhasController.criarCampanha(
                        titulo: titulo.trim(),
                        descricao: descricao.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Campanha criada com sucesso')),
                        );
                      }
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao criar campanha: $e')),
                        );
                      }
                      Navigator.of(context).pop(false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222)),
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCampaignDialog(CampanhaModel campanha) async {
    String titulo = campanha.titulo;
    String descricao = campanha.descricao;

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text('Editar Campanha', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => titulo = v,
                      controller: TextEditingController(text: titulo),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => descricao = v,
                      controller: TextEditingController(text: descricao),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titulo.trim().isEmpty || descricao.trim().isEmpty) return;

                    try {
                      await _campanhasController.updateCampanha(
                        id: campanha.id,
                        titulo: titulo.trim(),
                        descricao: descricao.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Campanha atualizada com sucesso')),
                        );
                      }
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar campanha: $e')),
                        );
                      }
                      Navigator.of(context).pop(false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222)),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteCampaignDialog(CampanhaModel campanha) async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Excluir Campanha', style: TextStyle(color: Colors.white)),
          content: Text(
            'Tem certeza que deseja excluir "${campanha.titulo}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _campanhasController.deleteCampanha(campanha.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Campanha excluída com sucesso')),
                    );
                  }
                  Navigator.of(context).pop(true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir campanha: $e')),
                    );
                  }
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSendCampaignDialog({required RetencaoClientesItem cliente}) async {
    String? selectedId;

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text('Enviar Campanha', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<List<CampanhaModel>>(
                  stream: _campanhasController.streamAllCampanhas(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFFB22222)),
                        ),
                      );
                    }

                    if (snap.hasError) {
                      return Text(
                        'Erro ao carregar campanhas: ${snap.error}',
                        style: const TextStyle(color: Colors.white70),
                      );
                    }

                    final campaigns = snap.data ?? [];
                    if (campaigns.isEmpty) {
                      return const Text(
                        'Nenhuma campanha criada. Crie uma campanha antes de enviar.',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    selectedId ??= campaigns.first.id;
                    final selected = campaigns.firstWhere((c) => c.id == selectedId);
                    final resumo = _shortDesc(selected.descricao);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFFB22222)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cliente.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedId,
                          dropdownColor: const Color(0xFF2A2A2A),
                          decoration: const InputDecoration(
                            labelText: 'Campanha',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                          ),
                          items: campaigns.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                c.titulo,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => selectedId = v),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Simulação:',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(resumo, style: const TextStyle(color: Colors.white70)),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedId == null) return;

                    final campaigns = await _campanhasController.streamAllCampanhas().first;
                    final selected = campaigns.firstWhere((c) => c.id == selectedId);

                    final phoneRaw = cliente.telemovel;
                    final phone = phoneRaw
                        .replaceAll(' ', '')
                        .replaceAll('-', '')
                        .replaceAll('(', '')
                        .replaceAll(')', '')
                        .replaceAll('+', '');

                    final msg =
                        'Olá ${cliente.nome}! 👋\n\nSegue a campanha:\n• ${selected.titulo}\n\n${selected.descricao}';

                    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');

                    try {
                      await _campanhasController.logEnvioCampanha(
                        clienteId: cliente.clienteId,
                        campanhaId: selected.id,
                        canal: 'whatsapp',
                      );

                      final canLaunch = await canLaunchUrl(uri);
                      if (canLaunch) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
                        );
                      }
                    }

                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222)),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Retenção Cliente', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Clientes com inatividade (gestão de campanhas)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateCampaignDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Campanha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _ranges.map((r) {
                final selected = r == _selectedInactivityRange;
                return ChoiceChip(
                  label: Text(
                    r,
                    style: TextStyle(color: selected ? Colors.white : Colors.white70),
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedInactivityRange = r;
                      _futureClientes = _loadFiltered();
                    });
                  },
                  selectedColor: const Color(0xFFB22222),
                  backgroundColor: const Color(0xFF2A2A2A),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showPromocoes = !_showPromocoes),
                  icon: const Icon(Icons.list_alt, color: Colors.white),
                  label: Text(
                    _showPromocoes ? 'Voltar para Clientes' : 'Ver Lista de Campanhas',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showPromocoes)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: StreamBuilder<List<CampanhaModel>>(
                    stream: _campanhasController.streamAllCampanhas(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFB22222)),
                        );
                      }
                      if (snap.hasError) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar promoções',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final promos = snap.data ?? [];
                      if (promos.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma promoção criada ainda.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: isMobile ? 16 : 24),
                        itemCount: promos.length,
                        itemBuilder: (context, index) {
                          final p = promos[index];
                          return Card(
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.campaign, color: Color(0xFFB22222)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p.titulo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.descricao,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _showEditCampaignDialog(p),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Editar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () => _showDeleteCampaignDialog(p),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Excluir'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
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
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: FutureBuilder<List<RetencaoClientesItem>>(
                    future: _futureClientes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFB22222)),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      final filteredTotal = items.length;

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum cliente encontrado para este filtro.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        );
                      }

                      return FutureBuilder<int>(
                        future: _controller.getTotalClientesCount(),
                        builder: (context, totalSnap) {
                          final totalGeneral = totalSnap.data ?? 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Clientes inativos: $filteredTotal de $totalGeneral',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: isMobile
                                    ? ListView.builder(
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          final item = items[index];
                                          return Card(
                                            color: const Color(0xFF2A2A2A),
                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: const Color(0xFFB22222).withOpacity(0.14),
                                                          border: Border.all(
                                                            color: const Color(0xFFB22222).withOpacity(0.55),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 16,
                                                          color: Color(0xFFB22222),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          item.nome,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _infoRow(Icons.phone, 'Telemóvel', item.telemovel),
                                                  const SizedBox(height: 6),
                                                  _infoRow(Icons.email, 'Email', item.email),
                                                  const SizedBox(height: 6),
                                                  _infoRow(
                                                    Icons.calendar_today,
                                                    'Último agendamento',
                                                    _formatDateDDMMYYYY(item.ultimoAgendamento),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  _infoRow(
                                                    Icons.event,
                                                    'Agendamentos',
                                                    item.totalAgendamentos.toString(),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  _infoRow(
                                                    Icons.euro,
                                                    'Gasto total',
                                                    '€${item.totalGasto.toStringAsFixed(2)}',
                                                  ),
                                                  const SizedBox(height: 6),
                                                  _infoRow(
                                                    Icons.send,
                                                    'Envios',
                                                    item.ultimoEnvioAt == null
                                                        ? item.qtdEnviosCampanha.toString()
                                                        : '${item.qtdEnviosCampanha} • ${_formatDateDDMMYYYY(item.ultimoEnvioAt)}',
                                                  ),
                                                  const SizedBox(height: 14),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _showSendCampaignDialog(cliente: item),
                                                      icon: const Icon(Icons.send),
                                                      label: const Text('Enviar Campanha'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFB22222),
                                                        foregroundColor: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : SizedBox(
                                        height: 420,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              headingRowColor: MaterialStateProperty.all(const Color(0xFF2A2A2A)),
                                              columns: const [
                                                DataColumn(label: Text('Cliente', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Telemóvel', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Último', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Agendamentos', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Gasto', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Envios', style: TextStyle(color: Colors.white))),
                                                DataColumn(label: Text('Ações', style: TextStyle(color: Colors.white))),
                                              ],
                                              rows: items.map((item) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        item.nome,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(item.telemovel, style: const TextStyle(color: Colors.white70)),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _formatDateDDMMYYYY(item.ultimoAgendamento),
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.totalAgendamentos.toString(),
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '€${item.totalGasto.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          color: Color(0xFFB22222),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.ultimoEnvioAt == null
                                                            ? item.qtdEnviosCampanha.toString()
                                                            : '${item.qtdEnviosCampanha} • ${_formatDateDDMMYYYY(item.ultimoEnvioAt)}',
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      ElevatedButton.icon(
                                                        onPressed: () => _showSendCampaignDialog(cliente: item),
                                                        icon: const Icon(Icons.send, size: 16),
                                                        label: const Text('Enviar'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFFB22222),
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
