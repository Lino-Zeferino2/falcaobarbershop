import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firestore_instance.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';
import '../../admin/controller/admin_controller.dart';
import '../../admin/model/vip_plan_model.dart';
import '../../admin/model/vip_subscription_model.dart';
import '../../admin/model/settings_model.dart';
import '../../admin/model/barbearia_model.dart';
import '../../admin/model/service_model.dart';
import '../../admin/model/profissional_model.dart';
import 'booking_page.dart';
import 'login_page.dart';
import 'history_page.dart';
import 'points_offers_page.dart';
import 'vip_subscription_page.dart';
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
return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/logo_falcao.png', height: 40),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                MediaQuery.of(context).size.width < 400 ? 'Barbershop' : _settings?.barbeariaNome ?? 'Falcão Barbershop',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
leading: null,
        actions: [
          if (MediaQuery.of(context).size.width > 600) ...[
           // TextButton(onPressed: () => _scrollToSection(_heroKey), child: const Text('Início', style: TextStyle(color: Colors.white))),
           // TextButton(onPressed: () => _scrollToSection(_servicesKey), child: const Text('Serviços', style: TextStyle(color: Colors.white))),
           // TextButton(onPressed: () => _scrollToSection(_vipKey), child: const Text('VIP', style: TextStyle(color: Colors.white))),
          //  TextButton(onPressed: () => _scrollToSection(_barbersKey), child: const Text('Barbeiros', style: TextStyle(color: Colors.white))),
            //TextButton(onPressed: () => _scrollToSection(_contactKey), child: const Text('Contato', style: TextStyle(color: Colors.white))),
            if (_currentUser == null) ...[
               TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnonymousAppointmentsPage())),
                child: const Text('Meus Agendamentos', style: TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color.fromARGB(255, 172, 15, 15),
                      shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                  ),
                  child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
                TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnonymousAppointmentsPage())),
                child: const Text('Meus Agendamentos', style: TextStyle(color: Colors.white)),
              ),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())), child: const Text('Histórico', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointsOffersPage())), child: const Text('Pontos e Ofertas', style: TextStyle(color: Colors.white))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                  ),
                  child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingPage(),
                              ),
                            ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                ),
                child: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
endDrawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              backgroundColor: const Color(0xFF0D0D0D),
              child: ListView(
                children: [
                  //ListTile(title: const Text('Início', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold )), onTap: () => _scrollToSection(_heroKey)),
                 // ListTile(title: const Text('Serviços', style: TextStyle(color: Colors.white)), onTap: () => _scrollToSection(_servicesKey)),
                 // ListTile(title: const Text('VIP', style: TextStyle(color: Colors.white)), onTap: () => _scrollToSection(_vipKey)),
                 // ListTile(title: const Text('Barbeiros', style: TextStyle(color: Colors.white)), onTap: () => _scrollToSection(_barbersKey)),
                 // ListTile(title: const Text('Agendar', style: TextStyle(color: Colors.white)), onTap: () => _scrollToSection(_servicesKey)),
                //  ListTile(title: const Text('Contato', style: TextStyle(color: Colors.white)), onTap: () => _scrollToSection(_contactKey)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                        title: const Text('Meus Agendamentos', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnonymousAppointmentsPage())),
                      ),
                  ),
                  if (_currentUser == null) ...[
                     Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                        style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                                           foregroundColor: const Color.fromARGB(255, 172, 15, 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                           shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                        ),
                        child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                                           ),
                     ),
                  ] else ...[
                    ListTile(title: const Text('Histórico', style: TextStyle(color: Colors.white)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()))),
                    ListTile(title: const Text('Pontos e Ofertas', style: TextStyle(color: Colors.white)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointsOffersPage()))),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                           shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                        ),
                        child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookingPage(),
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                      ),
                      child: const Text('Agendar Agora', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          : null,
          
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Hero Section
            
Container(
  key: _heroKey,
  height: MediaQuery.of(context).size.height * 0.85,
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/hero.png'),
      fit: BoxFit.cover,
    ),
  ),
  child: Stack(
    children: [
      // Gradient overlay elegante
      Container(
        decoration: BoxDecoration(
           gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.9),
        Colors.black.withOpacity(0.85),
      ],
    ),
        ),
      ),

      // Conteúdo
      LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: isDesktop
                    ? Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lado esquerdo (texto e CTAs maiores e mais alinhados)
                          Expanded(
                            flex: 4,
                            child: Transform.translate(
                              offset: const Offset(-100, 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                if (_userModel != null) ...[
                                  Text(
                                    'Olá, ${_userModel!.name}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  _settings?.descricaoCurta ?? 'Excelência em cada corte',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _settings?.subDescricao ??
                                      'Estilo, precisão e profissionalismo num só lugar.',
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 900 ? 12 : 11,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 9,
                                      color: _isBarbershopOpen
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isBarbershopOpen
                                          ? 'Aberto agora'
                                          : 'Fechado no momento',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isBarbershopOpen
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: SizedBox(
                                        height: 40,
                                        
                                        child: SizedBox(
                                          width: 220,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const BookingPage(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFB22222),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              elevation: 8,
                                            ),
                                            child: const Text(
                                              'Agendar Agora',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 40,
                                  width: 260,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const PortfolioWorksPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.red, width: 2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 8,
                                    ),
                                    child: const Text(
                                      'Nossos Trabalhos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                          const SizedBox(width: 20),

                          // Lado direito (imagem com borda vermelha grande)
                          Expanded(
                            flex: 10,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * 0.45,
                                height: constraints.maxWidth * 0.45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 225, 50, 50),
                                    width: 12,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: constraints.maxWidth * 0.40,
                                  height: constraints.maxWidth * 0.40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 204, 40, 40),
                                      width: 12,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: constraints.maxWidth * 0.30,
                                    height: constraints.maxWidth * 0.30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFB22222),
                                        width: 12,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/falcao.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Imagem em formato circular também na visão mobile
                        Center(
                          child: Container(
                             width: 270,
                            height: 270,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.fromARGB(255, 225, 50, 50),
                                  width: 20,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                            child: Container(
                               width: 260,
                              height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 200, 59, 59),
                                    width: 12,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:   const Color(0xFFB22222),
                                    width: 12,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(0),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/falcao.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                        if (_userModel != null) ...[
                          Text(
                            'Olá, ${_userModel!.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          _settings?.descricaoCurta ?? 'Excelência em cada corte',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _settings?.subDescricao ??
                              'Estilo, precisão e profissionalismo num só lugar.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: _isBarbershopOpen
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isBarbershopOpen
                                  ? 'Aberto agora'
                                  : 'Fechado no momento',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isBarbershopOpen
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          width: 180,
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const BookingPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB22222),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Agendar Agora',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PortfolioWorksPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              side: const BorderSide(color: Colors.red, width: 2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Nossos Trabalhos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                                              ),
              ),
            ),
          );
        },
      ),


      // FloatingActionButton dentro do hero (canto direito, mais para cima)
      Positioned(
        right: 16,
        bottom: 10,
        child: FloatingActionButton(
          backgroundColor:  Color.fromARGB(255, 34, 113, 54),
          elevation: 6,
          tooltip: 'WhatsApp',
          onPressed: () {
            final message = Uri.encodeComponent(
              'Olá! Tenho interesse em agendar um corte. Pode me ajudar com horários?',
            );
            _openUrl('https://wa.me/351925203598?text=$message');
          },
          child:  Icon(
            Icons.message_sharp,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
),

/*
 // Escolher Barbearia
            Container(
              key: _servicesKey,
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Escolhe a barbearia onde deseja agendar',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Barbearias from Database
                  StreamBuilder<List<BarbeariaModel>>(
                    stream: _barbeariasStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar barbearias: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhuma barbearia disponível', style: const TextStyle(color: Colors.white)));
                      }
                      final activeBarbearias = snapshot.data!.where((b) => b.isActive).toList();
                      if (activeBarbearias.isEmpty) {
                        return const Center(child: Text('Nenhuma barbearia ativa', style: const TextStyle(color: Colors.white)));
                      }

                      return MediaQuery.of(context).size.width > 600
                          ? GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.0,
                              children: activeBarbearias.asMap().entries.map((entry) {
                                int index = entry.key;
                                BarbeariaModel barbearia = entry.value;
                                String imagePath;
                                if (index == 0) {
                                  imagePath = 'assets/images/barbearia1.jpeg';
                                } else if (index == 1) {
                                  imagePath = 'assets/images/barbearia2.JPEG';
                                } else {
                                  imagePath = ''; // No image for others
                                }
                                return _barbershopSelectionCard(barbearia, imagePath);
                              }).toList(),
                            )
                          : Column(
                              children: activeBarbearias.asMap().entries.map((entry) {
                                int index = entry.key;
                                BarbeariaModel barbearia = entry.value;
                                String imagePath;
                                if (index == 0) {
                                  imagePath = 'assets/images/barbearia1.jpeg';
                                } else if (index == 1) {
                                  imagePath = 'assets/images/barbearia2.JPEG';
                                } else {
                                  imagePath = ''; // No image for others
                                }
                                return _barbershopSelectionCard(barbearia, imagePath);
                              }).toList(),
                            );
                    },
                  ),
                ],
              ),
            ),
            // VIP Plans
            Container(
                key: _vipKey,
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Planos VIP',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<List<VipPlanModel>>(
                      stream: _vipPlansStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Erro ao carregar planos VIP: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Nenhum plano VIP disponível', style: TextStyle(color: Colors.white)));
                        }
                        final plans = snapshot.data!.where((plan) => plan.isActive).toList();
                        if (plans.isEmpty) {
                          return const Center(child: Text('Nenhum plano VIP ativo', style: TextStyle(color: Colors.white)));
                        }
                        return GridView.count(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: plans.map((plan) => _vipPlanCard(plan)).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Barbeiros
            Container(
              key: _barbersKey,
              color: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Nossos Barbeiros',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<ProfissionalModel>>(
                    stream: _profissionaisStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar barbeiros: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhum barbeiro disponível', style: const TextStyle(color: Colors.white)));
                      }
                      final profissionais = snapshot.data!.where((p) => p.disponivel).toList();
                      if (profissionais.isEmpty) {
                        return const Center(child: Text('Nenhum barbeiro ativo', style: const TextStyle(color: Colors.white)));
                      }
                      return GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: profissionais.map((profissional) => _barberCardFromModel(profissional)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Galeria
            Container(
              key: _galleryKey,
              color: Colors.black,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Nosso Espaço',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<PostModel>>(
                    stream: AdminController().getAllPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar imagens: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhuma imagem disponível', style: const TextStyle(color: Colors.white)));
                      }
                      final allPosts = snapshot.data!;
                      final displayedPosts = _showAllImages ? allPosts : allPosts.take(6).toList();

                      return Column(
                        children: [
                          GridView.count(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: displayedPosts.map((post) => Container(
                              margin: const EdgeInsets.all(5),
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white70,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )).toList(),
                          ),
                          if (allPosts.length > 6 && !_showAllImages)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextButton(
                                onPressed: () => setState(() => _showAllImages = true),
                                child: const Text(
                                  'Ver mais imagens',
                                  style: TextStyle(color: Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (_showAllImages)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextButton(
                                onPressed: () => setState(() => _showAllImages = false),
                                child: const Text(
                                  'Ver menos',
                                  style: TextStyle(color: Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Estatísticas e Serviços em Destaque
            Container(
              color: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Porquê nos Escolher ?',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  MediaQuery.of(context).size.width > 600
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statCard(Icons.people, '+${(_totalUsers + 2000).toString()}', 'Clientes Satisfeitos'),
                            _statCard(Icons.cut, '+${(_totalAppointments + 5000).toString()}', 'Cortes Realizados'),
                            _statCard(Icons.star, '4.9', 'Avaliação'),
                            _statCard(Icons.work, '8', 'Anos de Experiência'),
                          ],
                        )
                      : Column(
                          children: [
                            _statCard(Icons.people, '+${(_totalUsers + 2000).toString()}', 'Clientes Satisfeitos'),
                            const SizedBox(height: 20),
                            _statCard(Icons.cut, '+${(_totalAppointments + 5000).toString()}', 'Cortes Realizados'),
                            const SizedBox(height: 20),
                            _statCard(Icons.star, '4.9', 'Avaliação'),
                            const SizedBox(height: 20),
                            _statCard(Icons.work, '8', 'Anos de Experiência'),
                          ],
                        ),

                ],
              ),
            ),
            // Contato
            Container(
              key: _contactKey,
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Contato',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 36 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Global contact info
                  const ListTile(leading: Icon(Icons.phone, color: Colors.white), title: Text('WhatsApp', style: TextStyle(color: Colors.white)), onTap: null),
                  ListTile(leading: const Icon(Icons.camera_alt, color: Colors.white), title: const Text('Instagram', style: TextStyle(color: Colors.white)), onTap: () async {
                    final url =_settings?.instagram ?? 'https://www.instagram.com/falcao___barber?igsh=MWdydHQzZ292dThldw==';
                    try {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } catch (e) {
                      // Handle error if needed
                    }
                  }),
                  const SizedBox(height: 20),
                  // Barbershops
                  Text(
                    'Nossas Barbearias',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<BarbeariaModel>>(
                    stream: _barbeariasStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar barbearias: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhuma barbearia disponível', style: const TextStyle(color: Colors.white)));
                      }
                      final activeBarbearias = snapshot.data!.where((b) => b.isActive).toList();
                      if (activeBarbearias.isEmpty) {
                        return const Center(child: Text('Nenhuma barbearia ativa', style: const TextStyle(color: Colors.white)));
                      }
                      return MediaQuery.of(context).size.width > 600
                          ? GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 0.8, // Adjust aspect ratio to allow more height
                              children: activeBarbearias.map((barbearia) => _barbershopCardFromModel(barbearia)).toList(),
                            )
                          : Column(
                              children: activeBarbearias.map((barbearia) => _barbershopCardFromModel(barbearia)).toList(),
                            );
                    },
                  ),
                ],
              ),
            ),


     */
            // Rodapé (minimalista e responsivo)
            _buildFooter(),
          ],
        ),
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
                  Text('${service.preco.toStringAsFixed(2)}€', style: const TextStyle(color: const Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Text('Preço: ${service.preco.toStringAsFixed(2)}€', style: const TextStyle(color: const Color(0xFFB22222), fontSize: 16, fontWeight: FontWeight.bold)),
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



  Widget _vipPlanCard(VipPlanModel plan) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    bool isSubscribed = _userVipSubscription != null && _userVipSubscription!.planoId == plan.id;
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (isSubscribed) {
      String status = _userVipSubscription!.status;
      if (status == 'ativo') {
        buttonText = 'Ver meu plano - Ativo';
        buttonColor = Colors.green;
      } else if (status == 'pendente') {
        buttonText = 'Ver meu plano - Pendente';
        buttonColor = Colors.blue;
      } else if (status == 'cancelado') {
        buttonText = 'Ver meu plano - Cancelado';
        buttonColor = Colors.red;
      } else {
        buttonText = 'Ver meu plano';
        buttonColor = Colors.grey;
      }
      onPressed = () {
        // Navigate to view plan or show details
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VipSubscriptionPage(plan: plan)),
        );
      };
    } else {
      buttonText = 'Assinar Plano';
      buttonColor = const Color(0xFFB22222);
      onPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VipSubscriptionPage(plan: plan)),
        );
      };
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: TextStyle(color: Colors.white, fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(plan.description, style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 16 : 14)),
              const SizedBox(height: 12),
              Text('${plan.price.toStringAsFixed(2)}€', style: TextStyle(color: const Color(0xFFB22222), fontSize: isDesktop ? 22 : 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Benefícios:', style: TextStyle(color: Colors.white, fontSize: isDesktop ? 18 : 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...plan.benefits.take(3).map((benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check, color: const Color(0xFFB22222), size: isDesktop ? 18 : 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(benefit, style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 16 : 14))),
                  ],
                ),
              )),
              if (plan.benefits.length > 3) ...[
                const SizedBox(height: 6),
                Text('+ ${plan.benefits.length - 3} mais...', style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 16 : 14)),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: isDesktop ? 14 : 12),
                ),
                child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 16 : 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barberCardFromModel(ProfissionalModel profissional) {
    return Card(
      color: const Color(0xFF0D0D0D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFB22222),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: (profissional.fotoUrl != null && profissional.fotoUrl!.trim().isNotEmpty)
                    ? Image.network(
                        profissional.fotoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profissional.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              profissional.especialidade ?? profissional.descricao ?? 'Especialista',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _scrollToSection(_servicesKey),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB22222),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: const Text('Ver Serviços'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barbershopSelectionCard(BarbeariaModel barbearia, String imagePath) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imagePath.isNotEmpty
          ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.image,
                    color: Colors.white70,
                    size: 50,
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey[800],
              child: const Icon(
                Icons.image,
                color: Colors.white70,
                size: 50,
              ),
            ),
    );

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        // desktop com menos padding pra reduzir “espaço”
        padding: EdgeInsets.all(isDesktop ? 12 : 16),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // desktop: imagem maior
                  SizedBox(
                    width: 210,
                    height: 190,
                    child: imageWidget,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          barbearia.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Para agendar deve selecionar a barbearia',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(selectedBarbearia: barbearia),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB22222),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Agendar nessa Barbearia',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // mobile manter como está (outline e altura adequada)
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: imageWidget,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    barbearia.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para agendar deve selecionar a barbearia',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingPage(selectedBarbearia: barbearia),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB22222), width: 2),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Agendar nessa Barbearia',
                      style: TextStyle(color: Color(0xFFB22222), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _barbershopCardFromModel(BarbeariaModel barbearia) {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(barbearia.address)}';

    void openMaps() async {
      try {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    Widget mapWidget = SizedBox(
      height: 58,
      width: 150, // fixa no desktop para não “roubar” espaço do lado esquerdo
      child: GestureDetector(
        onTap: openMaps,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/map.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 6,
                child: Text(
                  barbearia.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget contentWidget = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            barbearia.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Endereço: ${barbearia.address}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: openMaps,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text(
                'Obter direções',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: Builder(
            builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width > 600;

              if (isDesktop) {
                // Desktop: 2 colunas ocupando toda a largura do card
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: contentWidget),
                    const SizedBox(width: 12),
                    mapWidget,
                  ],
                );
              }

              // Mobile: 1 coluna
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mapWidget,
                  const SizedBox(height: 6),
                  contentWidget,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      width: isDesktop ? 250 : MediaQuery.of(context).size.width - 40,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFB22222)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    Widget _socialIconButton(
      BuildContext context, {
      required IconData icon,
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
            child: Icon(
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

    const googleQrData =
        'https://www.google.com/search?num=10&sa=X&sca_esv=1bab67044c4ee1f2&hl=en-PT&sxsrf=AE3TifOxbSSMlXTdI-E9zYCuSrbmu-LeRw:1763425062235&q=Falc%C3%A3o+BarberShop+%E2%80%94+Castelo+Branco+Reviews&ved=2ahUKEwiwrrCjtvqQAxXfhP0HHTw4HRkQ7t0BegQICBAI&biw=1536&bih=826&dpr=1.25';

    final qrSize = isMobile ? 90.0 : 120.0;

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
                          decoration: const BoxDecoration(color: Colors.white),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/logo_falcao.png',
                            height: isMobile ? 26 : 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '© 2025 Falcão Barbershop.\nTodos os direitos reservados.',
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
                            icon: Icons.camera_alt_rounded,
                            label: 'Instagram',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://www.instagram.com/falcao_barbershop?igsh=MWdydHQzZ292dThldw=='),
                          ),
                          _socialIconButton(
                            context,
                            icon: Icons.music_note_rounded,
                            label: 'TikTok',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://www.tiktok.com/@falcaobarbershop?_r=1&_t=ZS-97F6iWxZU4D'),
                          ),
                          _socialIconButton(
                            context,
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFFB22222),
                            onPressed: () => _openUrl('https://wa.me/351925203598'),
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
