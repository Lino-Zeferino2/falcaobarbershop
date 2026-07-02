// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';
import '../../admin/controller/admin_controller.dart';
import '../../admin/model/vip_subscription_model.dart';
import '../../admin/model/settings_model.dart';
import '../../admin/model/service_model.dart';
import 'booking_page.dart';
import 'login_page.dart';
import 'history_page.dart';
import 'points_offers_page.dart';
import 'anonymous_appointments_page.dart';
import 'portfolio_works_page.dart';


class HomeUser extends StatefulWidget {
  final bool scrollToServices;
  const HomeUser({super.key, this.scrollToServices = false});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _heroImageFloatAnimation;


  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  User? _currentUser;
  UserModel? _userModel;
  final AuthController _authController = AuthController();
  SettingsModel? _settings;

  VipSubscriptionModel? _userVipSubscription;

  bool _isAtTop = true;

  final GlobalKey _servicesKey = GlobalKey();

  Future<void> _getSettings() async {
    _settings = await AdminController().getSettings();
    if (mounted) setState(() {});
  }


  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  bool get _isBarbershopOpen {
    if (_settings == null) return false;

    final now = DateTime.now();
    final weekday = now.weekday; // 1=Monday, 7=Sunday

    final dayNames = {
      1: 'segunda',
      2: 'terça',
      3: 'quarta',
      4: 'quinta',
      5: 'sexta',
      6: 'sábado',
      7: 'domingo',
    };

    final currentDay = dayNames[weekday]!;
    if (!_settings!.diasAtendimento.contains(currentDay)) return false;

    final turnos = _settings!.turnos as Map<String, dynamic>;
    final manha = turnos['manha'] as Map<String, dynamic>;
    final tarde = turnos['tarde'] as Map<String, dynamic>;

    bool isInTime(String inicio, String fim) {
      final inicioParts = inicio.split(':');
      final fimParts = fim.split(':');
      final inicioHour = int.parse(inicioParts[0]);
      final inicioMin = int.parse(inicioParts[1]);
      final fimHour = int.parse(fimParts[0]);
      final fimMin = int.parse(fimParts[1]);

      final inicioTime = DateTime(now.year, now.month, now.day, inicioHour, inicioMin);
      final fimTime = DateTime(now.year, now.month, now.day, fimHour, fimMin);

      return now.isAfter(inicioTime) && now.isBefore(fimTime) ||
             now.isAtSameMomentAs(inicioTime) ||
             now.isAtSameMomentAs(fimTime);
    }

    if (isInTime(manha['inicio'], manha['fim'])) return true;
    if (isInTime(tarde['inicio'], tarde['fim'])) return true;

    return false;
  }





  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animação para o componente da imagem no hero (falcao.jpg)
    _heroImageFloatAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -12),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );


    // Verificar estado de autenticação

    _checkAuthState();

    // Carregar configurações
    _getSettings();

 

    // Scroll to services if requested
    if (widget.scrollToServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(_servicesKey);
      });
    }
    //Scrool com botao
    _scrollController.addListener(() {
  if (!_scrollController.hasClients) return;

  final atTop = _scrollController.offset <= 50;

  if (atTop != _isAtTop) {
    setState(() {
      _isAtTop = atTop;
    });
  }
});

  }
//Metodo para scroll

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      if (user != null) {
        try {
          _userModel = await _authController.getCurrentUser();
          if (_userModel != null) {
            _userVipSubscription = await AdminController().getUserVipSubscription(_userModel!.uid);
            if (_userVipSubscription != null) {
            }
          }
          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          print('Error getting current user: $e');
          _userModel = null;
          _userVipSubscription = null;
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        _userModel = null;
        _userVipSubscription = null;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

Future<void> _logout() async {
    try {
      await _authController.logout();
    setState(() {
      _currentUser = null;
    });
    
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair: $e')),
      );
    }
  }


 

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
Widget build(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width <= 600;

  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: const Color(0xFF0D0D0D),
    appBar: _buildAppBar(isMobile),
    endDrawer: isMobile ? _buildDrawer() : null,
    body: SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          _buildHero(isMobile),
          _buildServicesSection(),
          _buildCtaSection(isMobile),
          _buildFooter(),
        ],
      ),
    ),
  );
}

PreferredSizeWidget _buildAppBar(bool isMobile) {
  return AppBar(
    backgroundColor: const Color(0xFF0D0D0D),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: Colors.white.withOpacity(0.06)),
    ),
    title: GestureDetector(
      onTap: (){
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) =>const HomeUser()));
      },
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset('assets/images/logo_falcao.png'),
          ),
          const SizedBox(width: 10),
          Text(
            _settings?.barbeariaNome ?? 'Falcão Barbershop',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    actions: [
      if (!isMobile) ...[
        if (_currentUser == null) ...[
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousAppointmentsPage())),
            child: const Text('Agendamentos', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Text('Entrar', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ] else ...[
            TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousAppointmentsPage())),
            child: const Text('Agendamentos', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
            child: const Text('Histórico', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsOffersPage())),
            child: const Text('Pontos', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          TextButton(
            onPressed: _logout,
            child: const Text('Sair', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ],
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
            icon: const Icon(Icons.content_cut, size: 14),
            label: const Text('Agendar', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ] else ...[
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    ],
  );
}

Widget _buildDrawer() {
  return Drawer(
    backgroundColor: const Color(0xFF0D0D0D),
    child: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/images/logo_falcao.png'),
                ),
                const SizedBox(width: 10),
                const Text('Falcão Barbershop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 20),
            title: const Text('Agendamentos', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousAppointmentsPage())),
          ),
          if (_currentUser != null) ...[
             ListTile(
            leading: const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 20),
            title: const Text('Histórico', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
          
            ListTile(
              leading: const Icon(Icons.star_outline, color: Colors.white54, size: 20),
              title: const Text('Pontos e Ofertas', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsOffersPage())),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                    icon: const Icon(Icons.content_cut, size: 16),
                    label: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (_currentUser == null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Entrar', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ] else ...[
                  
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _logout,
                      child: const Text('Sair', style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHero(bool isMobile) {
  return Container(
    key: _heroKey,
    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.88),
    decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
    child: Stack(
      children: [
        // Glow de fundo
        Positioned(
          top: 0, left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: isMobile ? Alignment.topCenter : Alignment.centerRight,
                radius: 1.2,
                colors: [
                  const Color(0xFFB22222).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Conteúdo
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: isMobile ? 40 : 60,
            ),
            child: isMobile ? _buildHeroMobile() : _buildHeroDesktop(),
          ),
        ),

        // WhatsApp FAB
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF25D366),
            elevation: 6,
            tooltip: 'WhatsApp',
            onPressed: () {
              final msg = Uri.encodeComponent('Olá! Tenho interesse em agendar um corte.');
              _openUrl('https://wa.me/351925203598?text=$msg');
            },
            child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeroMobile() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _buildOpenBadge(),
      const SizedBox(height: 32),
      _buildPhotoCircle(240),
      const SizedBox(height: 32),
      if (_userModel != null) ...[
        Text('Olá, ${_userModel!.name.split(' ').first}',
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 8),
      ],
      Text(
        _settings?.descricaoCurta ?? 'Estilo que\nfala por si.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
      ),
      const SizedBox(height: 12),
      Text(
        _settings?.subDescricao ?? 'Precisão, estilo e profissionalismo num só lugar.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.6),
        maxLines: 3,
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
            icon: const Icon(Icons.content_cut, size: 16),
            label: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioWorksPage())),
          icon: const Icon(Icons.play_circle_outline, size: 16),
          label: const Text('Nossos Trabalhos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 36),
      _buildStats(isMobile: true),
    ],
  );
}

Widget _buildHeroDesktop() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOpenBadge(),
            const SizedBox(height: 24),
            if (_userModel != null) ...[
              Text('Olá, ${_userModel!.name.split(' ').first}',
                  style: const TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 10),
            ],
            Text(
              _settings?.descricaoCurta ?? 'Estilo que\nfala por si.',
              style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1.05),
            ),
            const SizedBox(height: 16),
            Text(
              _settings?.subDescricao ?? 'Precisão, estilo e profissionalismo num só lugar. Agenda o teu próximo corte agora.',
              style: const TextStyle(color: Colors.white38, fontSize: 16, height: 1.6),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                    icon: const Icon(Icons.content_cut, size: 16),
                    label: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioWorksPage())),
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Nossos Trabalhos', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            _buildStats(isMobile: false),
          ],
        ),
      ),
      const SizedBox(width: 60),
      Expanded(
        flex: 4,
        child: Center(child: _buildPhotoCircle(320)),
      ),
    ],
  );
}

Widget _buildOpenBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: _isBarbershopOpen
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _isBarbershopOpen
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: _isBarbershopOpen ? Colors.greenAccent : Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isBarbershopOpen ? 'Aberto agora · Castelo Branco' : 'Fechado no momento',
          style: TextStyle(
            color: _isBarbershopOpen ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPhotoCircle(double size) {
  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, _heroImageFloatAnimation.value.dy),
        child: child,
      );
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Anéis pulsantes
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              final opacity = (0.15 - i * 0.04) * (0.5 + 0.5 * _animationController.value);
              return Container(
                width: size + 30 + i * 20,
                height: size + 30 + i * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFB22222).withOpacity(opacity),
                    width: 1.5,
                  ),
                ),
              );
            },
          );
        }),

        // Foto
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFB22222), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB22222).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/falcao.jpg', fit: BoxFit.cover),
          ),
        ),

        // Badge avaliação
        Positioned(
          top: 20, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 10)),
                SizedBox(height: 2),
                Text('4.9 · 500+ clientes', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStats({required bool isMobile}) {
  final stats = [
    ('500+', 'Clientes'),
    ('4.9', 'Avaliação'),
    ('5+', 'Anos exp.'),
    ('+10 mil ', 'Cortes'),
  ];

  return Wrap(
    spacing: isMobile ? 24 : 40,
    runSpacing: 16,
    children: stats.asMap().entries.map((entry) {
      final i = entry.key;
      final stat = entry.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (i > 0)
            Container(
              width: 1, height: 32,
              color: Colors.white.withOpacity(0.08),
              margin: EdgeInsets.only(right: isMobile ? 24 : 40),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.$1, style: const TextStyle(color: Color(0xFFB22222), fontSize: 26, fontWeight: FontWeight.w800)),
              Text(stat.$2, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      );
    }).toList(),
  );
}

Widget _buildServicesSection() {
  return FutureBuilder<SettingsModel?>(
    future: AdminController().getSettings(),
    builder: (context, snapshot) {
      final isMobile = MediaQuery.of(context).size.width <= 600;

      return Container(
        key: _servicesKey,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 60,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SERVIÇOS',
                  style: TextStyle(color: Color(0xFFB22222), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('O que oferecemos',
                      style: isMobile?  TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700): TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                    child:  Text('Ver todos →', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Preview de 3 serviços do Firestore
              StreamBuilder(
                stream: AdminController().getAllActiveServices(),
                builder: (context, snapshot) {
                  final services = List.from(snapshot.data ?? []);
services.shuffle();
final randomServices = services.take(3).toList();
                  if (services.isEmpty) return const SizedBox.shrink();

                  return GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isMobile ? 1 : 3,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
    childAspectRatio: isMobile ? 2.5 : 1.1,
  ),
  itemCount: randomServices.length,
  itemBuilder: (context, index) {
    final s = randomServices[index];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BookingPage(selectedService: {
            'nome': s.nome, 'preco': s.preco, 'duracao': s.duracao,
          }))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: isMobile
            ? Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB22222).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_cut, color: Color(0xFFB22222), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('${s.duracao} min', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('€${s.preco.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFFB22222), fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB22222).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_cut, color: Color(0xFFB22222), size: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('${s.duracao} min', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const Spacer(),
                  Text('€${s.preco.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFFB22222), fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  },
);},
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildCtaSection(bool isMobile) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 20),
    padding: EdgeInsets.all(isMobile ? 28 : 40),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFB22222).withOpacity(0.15), const Color(0xFF0D0D0D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFB22222).withOpacity(0.2)),
    ),
    child: Column(
      children: [
        const Text('Pronto para o próximo corte?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text('Agenda agora ou fala connosco directamente pelo WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12, runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
              icon: const Icon(Icons.content_cut, size: 16),
              label: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final msg = Uri.encodeComponent('Olá! Tenho interesse em agendar um corte.');
                _openUrl('https://wa.me/351925203598?text=$msg');
              },
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
              label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'face':
        return Icons.face;
      case 'cut':
        return Icons.cut;
      case 'star':
        return Icons.star;
      case 'home':
        return Icons.home;
      case 'brush':
        return Icons.brush;
      case 'color_lens':
        return Icons.color_lens;
      case 'palette':
        return Icons.palette;
      case 'content_cut':
        return Icons.content_cut;
      case 'remove_red_eye':
        return Icons.remove_red_eye;
      case 'straighten':
        return Icons.straighten;
      case 'face_retouching_natural':
        return Icons.face_retouching_natural;
      case 'edit':
        return Icons.edit;
      default:
        return Icons.content_cut;
    }
  }

  Widget _serviceItemFromModel(ServiceModel service) {
    final icon = _getIconFromName(service.iconName);
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFB22222)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.nome, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${service.duracao} min', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('${service.preco.toStringAsFixed(2)}€', style: const TextStyle(color:  Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Map<String, dynamic> selectedService = {
                      'name': service.nome,
                      'duration': '${service.duracao} min',
                      'price': '${service.preco.toStringAsFixed(2)}€',
                    };
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(selectedService: selectedService)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Agendar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF2A2A2A),
                          title: Row(
                            children: [
                              Icon(icon, size: 30, color: const Color(0xFFB22222)),
                              const SizedBox(width: 10),
                              Text(service.nome, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Descrição: ${service.descricao}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 10),
                              Text('Duração: ${service.duracao} min', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 10),
                              Text('Preço: ${service.preco.toStringAsFixed(2)}€', style: const TextStyle(color: Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Fechar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Ver Detalhe', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _barberCard(String name, String specialty, String imagePath) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          color: const Color(0xFF0D0D0D),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() as VoidCallback),
                  onExit: (_) => setState(() as VoidCallback),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(imagePath, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white)),
                Text(specialty, style: const TextStyle(color: Colors.white70)),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingPage())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Agendar com $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }








  Widget _buildFooter() {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    Widget _socialIconButton(
      BuildContext context, {
      required FaIconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: label,
        textStyle: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.7), width: 1),
            ),
            child: FaIcon(
            icon,
              color: color,
              size: isMobile ? 20 : 22,
            ),
          ),
        ),
      );
    }

    Future<void> _openUrl(String url) async {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    void _showPrivacyPolicy() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Política de Privacidade',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: const Text(
                'Política de Privacidade\n\n'
                'A Falcão Barbershop valoriza a sua privacidade e está comprometida em proteger as suas informações pessoais. Esta política descreve como coletamos, usamos e protegemos os dados fornecidos pelos usuários.\n\n'
                '1. Coleta de Dados: Coletamos informações como nome, e-mail, telefone e dados de agendamento para fornecer nossos serviços.\n\n'
                '2. Uso dos Dados: Os dados são utilizados para agendar serviços, enviar notificações e melhorar a experiência do usuário.\n\n'
                '3. Compartilhamento: Não compartilhamos dados pessoais com terceiros sem consentimento, exceto quando exigido por lei.\n\n'
                '4. Segurança: Implementamos medidas de segurança para proteger os dados contra acesso não autorizado.\n\n'
                '5. Cookies: Utilizamos cookies para melhorar a navegação no site.\n\n'
                'Para mais informações, entre em contato conosco.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    void _showTerms() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Termos de Uso',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: const Text(
                'Termos de Uso\n\n'
                'Bem-vindo à Falcão Barbershop. Ao utilizar nossos serviços, você concorda com estes termos.\n\n'
                '1. Aceitação: Ao acessar o aplicativo, você aceita estes termos e condições.\n\n'
                '2. Serviços: Oferecemos agendamento de cortes de cabelo e serviços relacionados. Reservamo-nos o direito de alterar serviços sem aviso prévio.\n\n'
                '3. Responsabilidades do Usuário: Você é responsável por fornecer informações precisas e manter a confidencialidade de sua conta.\n\n'
                '4. Limitação de Responsabilidade: Não nos responsabilizamos por danos indiretos ou consequenciais decorrentes do uso do serviço.\n\n'
                '5. Modificações: Podemos atualizar estes termos a qualquer momento. O uso contínuo implica aceitação das mudanças.\n\n'
                'Para dúvidas, contate-nos.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }


    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 18 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration:  BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/logo_falcao.png',
                            height: isMobile ? 26 : 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '© 2026 Falcão Barbershop.\nTodos os direitos reservados.',
                            style: const TextStyle(color: Colors.white, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Desenvolvido por ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        
                      ],
                    ),
                    InkWell(
                          onTap: () => _openUrl('https://linozeferino-portfolio.web.app'),
                          child: const Text(
                            'Lino Zeferino',
                            style: TextStyle(
                              color: Color(0xFFB22222),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              if (!isMobile) const SizedBox(width: 16),

              Expanded(
                flex: isMobile ? 0 : 1,
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'Siga-nos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _socialIconButton(
                            context,
                            icon: FontAwesomeIcons.whatsapp,
                            label: 'WhatsApp',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://wa.me/351925203598'),
                          ),
                          _socialIconButton(
                            context,
                            icon: FontAwesomeIcons.instagram,
                            label: 'Instagram',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://www.instagram.com/falcao_barbershop?igsh=MWdydHQzZ292dThldw=='),
                          ),
                          _socialIconButton(
                            context,
                            icon: FontAwesomeIcons.tiktok,
                            label: 'TikTok',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://www.tiktok.com/@falcaobarbershop?_r=1&_t=ZS-97F6iWxZU4D'),
                          ),


                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _showPrivacyPolicy,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Política de Privacidade'),
                ),
                TextButton(
                  onPressed: _showTerms,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Termos de Uso'),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 50, color: const Color(0xFFB22222)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
