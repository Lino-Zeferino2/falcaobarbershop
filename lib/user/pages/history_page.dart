// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../firestore_instance.dart';

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

      // Sort bookings by createdAt descending in memory since index is building
      bookings.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Determine status and fetch professional names
      final now = DateTime.now();
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

        // Fetch professional name if it's an ID
        final professionalId = booking['professional'];
        if (professionalId != null && professionalId is String && professionalId.length > 20) { // Assuming IDs are longer than names
          try {
            final profDoc = await firestore.collection('profissionais').doc(professionalId).get();
            if (profDoc.exists) {
              booking['professional'] = profDoc.data()?['name'] ?? professionalId;
            }
          } catch (e) {
            debugPrint('Error fetching professional name: $e');
            // Keep the original value if fetch fails
          }
        }
      }

      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterBookings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBookings = _bookings.where((booking) {
        return booking['service'].toLowerCase().contains(query) ||
               booking['professional'].toLowerCase().contains(query) ||
               booking['barbearia'].toLowerCase().contains(query) ||
               DateFormat('dd/MM/yyyy').format(DateTime.parse(booking['date'])).contains(query);
      }).toList();
    });
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await firestore
          .collection('agendamentos')
          .doc(bookingId)
          .update({'status': 'canceled'});
      await _loadBookings(); // Reload to update status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado com sucesso')),
      );
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cancelar agendamento')),
      );
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text(
          'Detalhes do Agendamento',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Serviço', booking['service']),
              _detailRow('Profissional', booking['professional']),
              _detailRow('Data', '${DateFormat('dd/MM/yyyy').format(DateTime.parse(booking['date']))} - ${DateFormat('EEEE', 'pt_BR').format(DateTime.parse(booking['date']))}'),
              _detailRow('Hora', booking['time']),
              _detailRow('Barbearia', booking['barbearia']),
              _detailRow('Nome', booking['name']),
              _detailRow('Telefone', booking['phone']),
              _detailRow('Email', booking['email']),
              _detailRow('Preço', '${booking['price']?.toStringAsFixed(2) ?? 'N/A'}€'),
              _detailRow('Status', booking['displayStatus']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
        ],
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
    final canCancel = booking['displayStatus'] == 'Pendente' || booking['displayStatus'] == 'Confirmado';
    final timeDiff = bookingDateTime.difference(now).inMinutes > 45;

    Color statusColor;
    switch (booking['displayStatus']) {
      case 'Pendente':
        statusColor = Colors.orange;
        break;
      case 'Confirmado':
        statusColor = Colors.green;
        break;
      case 'Recusado':
        statusColor = Colors.red;
        break;
      case 'Concluído':
        statusColor = Colors.blue;
        break;
      case 'Cancelado':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.white;
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_cut, color: const Color(0xFFB22222), size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['service'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${DateFormat('dd/MM/yyyy').format(dateTime)} - ${booking['time']}', style: const TextStyle(color: Colors.white70)),
                      Text(booking['professional'], style: const TextStyle(color: Colors.white70)),
                      Text('${booking['price']?.toStringAsFixed(2) ?? 'N/A'}€', style: const TextStyle(color:  Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking['displayStatus'],
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showBookingDetails(booking),
                  child: const Text('Ver Detalhes', style: TextStyle(color: Color(0xFFB22222))),
                ),
                if (canCancel && timeDiff) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _showCancelDialog(booking['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Confirmar Cancelamento', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja cancelar este agendamento?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Agendamentos'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar agendamentos...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterBookings();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: _filteredBookings.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum agendamento encontrado',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredBookings.length,
                            itemBuilder: (context, index) => _bookingCard(_filteredBookings[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
