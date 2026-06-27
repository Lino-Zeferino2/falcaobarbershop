import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../model/notification_model.dart';
import 'home_admin.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onNavigateToAppointments;

  const NotificationsPage({super.key, this.onNavigateToAppointments});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AdminController _adminController = AdminController();
  String _selectedFilter = 'Todos'; // 'Todos', 'Lido', 'Não Lido'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Notificações', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Filter chips and Mark All as Read button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == 'Todos',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'Todos';
                        });
                      },
                      backgroundColor: const Color(0xFF2A2A2A),
                      selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                      checkmarkColor: const Color(0xFFB22222),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Todos' ? const Color(0xFFB22222) : Colors.white,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Lido'),
                      selected: _selectedFilter == 'Lido',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'Lido';
                        });
                      },
                      backgroundColor: const Color(0xFF2A2A2A),
                      selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                      checkmarkColor: const Color(0xFFB22222),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Lido' ? const Color(0xFFB22222) : Colors.white,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Não Lido'),
                      selected: _selectedFilter == 'Não Lido',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'Não Lido';
                        });
                      },
                      backgroundColor: const Color(0xFF2A2A2A),
                      selectedColor: const Color(0xFFB22222).withOpacity(0.2),
                      checkmarkColor: const Color(0xFFB22222),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Não Lido' ? const Color(0xFFB22222) : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mark all as read button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Marcar Todas como Lidas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _adminController.getAllNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final allNotifications = snapshot.data ?? [];

                // Apply filter
                final notifications = allNotifications.where((notification) {
                  if (_selectedFilter == 'Lido') {
                    return notification.lida;
                  } else if (_selectedFilter == 'Não Lido') {
                    return !notification.lida;
                  }
                  return true; // 'Todos'
                }).toList();

                // Sort by createdAt descending (most recent first)
                notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma notificação encontrada',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      color: notification.lida
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFF3A3A3A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          notification.lida
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: notification.lida ? Colors.white70 : const Color(0xFFB22222),
                        ),
                        title: Text(
                          notification.titulo,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notification.lida ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.mensagem,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(notification.createdAt),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark_read') {
                              _markAsRead(notification.id);
                            } else if (value == 'delete') {
                              _deleteNotification(notification.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!notification.lida)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Text('Marcar como lida'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir'),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                        onTap: () async {
                          // Navigate to appointments page without marking as read
                          if (widget.onNavigateToAppointments != null) {
                            await _markAsRead(notification.id);
                            widget.onNavigateToAppointments!();
                          } else {
                            // Fallback: navigate to home_admin and select appointments tab
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeAdmin(),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora';
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _adminController.markNotificationAsRead(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificação marcada como lida')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar como lida: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Notificação'),
        content: const Text('Tem certeza que deseja excluir esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.deleteNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificação excluída')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir notificação: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _adminController.markAllNotificationsAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas as notificações foram marcadas como lidas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar todas como lidas: $e')),
      );
    }
  }

  Future<void> _showAddNotificationDialog() async {
    final tituloController = TextEditingController();
    final mensagemController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Notificação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mensagemController,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tituloController.text.isNotEmpty && mensagemController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _adminController.addNotification(
          tituloController.text,
          mensagemController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificação criada com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar notificação: $e')),
        );
      }
    }
  }
}
