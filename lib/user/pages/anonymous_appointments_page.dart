import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../admin/controller/admin_controller.dart';
import '../../admin/model/appointment_model.dart';

class AnonymousAppointmentsPage extends StatefulWidget {
  const AnonymousAppointmentsPage({super.key});

  @override
  State<AnonymousAppointmentsPage> createState() => _AnonymousAppointmentsPageState();
}

class _AnonymousAppointmentsPageState extends State<AnonymousAppointmentsPage> {
  final TextEditingController _emailController = TextEditingController();
  final AdminController _adminController = AdminController();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _loadLoggedAppointments() async {
    // Para usuários logados, listamos pelos dados do próprio usuário.
    // Como a query atual do AdminController é por email, usamos o email do Firebase.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email == null || email.isEmpty) {
      setState(() {
        _hasSearched = true;
        _appointments = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _adminController.getAppointmentsByEmail(email);
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao buscar agendamentos. Tente novamente.';
        _appointments = [];
        _hasSearched = true;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Se estiver logado, já lista sem precisar de email.
    if (_isLoggedIn) {
      _hasSearched = true;
      _loadLoggedAppointments();
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchAppointments() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Por favor, insira um email.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Por favor, insira um email válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _adminController.getAppointmentsByEmail(email);
      setState(() {
        _appointments = appointments;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar agendamentos. Tente novamente.';
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text('Tem certeza que deseja cancelar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminController.cancelAppointment(appointmentId);
      await _searchAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento cancelado com sucesso!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cancelar agendamento.')),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Formato: não ocupa 100% largura (laterais).
            final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 16.0;
            final maxContentWidth = constraints.maxWidth > 1200 ? 1100.0 : constraints.maxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header moderno
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2A2A2A),
                              Color(0xFF0D0D0D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meus Agendamentos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isLoggedIn
                                ? Text(
                                    'Seus agendamentos já estão carregados.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 14,
                                    ),
                                  )
                                : Text(
                                    'Digite seu email para ver seus horários.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 14,
                                    ),
                                  ),
                            const SizedBox(height: 14),

                            // Form: só para usuários NÃO logados
                            if (!_isLoggedIn)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.06),
                                      labelText: 'Email',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.email, color: Color(0xFFB22222)),
                                      errorText: _errorMessage,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) => _isLoading ? null : _searchAppointments(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _searchAppointments,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Buscar',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_hasSearched)
                        Text(
                          _appointments.isEmpty
                              ? 'Nenhum agendamento encontrado para este email.'
                              : 'Seus agendamentos:',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      if (_hasSearched) const SizedBox(height: 12),

                      // Lista
                      if (_hasSearched)
                        Expanded(
                          child: _appointments.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Preencha seu email e clique em Buscar.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _appointments.length,
                                  itemBuilder: (context, index) {
                                    final appointment = _appointments[index];

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      color: const Color(0xFF0D0D0D),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(appointment.dateTime),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(appointment.status),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(appointment.status),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            _detailRow('Horário', DateFormat('HH:mm').format(appointment.dateTime)),
                                            const SizedBox(height: 4),
                                            _detailRow('Serviço', appointment.serviceName),
                                            const SizedBox(height: 4),
                                            _detailRow('Profissional', appointment.barberName),
                                            const SizedBox(height: 4),
                                            _detailRow(
                                              'Preço',
                                              'R\$ ${appointment.price.toStringAsFixed(2)}',
                                              valueColor: const Color(0xFFB22222),
                                            ),

                                            if (appointment.status == 'pending' || appointment.status == 'confirmed')
                                              const SizedBox(height: 14),

                                            if (appointment.status == 'pending' || appointment.status == 'confirmed')
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () => _cancelAppointment(appointment.id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancelar Agendamento',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                      // caso ainda não tenha buscado
                      if (!_hasSearched)
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(top: 40),
                            child: const Text(
                              'Digite seu email acima e clique em Buscar.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFF0D0D0D),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 15,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

