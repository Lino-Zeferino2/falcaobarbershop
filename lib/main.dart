// ignore_for_file: use_build_context_synchronously

import 'package:falcaobarbershopv2/user/pages/anonymous_appointments_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'user/pages/home_user.dart';
import 'admin/pages/home_admin.dart';
import 'professional/pages/home_professional_page.dart';
import 'user/controller/auth_controller.dart';
import 'user/model/user_model.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      debugShowMaterialGrid: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showPerformanceOverlay: false,
      title: 'Falcão',
      theme: ThemeData(
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFF0000),
          onPrimary: Colors.white,
          secondary: Color(0xFFFF0000),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
          background: Colors.black,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0000),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // onGenerateRoute lê o path real do browser (ex: "/history") e decide
      // já de imediato qual página construir — sem passar por HomeUser
      // primeiro nem depender de delays artificiais.
      onGenerateRoute: (settings) {
        if (settings.name == '/history') {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const AnonymousAppointmentsPage(),
          );
        }
        // Qualquer outro path (incluindo "/") cai no fluxo normal baseado em role.
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const AuthWrapper(),
        );
      },
      initialRoute: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthController _authController = AuthController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authController.userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const HomeUser();
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          if (user.role == 'admin') return const HomeAdmin();
          if (user.role == 'barbeiro') return const HomeProfessionalPage();
          return const HomeUser();
        }

        return const HomeUser();
      },
    );
  }
}