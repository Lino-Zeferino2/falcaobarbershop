import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../admin/controller/admin_controller.dart';
import '../../admin/model/appointment_model.dart';

// Mesma paleta usada no login/registro — mantém a identidade visual do app.
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
}

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

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      _hasSearched = true;
      _loadLoggedAppointments();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLoggedAppointments() async {
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
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
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
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      setState(() {
        _appointments = appointments;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (_) {
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
                decoration: BoxDecoration(
                  color: _Palette.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
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
                      onPressed: () => Navigator.of(context).pop(false),
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
                      onPressed: () => Navigator.of(context).pop(true),
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

    if (confirmed != true) return;

    try {
      await _adminController.cancelAppointment(appointmentId);
      if (_isLoggedIn) {
        await _loadLoggedAppointments();
      } else {
        await _searchAppointments();
      }

      if (mounted) {
        _showSnack('Agendamento cancelado com sucesso!', _Palette.success);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Erro ao cancelar agendamento.', _Palette.error);
      }
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
        return _Palette.warning;
      case 'confirmed':
        return _Palette.success;
      case 'completed':
        return _Palette.info;
      case 'cancelled':
      case 'cancelado':
        return _Palette.error;
      default:
        return _Palette.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        title: const Text('Meus Agendamentos', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _Palette.background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 16.0;
            final maxContentWidth = constraints.maxWidth > 1200 ? 1100.0 : constraints.maxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchHeader(
                        isLoggedIn: _isLoggedIn,
                        emailController: _emailController,
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onSearch: _searchAppointments,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildBody(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _Palette.primary, strokeWidth: 2.6),
      );
    }

    if (!_hasSearched) {
      return const _EmptyState(
        icon: Icons.search_rounded,
        title: 'Consulte os seus horários',
        subtitle: 'Digite o seu email acima e toque em Buscar para ver os seus agendamentos.',
      );
    }

    if (_appointments.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Nenhum agendamento encontrado',
        subtitle: 'Não encontrámos agendamentos associados a este email.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            '${_appointments.length} ${_appointments.length == 1 ? 'agendamento encontrado' : 'agendamentos encontrados'}',
            style: const TextStyle(
              color: _Palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: _appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              final canCancel = appointment.status == 'pending' || appointment.status == 'confirmed';
              return _AppointmentCard(
                appointment: appointment,
                statusText: _getStatusText(appointment.status),
                statusColor: _getStatusColor(appointment.status),
                statusIcon: _getStatusIcon(appointment.status),
                canCancel: canCancel,
                onCancel: () => _cancelAppointment(appointment.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------- Componentes ----------

class _SearchHeader extends StatelessWidget {
  final bool isLoggedIn;
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSearch;

  const _SearchHeader({
    required this.isLoggedIn,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [_Palette.surfaceLight, _Palette.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _Palette.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: _Palette.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Os seus agendamentos',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLoggedIn
                          ? 'Sincronizados com a sua conta.'
                          : 'Digite o seu email para consultar os horários marcados.',
                      style: const TextStyle(color: _Palette.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: _Palette.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _Palette.background,
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: _Palette.textSecondary, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        borderSide: const BorderSide(color: _Palette.primary, width: 1.4),
                      ),
                      errorText: errorMessage,
                      errorStyle: const TextStyle(color: _Palette.error, fontSize: 12),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => isLoading ? null : onSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      disabledBackgroundColor: _Palette.primary.withOpacity(0.6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text(
                              'Buscar',
                              key: ValueKey('label'),
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final bool canCancel;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _Palette.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_rounded, color: _Palette.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(appointment.dateTime),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        DateFormat('HH:mm').format(appointment.dateTime),
                        style: const TextStyle(fontSize: 13, color: _Palette.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 14),
          _detailRow(Icons.design_services_outlined, 'Serviço', appointment.serviceName),
          const SizedBox(height: 10),
          _detailRow(Icons.person_outline_rounded, 'Profissional', appointment.barberName),
          const SizedBox(height: 10),
          _detailRow(
            Icons.payments_outlined,
            'Preço',
            'R\$ ${appointment.price.toStringAsFixed(2)}',
            valueColor: _Palette.primary,
          ),
          if (canCancel) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 17, color: _Palette.error),
                label: const Text(
                  'Cancelar agendamento',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Palette.error,
                  side: const BorderSide(color: _Palette.error, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _Palette.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: valueColor != null ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

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
              decoration: BoxDecoration(
                color: _Palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _Palette.textSecondary, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}