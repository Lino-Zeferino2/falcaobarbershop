// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../model/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onNavigateToAppointments;
  const NotificationsPage({super.key, this.onNavigateToAppointments});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AdminController _adminController = AdminController();
  String _filter = 'Todos';

  static const _red = Color(0xFFB22222);
  static const _card = Color(0xFF1A1A1A);
  static const _bg = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white.withOpacity(0.08)),
        ),
        title: const Text('Notificações',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, size: 16, color: Colors.white54),
            label: const Text('Marcar todas', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Não Lido', 'Lido'];
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _red : _bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _red : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(f,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _adminController.getAllNotifications(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _red));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Erro: ${snap.error}', style: const TextStyle(color: Colors.white54)),
          );
        }

        final all = snap.data ?? [];
        final filtered = all.where((n) {
          if (_filter == 'Lido') return n.lida;
          if (_filter == 'Não Lido') return !n.lida;
          return true;
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _filter == 'Não Lido'
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_outlined,
                  color: Colors.white24, size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _filter == 'Não Lido'
                      ? 'Sem notificações por ler.'
                      : 'Sem notificações.',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Agrupa por data
        final grouped = <String, List<NotificationModel>>{};
        for (final n in filtered) {
          final key = _groupKey(n.createdAt);
          grouped.putIfAbsent(key, () => []).add(n);
        }

        final keys = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: keys.length,
          itemBuilder: (_, i) {
            final key = keys[i];
            final items = grouped[key]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(key,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                ...items.map((n) => _notifCard(n)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _notifCard(NotificationModel n) {
    final unread = !n.lida;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          await _markAsRead(n.id);
          if (widget.onNavigateToAppointments != null) {
            widget.onNavigateToAppointments!();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? _red.withOpacity(0.06) : _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? _red.withOpacity(0.25) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: unread ? _red.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _notifIcon(n.tipo),
                  color: unread ? _red : Colors.white38,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.titulo,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (unread)
                          Container(
                            width: 7, height: 7,
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.mensagem,
                        style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_relativeTime(n.createdAt),
                        style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                color: const Color(0xFF222222),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.white24, size: 18),
                onSelected: (v) {
                  if (v == 'read') _markAsRead(n.id);
                  if (v == 'delete') _deleteNotification(n.id);
                },
                itemBuilder: (_) => [
                  if (unread)
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Marcar como lida', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Apagar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notifIcon(String tipo) {
    switch (tipo) {
      case 'new_booking': return Icons.calendar_today_outlined;
      case 'confirmed': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      case 'completed': return Icons.done_all_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  String _groupKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    if (now.difference(dt).inDays < 7) return 'Esta semana';
    return 'Mais antigas';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min atrás';
    return 'Agora';
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _adminController.markNotificationAsRead(id);
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _adminController.deleteNotification(id);
      if (mounted) _snack('Notificação apagada');
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _adminController.markAllNotificationsAsRead();
      if (mounted) _snack('Todas marcadas como lidas');
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFFB22222),
    ));
  }
}