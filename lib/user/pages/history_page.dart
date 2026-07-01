// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../firestore_instance.dart';

// Mesma paleta usada nas demais telas do app.
class _Palette {
  static const background = Color(0xFF0B0B0D);
  static const surface = Color(0xFF161617);
  static const surfaceLight = Color(0xFF1F1F21);
  static const primary = Color(0xFFB22222);
  static const primaryDark = Color(0xFF8C1A1A);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA8A8AC);
  static const error = Color(0xFFFF5C5C);
  static const warning = Color(0xFFE8A33D);
  static const success = Color(0xFF3DDC84);
  static const info = Color(0xFF5BA3E8);
  static const neutral = Color(0xFF8A8A8E);
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _searchController.addListener(_filterBookings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await firestore
          .collection('agendamentos')
          .where('userId', isEqualTo: user.uid)
          .get();

      final bookings = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();

      // Ordena por data de criação (mais recente primeiro) em memória.
      bookings.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      final now = DateTime.now();

      // 1ª passagem: calcula o status de cada agendamento e recolhe, sem
      // duplicados, os IDs de profissional que ainda precisam de ser
      // resolvidos para nome (evita disparar a mesma query várias vezes).
      final Set<String> professionalIdsToResolve = {};
      for (var booking in bookings) {
        final dateTime = DateTime.parse(booking['date']);
        final timeParts = booking['time'].split(':');
        final bookingDateTime = DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        if (booking['status'] == 'canceled') {
          booking['displayStatus'] = 'Cancelado';
        } else if (bookingDateTime.isBefore(now)) {
          booking['displayStatus'] = 'Concluído';
        } else if (booking['status'] == 'confirmed') {
          booking['displayStatus'] = 'Confirmado';
        } else if (booking['status'] == 'rejected') {
          booking['displayStatus'] = 'Recusado';
        } else {
          booking['displayStatus'] = 'Pendente';
        }

        final professionalId = booking['professional'];
        if (professionalId != null && professionalId is String && professionalId.length > 20) {
          professionalIdsToResolve.add(professionalId);
        }
      }

      // 2ª passagem: resolve todos os IDs em paralelo (em lotes de 10, limite
      // do operador whereIn do Firestore) em vez de um await sequencial por
      // agendamento — antes eram N round-trips em série, agora são poucos.
      final Map<String, String> professionalNames = {};
      if (professionalIdsToResolve.isNotEmpty) {
        final ids = professionalIdsToResolve.toList();
        const batchSize = 10;
        final batches = <Future<void>>[];

        for (var i = 0; i < ids.length; i += batchSize) {
          final batchIds = ids.sublist(i, i + batchSize > ids.length ? ids.length : i + batchSize);
          batches.add(
            firestore
                .collection('profissionais')
                .where(FieldPath.documentId, whereIn: batchIds)
                .get()
                .then((snap) {
              for (final doc in snap.docs) {
                professionalNames[doc.id] = (doc.data())['name'] ?? doc.id;
              }
            }).catchError((e) {
              debugPrint('Error fetching professional batch: $e');
            }),
          );
        }

        await Future.wait(batches);
      }

      // Aplica os nomes resolvidos (instantâneo, já está tudo em memória).
      for (var booking in bookings) {
        final professionalId = booking['professional'];
        if (professionalId != null && professionalNames.containsKey(professionalId)) {
          booking['professional'] = professionalNames[professionalId];
        }
      }

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBookings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBookings = _bookings.where((booking) {
        return (booking['service'] ?? '').toString().toLowerCase().contains(query) ||
            (booking['professional'] ?? '').toString().toLowerCase().contains(query) ||
            (booking['barbearia'] ?? '').toString().toLowerCase().contains(query) ||
            DateFormat('dd/MM/yyyy').format(DateTime.parse(booking['date'])).contains(query);
      }).toList();
    });
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await firestore.collection('agendamentos').doc(bookingId).update({'status': 'canceled'});
      await _loadBookings();
      if (!mounted) return;
      _showSnack('Agendamento cancelado com sucesso.', _Palette.success);
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      if (mounted) _showSnack('Erro ao cancelar agendamento.', _Palette.error);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pendente':
        return _Palette.warning;
      case 'Confirmado':
        return _Palette.success;
      case 'Recusado':
        return _Palette.error;
      case 'Concluído':
        return _Palette.info;
      case 'Cancelado':
        return _Palette.neutral;
      default:
        return _Palette.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pendente':
        return Icons.hourglass_top_rounded;
      case 'Confirmado':
        return Icons.check_circle_outline_rounded;
      case 'Recusado':
        return Icons.block_rounded;
      case 'Concluído':
        return Icons.done_all_rounded;
      case 'Cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }
void _showBookingDetails(Map<String, dynamic> booking) {
  final dateTime = DateTime.parse(booking['date']);
  final status = booking['displayStatus'] as String;
  final statusColor = _statusColor(status);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) {
      final screenHeight = MediaQuery.of(context).size.height;
      final bottomInset = MediaQuery.of(context).padding.bottom;

      return Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
        decoration: const BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alça de arraste (visual apenas — fechar é por botão ou toque fora)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 8, 22, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho: serviço + status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _Palette.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.content_cut_rounded, color: _Palette.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['service'] ?? '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(status), color: statusColor, size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: _Palette.textSecondary, size: 22),
                            splashRadius: 20,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Cartão de destaque: data, hora e preço
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _Palette.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _highlightItem(
                                icon: Icons.event_rounded,
                                label: DateFormat('dd/MM/yyyy').format(dateTime),
                                sublabel: DateFormat('EEEE', 'pt_BR').format(dateTime),
                              ),
                            ),
                            Container(width: 1, height: 38, color: Colors.white.withOpacity(0.07)),
                            Expanded(
                              child: _highlightItem(
                                icon: Icons.schedule_rounded,
                                label: booking['time'] ?? '-',
                                sublabel: 'Horário',
                              ),
                            ),
                            Container(width: 1, height: 38, color: Colors.white.withOpacity(0.07)),
                            Expanded(
                              child: _highlightItem(
                                icon: Icons.payments_outlined,
                                label: '${booking['price']?.toStringAsFixed(2) ?? 'N/A'}€',
                                sublabel: 'Preço',
                                valueColor: _Palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const _SectionLabel('Atendimento'),
                      const SizedBox(height: 10),
                      _detailTile(Icons.person_outline_rounded, 'Profissional', booking['professional']),
                      _detailTile(Icons.storefront_outlined, 'Barbearia', booking['barbearia']),

                      const SizedBox(height: 20),
                      const _SectionLabel('Dados do cliente'),
                      const SizedBox(height: 10),
                      _detailTile(Icons.badge_outlined, 'Nome', booking['name']),
                      _detailTile(Icons.phone_outlined, 'Telefone', booking['phone']),
                      _detailTile(Icons.alternate_email_rounded, 'Email', booking['email']),

                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _highlightItem({
  required IconData icon,
  required String label,
  required String sublabel,
  Color? valueColor,
}) {
  return Column(
    children: [
      Icon(icon, color: _Palette.textSecondary, size: 17),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor ?? Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        sublabel,
        style: const TextStyle(color: _Palette.textSecondary, fontSize: 10.5),
      ),
    ],
  );
}

Widget _detailTile(IconData icon, String label, String? value) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _Palette.surfaceLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: _Palette.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _Palette.textSecondary, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value ?? '-',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
 

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _Palette.error.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.event_busy_rounded, color: _Palette.error, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancelar agendamento',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tem a certeza que deseja cancelar este agendamento? Esta ação não pode ser desfeita.',
                style: TextStyle(color: _Palette.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: _Palette.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Voltar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _cancelBooking(bookingId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _bookingCard(Map<String, dynamic> booking) {
    final dateTime = DateTime.parse(booking['date']);
    final timeParts = booking['time'].split(':');
    final bookingDateTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final now = DateTime.now();
    final status = booking['displayStatus'] as String;
    final canCancel = status == 'Pendente' || status == 'Confirmado';
    final withinCancelWindow = bookingDateTime.difference(now).inMinutes > 45;
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Palette.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.content_cut_rounded, color: _Palette.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['service'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(dateTime)} · ${booking['time']}',
                        style: const TextStyle(color: _Palette.textSecondary, fontSize: 13),
                      ),
                      Text(
                        booking['professional'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _Palette.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status), color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${booking['price']?.toStringAsFixed(2) ?? 'N/A'}€',
                      style: const TextStyle(color: _Palette.primary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showBookingDetails(booking),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: _Palette.primary),
                  label: const Text('Ver detalhes', style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.w700)),
                ),
                if (canCancel && withinCancelWindow) ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(booking['id']),
                    icon: const Icon(Icons.close_rounded, size: 16, color: _Palette.error),
                    label: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.error,
                      side: const BorderSide(color: _Palette.error, width: 1.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        title: const Text('Histórico de Agendamentos', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _Palette.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _Palette.primary, strokeWidth: 2.6))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    cursorColor: _Palette.primary,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por serviço, profissional, data...',
                      hintStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: _Palette.textSecondary, size: 21),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded, color: _Palette.textSecondary, size: 19),
                            onPressed: () => _searchController.clear(),
                          );
                        },
                      ),
                      filled: true,
                      fillColor: _Palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _Palette.primary, width: 1.3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredBookings.isEmpty
                      ? _EmptyState(
                          hasQuery: _searchController.text.isNotEmpty,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) => _bookingCard(_filteredBookings[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _Palette.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: _Palette.surface, shape: BoxShape.circle),
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.event_note_outlined,
                color: _Palette.textSecondary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasQuery ? 'Nenhum resultado encontrado' : 'Ainda sem agendamentos',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Tente pesquisar por outro serviço, profissional ou data.'
                  : 'Os seus agendamentos vão aparecer aqui assim que forem criados.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}