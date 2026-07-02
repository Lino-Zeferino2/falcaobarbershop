// ignore_for_file: use_build_context_synchronously

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

  static const _red = Color(0xFFB22222);
  static const _card = Color(0xFF1A1A1A);
  static const _card2 = Color(0xFF222222);

  bool _showCampanhas = false;
  Future<List<RetencaoClientesItem>>? _futureClientes;
  String _selectedRange = '2+ meses';
  final List<String> _ranges = ['1+ mês', '2+ meses', '3+ meses'];

  int get _minMonths {
    switch (_selectedRange) {
      case '1+ mês': return 1;
      case '3+ meses': return 3;
      default: return 2;
    }
  }

  Future<List<RetencaoClientesItem>> _loadFiltered() =>
      _controller.getRetencaoClientes(minMonthsSinceLastAppointment: _minMonths);

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _futureClientes = _loadFiltered());
  }

  @override
  void initState() {
    super.initState();
    _futureClientes = _loadFiltered();
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _shortDesc(String? s, {int max = 120}) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return 'Sem descrição.';
    return v.length <= max ? v : '${v.substring(0, max)}...';
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _createCampaignDialog() async {
    String titulo = '', descricao = '';
    await showDialog(
      context: context,
      builder: (_) => _CampaignFormDialog(
        title: 'Nova Campanha',
        initialTitulo: titulo,
        initialDescricao: descricao,
        onSave: (t, d) async {
          await _campanhasController.criarCampanha(titulo: t, descricao: d);
        },
      ),
    );
  }

  Future<void> _editCampaignDialog(CampanhaModel c) async {
    await showDialog(
      context: context,
      builder: (_) => _CampaignFormDialog(
        title: 'Editar Campanha',
        initialTitulo: c.titulo,
        initialDescricao: c.descricao,
        onSave: (t, d) async {
          await _campanhasController.updateCampanha(id: c.id, titulo: t, descricao: d);
        },
      ),
    );
  }

  Future<void> _deleteCampaignDialog(CampanhaModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Apagar campanha?',
        content: '"${c.titulo}" será removida permanentemente.',
        actionLabel: 'Apagar',
        actionColor: Colors.red,
      ),
    );
    if (ok != true) return;
    try {
      await _campanhasController.deleteCampanha(c.id);
      if (mounted) _snack('Campanha apagada');
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    }
  }

  Future<void> _sendCampaignDialog(RetencaoClientesItem cliente) async {
    await showDialog(
      context: context,
      builder: (_) => _SendCampaignDialog(
        cliente: cliente,
        campanhasController: _campanhasController,
        shortDesc: _shortDesc,
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _red,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(isMobile),
          const SizedBox(height: 20),
          _tabs(),
          const SizedBox(height: 20),
          if (!_showCampanhas) ...[_filters(), const SizedBox(height: 16)],
          Expanded(child: _showCampanhas ? _campaignsList() : _clientsList(isMobile)),
        ],
      ),
    );
  }

  Widget _header(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Retenção de Clientes',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Recupera clientes inativos com campanhas personalizadas.',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _createCampaignDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(isMobile ? 'Campanha' : 'Nova Campanha'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        _tab('Clientes Inativos', Icons.person_off_outlined, !_showCampanhas, () => setState(() => _showCampanhas = false)),
        const SizedBox(width: 8),
        _tab('Campanhas', Icons.campaign_outlined, _showCampanhas, () => setState(() => _showCampanhas = true)),
      ],
    );
  }

  Widget _tab(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _red : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _red : Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ranges.map((r) {
          final selected = r == _selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRange = r;
                _futureClientes = _loadFiltered();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _red.withOpacity(0.15) : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _red.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.access_time, color: _red, size: 13),
                      const SizedBox(width: 4),
                    ],
                    Text(r,
                        style: TextStyle(
                          color: selected ? _red : Colors.white54,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _campaignsList() {
    return StreamBuilder<List<CampanhaModel>>(
      stream: _campanhasController.streamAllCampanhas(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _red));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _emptyState(Icons.campaign_outlined, 'Sem campanhas criadas.',
              'Cria uma campanha para enviar aos clientes inativos.');
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _campaignCard(items[i]),
        );
      },
    );
  }

  Widget _campaignCard(CampanhaModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign, color: _red, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
                onPressed: () => _editCampaignDialog(c),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _deleteCampaignDialog(c),
                tooltip: 'Apagar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_shortDesc(c.descricao),
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _clientsList(bool isMobile) {
    return RefreshIndicator(
      color: _red,
      backgroundColor: _card,
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<RetencaoClientesItem>>(
        future: _futureClientes,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _red));
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}', style: const TextStyle(color: Colors.white54)));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _emptyState(Icons.person_off_outlined, 'Sem clientes inativos.',
                'Todos os clientes estão activos com este filtro.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<int>(
                future: _controller.getTotalClientesCount(),
                builder: (_, totalSnap) {
                  final total = totalSnap.data ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: _red, size: 16),
                        const SizedBox(width: 8),
                        Text('${items.length} clientes inativos de $total total',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: isMobile
                    ? ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _clientCardMobile(items[i]),
                      )
                    : _clientTable(items),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _clientCardMobile(RetencaoClientesItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _red.withOpacity(0.15),
                child: Text(
                  item.nome.isNotEmpty ? item.nome[0].toUpperCase() : '?',
                  style: const TextStyle(color: _red, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.nome,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoChip(Icons.phone_outlined, item.telemovel),
          const SizedBox(height: 6),
          _infoChip(Icons.mail_outline, item.email),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _infoChip(Icons.calendar_today_outlined, _fmtDate(item.ultimoAgendamento))),
              const SizedBox(width: 8),
              Expanded(child: _infoChip(Icons.euro_outlined, '€${item.totalGasto.toStringAsFixed(2)}')),
            ],
          ),
          if (item.qtdEnviosCampanha > 0) ...[
            const SizedBox(height: 6),
            _infoChip(Icons.send_outlined,
                '${item.qtdEnviosCampanha} envio${item.qtdEnviosCampanha > 1 ? 's' : ''} · ${_fmtDate(item.ultimoEnvioAt)}'),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendCampaignDialog(item),
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Enviar Campanha', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _clientTable(List<RetencaoClientesItem> items) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(_card2),
            dividerThickness: 0.5,
            columnSpacing: 24,
            headingTextStyle: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
            dataTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            columns: const [
              DataColumn(label: Text('CLIENTE')),
              DataColumn(label: Text('TELEMÓVEL')),
              DataColumn(label: Text('ÚLTIMO')),
              DataColumn(label: Text('AGEND.')),
              DataColumn(label: Text('GASTO')),
              DataColumn(label: Text('ENVIOS')),
              DataColumn(label: Text('ACÇÃO')),
            ],
            rows: items.map((item) {
              return DataRow(cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _red.withOpacity(0.15),
                      child: Text(
                        item.nome.isNotEmpty ? item.nome[0].toUpperCase() : '?',
                        style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(item.nome,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                )),
                DataCell(Text(item.telemovel)),
                DataCell(Text(_fmtDate(item.ultimoAgendamento))),
                DataCell(Text('${item.totalAgendamentos}')),
                DataCell(Text('€${item.totalGasto.toStringAsFixed(2)}',
                    style: const TextStyle(color: _red, fontWeight: FontWeight.w600))),
                DataCell(Text(
                  item.ultimoEnvioAt == null
                      ? '${item.qtdEnviosCampanha}'
                      : '${item.qtdEnviosCampanha} · ${_fmtDate(item.ultimoEnvioAt)}',
                )),
                DataCell(
                  GestureDetector(
                    onTap: () => _sendCampaignDialog(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text('Enviar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 40),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Dialogs extraídos ─────────────────────────────────────────────────────────

class _CampaignFormDialog extends StatefulWidget {
  final String title;
  final String initialTitulo;
  final String initialDescricao;
  final Future<void> Function(String titulo, String descricao) onSave;

  const _CampaignFormDialog({
    required this.title,
    required this.initialTitulo,
    required this.initialDescricao,
    required this.onSave,
  });

  @override
  State<_CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<_CampaignFormDialog> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  static const _red = Color(0xFFB22222);
  static const _card = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.initialTitulo);
    _descCtrl = TextEditingController(text: widget.initialDescricao);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field('Título', _tituloCtrl, maxLines: 1),
          const SizedBox(height: 12),
          _field('Descrição', _descCtrl, maxLines: 5),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _red),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final t = _tituloCtrl.text.trim();
    final d = _descCtrl.text.trim();
    if (t.isEmpty || d.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(t, d);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado com sucesso'), backgroundColor: _red),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String actionLabel;
  final Color actionColor;

  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17)),
      content: Text(content, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _SendCampaignDialog extends StatefulWidget {
  final RetencaoClientesItem cliente;
  final CampanhasController campanhasController;
  final String Function(String?) shortDesc;

  const _SendCampaignDialog({
    required this.cliente,
    required this.campanhasController,
    required this.shortDesc,
  });

  @override
  State<_SendCampaignDialog> createState() => _SendCampaignDialogState();
}

class _SendCampaignDialogState extends State<_SendCampaignDialog> {
  String? _selectedId;
  bool _sending = false;

  static const _red = Color(0xFFB22222);
  static const _card = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Enviar Campanha', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: StreamBuilder<List<CampanhaModel>>(
          stream: widget.campanhasController.streamAllCampanhas(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: _red)));
            }
            final campaigns = snap.data ?? [];
            if (campaigns.isEmpty) {
              return const Text('Sem campanhas disponíveis. Cria uma primeiro.',
                  style: TextStyle(color: Colors.white54));
            }
            _selectedId ??= campaigns.first.id;
            final selected = campaigns.firstWhere((c) => c.id == _selectedId, orElse: () => campaigns.first);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _red.withOpacity(0.2),
                        child: Text(
                          widget.cliente.nome.isNotEmpty ? widget.cliente.nome[0].toUpperCase() : '?',
                          style: const TextStyle(color: _red, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.cliente.nome,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(widget.cliente.telemovel,
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  iconEnabledColor: Colors.white38,
                  decoration: InputDecoration(
                    labelText: 'Campanha',
                    labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: campaigns.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.titulo, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedId = v),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prévia', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(widget.shortDesc(selected.descricao),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton.icon(
          onPressed: _sending || _selectedId == null ? null : _send,
          icon: _sending
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, size: 14),
          label: const Text('Enviar via WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    if (_selectedId == null) return;
    setState(() => _sending = true);
    try {
      final campaigns = await widget.campanhasController.streamAllCampanhas().first;
      final selected = campaigns.firstWhere((c) => c.id == _selectedId!);
      final phone = widget.cliente.telemovel
          .replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      final msg = 'Olá ${widget.cliente.nome}! 👋\n\n${selected.titulo}\n\n${selected.descricao}';
      final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');

      await widget.campanhasController.logEnvioCampanha(
        clienteId: widget.cliente.clienteId,
        campanhaId: selected.id,
        canal: 'whatsapp',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}