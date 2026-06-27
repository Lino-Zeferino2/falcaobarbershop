
import 'package:falcaobarbershopv2/user/widgets/professional_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../model/user_model.dart';
import '../../admin/model/barbearia_model.dart';
import '../../admin/model/profissional_model.dart';
import '../../firestore_instance.dart';
import '../../services/email_service.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? selectedService;
  final BarbeariaModel? selectedBarbearia;

  const BookingPage({super.key, this.selectedService, this.selectedBarbearia});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with TickerProviderStateMixin {
  int _currentStep = 0;
  BarbeariaModel? _selectedBarbearia;
  Map<String, dynamic>? _selectedService;
  ProfissionalModel? _selectedProfessional;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _createAccount = false;
  bool _agreeToTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _usePoints = false;
  double _discount = 0.0;
  bool _showAllServices = false;

  bool _isCompletingBooking = false;


  double get _finalPrice {
    double basePrice = _parsePrice(_selectedService!['preco']!);
    if (_usePoints && _currentUser != null && _userData != null && _userData!.points >= 100.0) {
      int discountBlocks = _userData!.points ~/ 100;
      double discountPercent = discountBlocks * 0.1;
      return basePrice * (1 - discountPercent);
    }
    return basePrice;
  }

  int get _availableDiscountBlocks {
    if (_currentUser != null && _userData != null && _userData!.points >= 100.0) {
      return 1; // Limit to 1 block (10% discount) per booking
    }
    return 0;
  }

  User? _currentUser;
  UserModel? _userData;

  // Error messages
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<BarbeariaModel> _barbearias = [];
  List<ProfissionalModel> _profissionais = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, TimeOfDay>> _bookedTimes = [];
  List<DateTime> _bookedDates = [];
  int _calendarKey = 0;

  bool _isLoadingProfissionais = false;
  bool _isLoadingBarbearias = false;

  void _loadBookedDates() async {
    // Removed fully booked dates logic since slot counts now vary by service
    _bookedDates = [];
    if (mounted) setState(() {});
  }

  void _loadBarbearias() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingBarbearias = true;
          _barbearias = [];
        });
      }

      QuerySnapshot snapshot = await firestore.collection('barbearias').get();
      _barbearias = snapshot.docs
          .map((doc) => BarbeariaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((b) => b.isActive)
          .toList();
    } catch (e) {
      debugPrint('Error loading barbearias: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBarbearias = false;
        });
      }
    }
  }

  Future<void> _loadProfissionais() async {
    if (_selectedBarbearia == null) return;

    if (mounted) {
      setState(() {
        _isLoadingProfissionais = true;
        _profissionais = [];
      });
    }

    try {
      QuerySnapshot snapshot = await firestore
          .collection('profissionais')
          .where('barbeariaId', isEqualTo: _selectedBarbearia!.id)
          .get();

      _profissionais = snapshot.docs
          .map((doc) => ProfissionalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => p.disponivel)
          .toList();

      debugPrint('Loaded ${_profissionais.length} profissionais for barbearia ${_selectedBarbearia!.id}');
    } catch (e) {
      debugPrint('Error loading profissionais: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfissionais = false);
      }
    }
  }

  void _loadServices() async {
    if (_selectedProfessional != null) {
      try {
        QuerySnapshot snapshot = await firestore
            .collection('servicos')
            .where('profissionalId', isEqualTo: _selectedProfessional!.userId)
            .where('ativo', isEqualTo: true)
            .get();
        _services = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        debugPrint('Loaded ${_services.length} services for professional ${_selectedProfessional!.userId}');
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error loading services: $e');
      }
    }
  }

  Future<void> _loadBookedTimes() async {
    if (_selectedProfessional != null && _selectedDate != null) {
      try {
        String dateString =
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

        // 1) Agendamentos do banco falcaobarbershop (instância firestore)
        final QuerySnapshot snapshotFalca = await firestore
            .collection('agendamentos')
            .where('professional', isEqualTo: _selectedProfessional!.userId)
            .where('date', isEqualTo: dateString)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        // 2) Agendamentos (somente Firebase default)
        final QuerySnapshot snapshotDefault = await firestore
            .collection('agendamentos')
            .where('professional', isEqualTo: _selectedProfessional!.userId)
            .where('date', isEqualTo: dateString)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        final falcaBooked = snapshotFalca.docs.map((doc) {
          String timeStr = doc['time'];
          List<String> parts = timeStr.split(':');
          final start = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          final int duration = (doc['duracao'] ?? 0);
          final int intervalo = (doc['intervalo'] ?? 0);
          final int endTotalMinutes = start.hour * 60 + start.minute + duration + intervalo;
          final end = TimeOfDay(hour: endTotalMinutes ~/ 60, minute: endTotalMinutes % 60);
          return {'start': start, 'end': end};
        }).toList();

        final defaultBooked = snapshotDefault.docs.map((doc) {
          String timeStr = doc['time'];
          List<String> parts = timeStr.split(':');
          final start = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          final int duration = (doc['duracao'] ?? 0);
          final int intervalo = (doc['intervalo'] ?? 0);
          final int endTotalMinutes = start.hour * 60 + start.minute + duration + intervalo;
          final end = TimeOfDay(hour: endTotalMinutes ~/ 60, minute: endTotalMinutes % 60);
          return {'start': start, 'end': end};
        }).toList();

        _bookedTimes = [...falcaBooked, ...defaultBooked];

        debugPrint(
          'Loaded ${_bookedTimes.length} booked times (falcaobarbershop + default) for ${_selectedProfessional!.name} on $dateString',
        );

        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error loading booked times: $e');
      }
    } else {
      _bookedTimes = [];
      if (mounted) setState(() {});
    }
  }

  bool _isDayAvailable(DateTime day) {
    if (_selectedProfessional == null) {
      return day.weekday != DateTime.sunday; // Fallback: no Sundays
    }
    const weekdayMap = {
      1: "segunda",
      2: "terça",
      3: "quarta",
      4: "quinta",
      5: "sexta",
      6: "sábado",
      7: "domingo"
    };
    final dayName = weekdayMap[day.weekday];
    bool isWorkingDay = _selectedProfessional!.diasAtendimento.contains(dayName);

    bool isFullyBooked = _bookedDates.any(
      (bookedDate) => bookedDate.year == day.year && bookedDate.month == day.month && bookedDate.day == day.day,
    );

    return isWorkingDay && !isFullyBooked;
  }

  DateTime _getFirstAvailableDate() {
    if (_selectedProfessional == null) return DateTime.now();
    DateTime checkDate = DateTime.now();
    for (int i = 0; i < 30; i++) {
      if (_isDayAvailable(checkDate)) {
        return checkDate;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    return DateTime.now();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  List<TimeOfDay> _generateTimes(TimeOfDay start, TimeOfDay end, int interval) {
    List<TimeOfDay> times = [];
    TimeOfDay current = start;
    int endTotalMinutes = end.hour * 60 + end.minute;
    while (true) {
      int currentTotalMinutes = current.hour * 60 + current.minute;
      if (currentTotalMinutes + interval > endTotalMinutes) break;
      times.add(current);
      int nextTotalMinutes = currentTotalMinutes + interval;
      current = TimeOfDay(hour: nextTotalMinutes ~/ 60, minute: nextTotalMinutes % 60);
    }
    return times;
  }

  List<TimeOfDay> _getAvailableTimes() {
    if (_selectedProfessional == null || _selectedService == null) {
      return [];
    }

    int serviceDuration = _selectedService!['duracao'] ?? 0;
    List<TimeOfDay> times = [];
    Map<String, Map<String, String>> turnos;

    // Check for specific schedules for the selected date
    if (_selectedDate != null && _selectedProfessional!.horariosPorDia != null) {
      String dateKey =
          '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';

      if (_selectedProfessional!.horariosPorDia!.containsKey(dateKey)) {
        var specificTurnos = _selectedProfessional!.horariosPorDia![dateKey];
        if (specificTurnos == null) {
          return [];
        } else {
          turnos = specificTurnos.map((key, value) => MapEntry(key, Map<String, String>.from(value as Map)));
        }
      } else {
        turnos = _selectedProfessional!.turnos;
      }
    } else {
      turnos = _selectedProfessional!.turnos;
    }

    if (turnos.containsKey('manha')) {
      final manha = turnos['manha']!;
      final start = _parseTime(manha['inicio']!);
      final end = _parseTime(manha['fim']!);
      TimeOfDay current = start;
      int endTotalMinutes = end.hour * 60 + end.minute;

      while (current.hour * 60 + current.minute + serviceDuration <= endTotalMinutes) {
        times.add(current);
        int nextTotalMinutes = current.hour * 60 + current.minute + serviceDuration + _selectedProfessional!.intervaloMinutos;
        current = TimeOfDay(hour: nextTotalMinutes ~/ 60, minute: nextTotalMinutes % 60);
      }
    }

    if (turnos.containsKey('tarde')) {
      final tarde = turnos['tarde']!;
      final start = _parseTime(tarde['inicio']!);
      final end = _parseTime(tarde['fim']!);
      TimeOfDay current = start;
      int endTotalMinutes = end.hour * 60 + end.minute;

      while (current.hour * 60 + current.minute + serviceDuration <= endTotalMinutes) {
        times.add(current);
        int nextTotalMinutes = current.hour * 60 + current.minute + serviceDuration + _selectedProfessional!.intervaloMinutos;
        current = TimeOfDay(hour: nextTotalMinutes ~/ 60, minute: nextTotalMinutes % 60);
      }
    }

    // Filter out booked times considering overlaps
    times = times.where((time) {
      int proposedStartMinutes = time.hour * 60 + time.minute;
      int proposedEndMinutes = proposedStartMinutes + serviceDuration;

      for (var booked in _bookedTimes) {
        TimeOfDay bookedStart = booked['start']!;
        TimeOfDay bookedEnd = booked['end']!;
        int bookedStartMinutes = bookedStart.hour * 60 + bookedStart.minute;
        int bookedEndMinutes = bookedEnd.hour * 60 + bookedEnd.minute;

        if (proposedStartMinutes < bookedEndMinutes && proposedEndMinutes > bookedStartMinutes) {
          return false;
        }
      }
      return true;
    }).toList();

    // Filter out past times if the selected date is today
    if (_selectedDate != null && isSameDay(_selectedDate, DateTime.now())) {
      final now = TimeOfDay.now();

      final bufferTime = TimeOfDay(hour: now.hour, minute: now.minute + 30);
      final adjustedNow = bufferTime.hour > now.hour ||
              (bufferTime.hour == now.hour && bufferTime.minute > now.minute)
          ? bufferTime
          : TimeOfDay(hour: now.hour + 1, minute: now.minute);

      times = times
          .where((time) => time.hour > adjustedNow.hour || (time.hour == adjustedNow.hour && time.minute > adjustedNow.minute))
          .toList();
    }

    return times;
  }

  List<TimeOfDay> _getAllAvailableTimesForDate(DateTime date) {
    if (_selectedProfessional == null) return [];
    List<TimeOfDay> times = [];
    final turnos = _selectedProfessional!.turnos;

    if (turnos.containsKey('manha')) {
      final manha = turnos['manha']!;
      final start = _parseTime(manha['inicio']!);
      final end = _parseTime(manha['fim']!);
      times.addAll(_generateTimes(start, end, _selectedProfessional!.intervaloMinutos));
    }
    if (turnos.containsKey('tarde')) {
      final tarde = turnos['tarde']!;
      final start = _parseTime(tarde['inicio']!);
      final end = _parseTime(tarde['fim']!);
      times.addAll(_generateTimes(start, end, _selectedProfessional!.intervaloMinutos));
    }

    return times;
  }

  double _parsePrice(dynamic price) {
    if (price is String) {
      return double.tryParse(price.replaceAll('€', '')) ?? 0.0;
    } else if (price is num) {
      return price.toDouble();
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, now.day);
    while (initialDate.weekday == DateTime.sunday) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    _selectedDate = initialDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _selectedService = widget.selectedService;
    _selectedBarbearia = widget.selectedBarbearia;

    _loadUserData();
    _loadBarbearias();

    if (_selectedBarbearia != null) {
      _loadProfissionais();
    }

    if (_selectedProfessional != null) {
      _loadServices();
    }

    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.removeListener(_validateForm);
    _phoneController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);

    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc = await firestore.collection('clientes').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          _userData = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          DocumentSnapshot oldUserDoc = await firestore.collection('users').doc(_currentUser!.uid).get();
          if (oldUserDoc.exists) {
            _userData = UserModel.fromMap(oldUserDoc.data() as Map<String, dynamic>);
          }
        }

        if (_userData != null && mounted) {
          setState(() {
            _nameController.text = _userData!.name;
            _phoneController.text = _userData!.phone;
            _emailController.text = _userData!.email;
            _agreeToTerms = true;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    return weekdays[weekday - 1];
  }

  void _validateForm() {
    if (!mounted) return;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Nome é obrigatório';
      } else if (_nameController.text.trim().split(' ').length < 2) {
        _nameError = 'Nome deve ter pelo menos nome e sobrenome';
      }

      if (_phoneController.text.trim().isEmpty) {
        _phoneError = 'Telefone é obrigatório';
      } else if (!RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(_phoneController.text.trim())) {
        _phoneError = 'Telefone inválido';
      } else {
        String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 9) {
          _phoneError = 'Telefone deve ter exatamente 9 dígitos';
        }
      }

      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Email é obrigatório';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
        _emailError = 'Email inválido';
      }

      if (_createAccount) {
        if (_passwordController.text.isEmpty) {
          _passwordError = 'Senha é obrigatória';
        } else if (_passwordController.text.length < 6) {
          _passwordError = 'Senha deve ter pelo menos 6 caracteres';
        }

        if (_confirmPasswordController.text.isEmpty) {
          _confirmPasswordError = 'Confirmação de senha é obrigatória';
        } else if (_passwordController.text != _confirmPasswordController.text) {
          _confirmPasswordError = 'Senhas não coincidem';
        }
      }
    });
  }

  void _nextStep() {
    if (!mounted) return;
    _validateForm();

    if (_currentStep < 4) {
      if (_isStepValid()) {
        setState(() {
          _currentStep++;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } else {
      if (_isStepValid()) {
        _showSummaryDialog();
      }
    }
  }

  void _previousStep() {
    if (!mounted) return;
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedBarbearia != null;
      case 1:
        return _selectedProfessional != null;
      case 2:
        return _selectedService != null;
      case 3:
        return _selectedDate != null && _selectedTime != null;
      case 4:
        bool nameValid = _nameController.text.trim().split(' ').length >= 2;
        bool agreeToTermsValid = _currentUser != null || _agreeToTerms;
        return nameValid &&
            _phoneController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            agreeToTermsValid &&
            (!_createAccount ||
                (_passwordController.text.length >= 6 &&
                    _passwordController.text == _confirmPasswordController.text));
      default:
        return false;
    }
  }

  /// Fluxo principal de completar o agendamento (salva no Firestore, envia email, cria conta opcional, mostra dialog)
  Future<void> _completeBooking() async {
    if (!mounted) return;

    setState(() {
      _isCompletingBooking = true;
    });

    final String formattedTime = '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    // Verificar se há sobreposição de horários
    final String dateString =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    try {
      // 1) Criar conta se selecionado
      if (_createAccount) {
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          await firestore.collection('clientes').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'city': 'Castelo Branco',
            'role': 'cliente',
            'points': 0.0,
            'createdAt': Timestamp.now(),
          });

          _currentUser = userCredential.user;
        } catch (e) {
          debugPrint('Error creating account: $e');
        }
      }

      // Prepara dados do agendamento
      final int durationMinutes = (_selectedService!['duracao'] as int);
      final int intervaloMinutos = _selectedProfessional!.intervaloMinutos;

      final String bookingDateString =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      final Map<String, dynamic> bookingData = {
        'service': _selectedService!['nome'],
        'professional': _selectedProfessional!.userId,
        'date': bookingDateString,
        'time': formattedTime,
        'barbearia': _selectedBarbearia!.name,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'price': _finalPrice,
        'status': 'pending',
        'duracao': durationMinutes,
        'intervalo': intervaloMinutos,
        'createdAt': Timestamp.now(),
      };

      final String anonymousId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_currentUser != null) {
        bookingData['userId'] = _currentUser!.uid;
      } else {
        bookingData['anonymousId'] = anonymousId;
      }

      // Salvar booking de forma atômica via Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('createBooking');

      // IMPORTANT: no Web, values vindos do Firestore podem chegar como Int64.
      // cloud_functions (dart2js) não serializa Int64 -> força conversão para primitivos.
      final int safeDurationMinutes = (durationMinutes as num).toInt();
      final int safeIntervaloMinutos = (intervaloMinutos as num).toInt();
      final double safePrice = (_finalPrice as num).toDouble();

      try {
        final result = await callable.call({
          'professionalId': _selectedProfessional!.userId,
          'dateString': bookingDateString,
          'timeString': formattedTime,
          'serviceName': _selectedService!['nome'],
          'professionalName': _selectedProfessional!.name,
          'barbeariaName': _selectedBarbearia!.name,
          'clientName': _nameController.text,
          'clientPhone': _phoneController.text,
          'clientEmail': _emailController.text,
          'price': safePrice,
          'durationMinutes': safeDurationMinutes,
          'intervaloMinutos': safeIntervaloMinutos,
          'userId': _currentUser?.uid,
          'anonymousId': _currentUser == null ? anonymousId : null,
        });

        debugPrint('createBooking result: $result');
      } on FirebaseFunctionsException catch (e) {
        debugPrint('createBooking FirebaseFunctionsException: code=${e.code} message=${e.message}');
        final msg = (e.message ?? '').toLowerCase();

        if (msg.contains('agendamento duplicado')) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              title: const Text(
                'Agendamento Duplicado',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Você já possui um agendamento pendente ou confirmado para este mesmo horário. Por favor, verifique seus agendamentos existentes.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }

        if (msg.contains('horário indisponível') || msg.contains('horario indisponivel')) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              title: const Text(
                'Horário Indisponível',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'O horário selecionado se sobrepõe com um agendamento existente. Por favor, escolha outro horário.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }

        rethrow;
      }

      // Salvar dados do usuário anônimo (mantém comportamento atual)
      if (_currentUser == null) {
        final anonymousData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'anonymousId': bookingData['anonymousId'],
          'createdAt': Timestamp.now(),
        };
        await firestore.collection('clientes_anonimos').add(anonymousData);
      }

      // Atualizar ocupação local
      int newEndTotalMinutes =
          _selectedTime!.hour * 60 + _selectedTime!.minute + durationMinutes + intervaloMinutos;
      TimeOfDay newEnd = TimeOfDay(hour: newEndTotalMinutes ~/ 60, minute: newEndTotalMinutes % 60);
      _bookedTimes.add({'start': _selectedTime!, 'end': newEnd});
      if (mounted) setState(() {});

      // Atualizar pontos (mantém comportamento atual)
      if (_currentUser != null) {
        try {
          await firestore.collection('clientes').doc(_currentUser!.uid).update({
            'points': FieldValue.increment(10.0),
          });

          await firestore.collection('clientes').doc(_currentUser!.uid).collection('pointsHistory').add({
            'type': 'earned',
            'description': 'Agendamento confirmado: ${_selectedService!['nome']}',
            'points': 10.0,
            'date': Timestamp.now(),
          });

          if (_usePoints) {
            double pointsToSubtract = _availableDiscountBlocks * 100.0;
            await firestore.collection('clientes').doc(_currentUser!.uid).update({
              'points': FieldValue.increment(-pointsToSubtract),
            });

            await firestore.collection('clientes').doc(_currentUser!.uid).collection('pointsHistory').add({
              'type': 'spent',
              'description': 'Desconto de ${_availableDiscountBlocks * 10}% aplicado no agendamento',
              'points': -pointsToSubtract,
              'date': Timestamp.now(),
            });
          }
        } catch (e) {
          debugPrint('Erro ao atualizar pontos: $e');
        }
      }

      // Enviar emails (mantém comportamento atual)
      final emailService = EmailService();
      bool clientEmailOk = false;
      bool adminEmailOk = false;

      try {
        debugPrint('📧 Tentando enviar email para cliente...');
        clientEmailOk = await _sendBookingReceivedEmail(formattedTime);
        debugPrint('📧 Email para cliente: ${clientEmailOk ? 'SUCESSO' : 'FALHA'}');
      } catch (e) {
        debugPrint('❌ Erro ao enviar email para cliente: $e');
      }

      try {
        debugPrint('📧 Tentando enviar email para admin...');
        adminEmailOk = await emailService.sendNewAppointmentNotificationToAdmin(
          service: _selectedService!['nome'],
          professional: _selectedProfessional!.name,
          date: '${_selectedDate?.toLocal().toString().split(' ')[0]} (${_getWeekdayName(_selectedDate!.weekday)})',
          time: formattedTime,
          barbearia: _selectedBarbearia!.name,
          clientName: _nameController.text,
          clientPhone: _phoneController.text,
          clientEmail: _emailController.text,
          price: _finalPrice,
        );
        debugPrint('📧 Email para admin: ${adminEmailOk ? 'SUCESSO' : 'FALHA'}');
      } catch (e) {
        debugPrint('❌ Erro ao enviar email para admin: $e');
      }

      if (!mounted) return;

      String title = 'Agendamento Confirmado';
      String message = 'Seu agendamento foi submetido com sucesso.';

      if (!clientEmailOk && !adminEmailOk) {
        title = 'Agendamento Confirmado (Emails falharam)';
        message = 'Seu agendamento foi submetido, mas houve erros ao enviar os emails. Entraremos em contato em breve.';
      } else if (!clientEmailOk) {
        title = 'Agendamento Confirmado (Email cliente falhou)';
        message = 'Seu agendamento foi submetido, mas houve um erro ao enviar o email de confirmação. O admin foi notificado.';
      } else if (!adminEmailOk) {
        title = 'Agendamento Confirmado (Email admin falhou)';
        message = 'Seu agendamento foi submetido com sucesso. Você receberá um email de confirmação, mas o admin pode não ter sido notificado.';
      } else {
        message = 'Seu agendamento foi submetido com sucesso. Você receberá um email de confirmação.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0D0D0D),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Error completing booking: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0D0D0D),
          title: const Text(
            'Erro no Agendamento',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Ocorreu um erro ao processar o agendamento: $e',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingBooking = false;
        });
      }
    }
  }

  Future<bool> _sendBookingReceivedEmail(String formattedTime) async {
    final emailService = EmailService();
    return await emailService.sendBookingReceivedEmail(
      service: _selectedService?['nome'] ?? 'Não informado',
      professional: _selectedProfessional?.name ?? 'Não informado',
      date: '${_selectedDate?.toLocal().toString().split(' ')[0]} (${_getWeekdayName(_selectedDate!.weekday)})',
      time: formattedTime,
      barbearia: _selectedBarbearia?.name ?? 'Falcão Barbershop',
      name: _nameController.text.isNotEmpty ? _nameController.text : (_currentUser?.displayName ?? 'Cliente'),
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : 'Não informado',
      email: _emailController.text.isNotEmpty ? _emailController.text : (_currentUser?.email ?? 'cliente@naoinformado.com'),
      price: _finalPrice,
    );
  }

  void _showSummaryDialog() {
    final String formattedTime = '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              title: const Text(
                'Resumo do Agendamento',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Confirme os detalhes do seu agendamento:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.content_cut, color: Color(0xFFB22222)),
                        title: const Text('Serviço', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedService!['nome']!} - ${_selectedService!['duracao']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            if (_usePoints && _currentUser != null && _userData != null && _userData!.points >= 100.0)
                              Text(
                                'Preço: €${_parsePrice(_selectedService!['preco']!).toStringAsFixed(2)} → €${_finalPrice.toStringAsFixed(2)} (Desconto aplicado)',
                                style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                              )
                            else
                              Text('Preço: €${_finalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFFB22222)),
                        title: const Text('Profissional', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_selectedProfessional!.name, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFFB22222)),
                        title: const Text('Data', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          '${_selectedDate?.toLocal().toString().split(' ')[0]} - ${_getWeekdayName(_selectedDate!.weekday)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFFB22222)),
                        title: const Text('Hora', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(formattedTime, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFFB22222)),
                        title: const Text('Barbearia', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_selectedBarbearia!.name, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: Color(0xFFB22222)),
                        title: const Text('Nome', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_nameController.text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.phone, color: Color(0xFFB22222)),
                        title: const Text('Telefone', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_phoneController.text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Color(0xFFB22222)),
                        title: const Text('Email', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_emailController.text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Voltar', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _isCompletingBooking
                      ? null
                      : () async {
                          if (!mounted) return;
                          setStateDialog(() {}); // rebuild imediata

                          setStateDialog(() {
                            _isCompletingBooking = true;
                          });

                          try {
                            await _completeBooking();
                          } finally {
                            if (mounted) {
                              setStateDialog(() {
                                _isCompletingBooking = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                  ),
                  child: _isCompletingBooking
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Processando...'),
                          ],
                        )
                      : const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Termos de Uso e Política de Privacidade', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Aceitação dos Termos\n\n'
                  'Ao acessar e usar este aplicativo, você concorda em cumprir estes termos de uso. Se você não concordar com estes termos, por favor, não use o aplicativo.\n\n'
                  '2. Uso do Serviço\n\n'
                  'O aplicativo Falcão Barbershop permite agendar serviços de barbearia. Você concorda em usar o serviço apenas para fins legais e de acordo com estes termos.\n\n'
                  '3. Privacidade\n\n'
                  'Sua privacidade é importante para nós. Coletamos informações pessoais apenas para processar agendamentos. Não compartilhamos suas informações com terceiros sem seu consentimento.\n\n'
                  '4. Responsabilidades\n\n'
                  'Você é responsável por fornecer informações precisas ao agendar serviços. O Falcão Barbershop não se responsabiliza por erros decorrentes de informações incorretas.\n\n'
                  '5. Modificações\n\n'
                  'Reservamo-nos o direito de modificar estes termos a qualquer momento. As alterações entrarão em vigor imediatamente após a publicação no aplicativo.\n\n'
                  '6. Contato\n\n'
                  'Para dúvidas sobre estes termos, entre em contato conosco através do aplicativo.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamento'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10 : 20),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (index) {
                    if (index % 2 == 0) {
                      int stepIndex = index ~/ 2;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stepIndex <= _currentStep ? const Color(0xFFB22222) : Colors.grey,
                          boxShadow: stepIndex <= _currentStep
                              ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            [Icons.location_on, Icons.person, Icons.content_cut, Icons.calendar_today, Icons.assignment][stepIndex],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    } else {
                      int lineIndex = (index - 1) ~/ 2;
                      return Container(
                        width: 30,
                        height: 2,
                        color: lineIndex < _currentStep ? const Color(0xFFB22222) : Colors.grey,
                      );
                    }
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Barbearia', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(width: 10),
                  Text('Profissional', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(width: 10),
                  Text('Serviço', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(width: 10),
                  Text('Data e Hora', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(width: 10),
                  Text('Dados', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildStepContent(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton(
                      onPressed: _previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text('Voltar'),
                    ),
                  const Spacer(),
                  if (_isStepValid())
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: Text(_currentStep == 4 ? 'Confirmar Agendamento' : 'Próximo'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBarbeariaStep();
      case 1:
        return _buildProfessionalStep();
      case 2:
        return _buildServiceStep();
      case 3:
        return _buildDateTimeStep();
      case 4:
        return _buildPersonalDataStep();
      default:
        return Container();
    }
  }

  Widget _buildBarbeariaStep() {
    return Column(
      children: [
        const Text(
          'Selecionar Barbearia',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Escolha a barbearia desejada',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        if (_isLoadingBarbearias)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            ),
          )
        else if (_barbearias.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhuma barbearia disponível no momento.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._barbearias.map((barbearia) {
            final bool isSelected = _selectedBarbearia == barbearia;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                if (!mounted) return;
                if (_selectedBarbearia == barbearia) {
                  setState(() {
                    _selectedBarbearia = null;
                    _selectedProfessional = null;
                  });
                  return;
                }

                setState(() {
                  _selectedBarbearia = barbearia;
                  _selectedProfessional = null;
                });
                await _loadProfissionais();
              },
              child: Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                shadowColor: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 250,
                                child: Image.asset(
                                  'assets/images/barbearia1.jpeg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(Icons.storefront, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFFB22222), size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        barbearia.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  barbearia.address,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFB22222) : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            isSelected ? 'Selecionada' : 'Selecionar',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProfessionalStep() {
    return Column(
      children: [
        const Text(
          'Selecionar Profissional',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Escolha o barbeiro para o seu serviço',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        if (_isLoadingProfissionais)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            ),
          )
        else if (_profissionais.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum profissional disponível no momento.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._profissionais.map((professional) {
            final bool isSelected = _selectedProfessional == professional;
            return ProfessionalCard(
              professional: professional,
              isSelected: isSelected,
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _selectedProfessional = professional;
                  _selectedDate = _getFirstAvailableDate();
                  _selectedTime = null;
                  _calendarKey++;
                });
                _loadBookedDates();
                _loadBookedTimes();
                _loadServices();
              },
            );
          }),
      ],
    );
  }

  Widget _buildServiceStep() {
    final displayedServices = _showAllServices ? _services : _services.take(6).toList();

    return Column(
      children: [
        const Text(
          'Selecionar Serviço',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Escolha o serviço desejado',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final int columns = w >= 1500
                ? 8
                : (w >= 1250
                    ? 7
                    : (w >= 1050 ? 6 : (w >= 700 ? 4 : 2)));

            final bool isWebLike = w >= 900;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isWebLike ? 0.70 : 0.48,
              ),
              itemCount: displayedServices.length,
              itemBuilder: (context, index) {
                final service = displayedServices[index];
                final bool isSelected = _selectedService == service;

                final String nome = (service['nome'] ?? 'Serviço').toString();
                final String descricao = (service['descricao'] ?? service['description'] ?? '').toString();
                final String preco = (service['preco'] ?? 'N/A').toString();
                final String duracao = (service['duracao'] ?? 'N/A').toString();

                final ValueNotifier<bool> hovering = ValueNotifier<bool>(false);

                return MouseRegion(
                  onEnter: (_) => hovering.value = true,
                  onExit: (_) => hovering.value = false,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: hovering,
                    builder: (context, isHovering, _) {
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: (isHovering ? 1.02 : 1.0) * (isSelected ? 1.01 : 1.0),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFB22222)
                                  : (isHovering ? const Color(0xFFB22222).withOpacity(0.6) : Colors.transparent),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (isHovering || isSelected)
                                BoxShadow(
                                  color: Colors.red.withOpacity(isSelected ? 0.22 : 0.16),
                                  blurRadius: isSelected ? 18 : 12,
                                  spreadRadius: isSelected ? 2 : 1,
                                ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                _selectedService = isSelected ? null : service;
                              });
                            },
                            child: Card(
                              elevation: (isSelected ? 6 : 4) + (isHovering ? 2 : 0),
                              color: const Color(0xFF1A1A1A),
                              shadowColor: Colors.red.withOpacity(isSelected ? 0.22 : 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.content_cut,
                                          color: isSelected ? const Color(0xFFB22222) : Colors.white70,
                                          size: 28,
                                        ),
                                        const Spacer(),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFB22222),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Selecionado',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      nome,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isWebLike ? 15 : 16,
                                      ),
                                    ),
                                    if (descricao.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        descricao,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    const Divider(color: Colors.grey, thickness: 1),
                                    Text(
                                      "€ $preco",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isWebLike ? 22 : 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFFB22222),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$duracao min',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFB22222) : Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isSelected ? 'Selecionado' : 'Selecionar',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWebLike ? 13 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        if (_services.length > 5) ...[
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAllServices = !_showAllServices;
                });
              },
              icon: Icon(_showAllServices ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAllServices ? 'Ver Menos' : 'Ver Mais'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      children: [
        const Text(
          'Selecionar Data e Hora',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Escolha uma data e horário disponível',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: TableCalendar(
            key: ValueKey(_calendarKey),
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _selectedDate ?? DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            enabledDayPredicate: _isDayAvailable,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              if (_selectedProfessional != null) {
                _loadBookedTimes();
              }
            },
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {CalendarFormat.week: 'Semana'},
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(color: Color(0xFFB22222), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              disabledTextStyle: TextStyle(color: Colors.grey),
            ),
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white),
              weekendStyle: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedDate != null) ...[
          Text(
            'Data selecionada: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)} - ${_getWeekdayName(_selectedDate!.weekday)}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedTime = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Limpar Data'),
          ),
        ],
        const SizedBox(height: 20),
        if (_selectedDate != null) ...[
          const Text('Horários Disponíveis:', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width > 600 ? 70 : 100,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 2.0,
            ),
            itemCount: _getAvailableTimes().length,
            itemBuilder: (context, index) {
              final time = _getAvailableTimes()[index];
              final ValueNotifier<bool> hovering = ValueNotifier<bool>(false);
              final bool isSelected = _selectedTime == time;

              return MouseRegion(
                onEnter: (_) => hovering.value = true,
                onExit: (_) => hovering.value = false,
                child: ValueListenableBuilder<bool>(
                  valueListenable: hovering,
                  builder: (context, isHovering, _) {
                    final Color baseBg = isSelected ? const Color(0xFFB22222) : Colors.grey;
                    final Color hoverBg = isSelected ? const Color(0xFFB22222).withOpacity(0.85) : const Color(0xFFB22222).withOpacity(0.65);

                    return AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: (isHovering ? 1.06 : 1.0),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: (isHovering || isSelected)
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(isSelected ? 0.30 : 0.22),
                                    blurRadius: isSelected ? 16 : 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() => _selectedTime = time);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isHovering ? hoverBg : baseBg,
                            foregroundColor: (isHovering || isSelected) ? Colors.white : null,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: (isSelected || isHovering) ? FontWeight.bold : null,
                              fontSize: MediaQuery.of(context).size.width > 600 ? 11 : 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalDataStep() {
    return Column(
      children: [
        const Text(
          'Inserir Dados Pessoais',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Preencha suas informações para finalizar o agendamento',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome completo',
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
            errorText: _nameError,
            errorStyle: const TextStyle(color: Colors.red),
          ),
          style: const TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Telefone',
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
            errorText: _phoneError,
            errorStyle: const TextStyle(color: Colors.red),
          ),
          style: const TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
            errorText: _emailError,
            errorStyle: const TextStyle(color: Colors.red),
          ),
          style: const TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 10),

        if (_currentUser != null && _userData != null && _userData!.points >= 100.0) ...[
          CheckboxListTile(
            title: Text(
              'Usar pontos para desconto (${(_availableDiscountBlocks * 10).toStringAsFixed(0)}%)',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Você tem ${_userData!.points.toStringAsFixed(0)} pontos (${_availableDiscountBlocks} blocos de desconto disponíveis).',
              style: const TextStyle(color: Colors.white70),
            ),
            value: _usePoints,
            onChanged: (value) => setState(() => _usePoints = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFB22222),
          ),
          if (_usePoints) ...[
            const SizedBox(height: 10),
            Text(
              'Desconto de ${(_availableDiscountBlocks * 10).toStringAsFixed(0)}% aplicado ao agendamento.',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ],
        ],

        if (_currentUser == null) ...[
          CheckboxListTile(
            title: const Text('Quero criar uma conta', style: TextStyle(color: Colors.white)),
            value: _createAccount,
            onChanged: (value) => setState(() => _createAccount = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFB22222),
          ),

          if (_createAccount) ...[
            const SizedBox(height: 10),
            const Text(
              'Crie uma conta para guardar seus agendamentos, receber lembretes e promoções exclusivas.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                errorText: _passwordError,
                errorStyle: const TextStyle(color: Colors.red),
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirmar senha',
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
                errorText: _confirmPasswordError,
                errorStyle: const TextStyle(color: Colors.red),
                suffixIcon: IconButton(
                  icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                  onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],

          const SizedBox(height: 10),

          RichText(
            text: TextSpan(
              text: 'Aceito os ',
              style: const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: 'termos de uso',
                  style: const TextStyle(
                    color: Color(0xFFB22222),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                ),
                const TextSpan(text: ' e '),
                TextSpan(
                  text: 'política de privacidade',
                  style: const TextStyle(
                    color: Color(0xFFB22222),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                ),
              ],
            ),
          ),

          CheckboxListTile(
            title: const Text('Aceito os termos', style: TextStyle(color: Colors.white)),
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ] else ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB22222), width: 1),
            ),
            child: const Text(
              'Como usuário logado, você já aceitou os termos de uso. Clique em "Confirmar Agendamento" para finalizar.',
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

