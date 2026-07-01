

// ignore_for_file: use_build_context_synchronously

import 'package:falcaobarbershopv2/user/pages/anonymous_appointments_page.dart';
import 'package:falcaobarbershopv2/user/pages/history_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';


import 'user/pages/home_user.dart';
import 'admin/pages/home_admin.dart';
import 'professional/pages/home_professional_page.dart';
import 'user/controller/auth_controller.dart';
import 'user/model/user_model.dart';

Future<void> main() async {
  
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
          primary: Color(0xFFFF0000), // Red
          onPrimary: Colors.white, // Strong white
          secondary: Color(0xFFFF0000), // Red
          onSecondary: Colors.white, // Strong white
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFF1A1A1A), // Dark gray for surfaces
          onSurface: Colors.white, // Strong white
          background: Colors.black, // Black background
          onBackground: Colors.white, // Strong white
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
      initialRoute: '/',
      routes: {
        '/history': (context) => const AuthWrapper(), // Will handle navigation in AuthWrapper
      },
      home: const AuthWrapper(),
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
    print('AuthWrapper: Building AuthWrapper widget');

    // Check if we need to navigate to history page
    final route = ModalRoute.of(context);
    final routeName = route?.settings.name;
    print('AuthWrapper: Current route: $routeName');

    return StreamBuilder<UserModel?>(
      stream: _authController.userStream,
      builder: (context, snapshot) {
        print('AuthWrapper: StreamBuilder called - connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');

        if (snapshot.hasError) {
          print('AuthWrapper error: ${snapshot.error}');
          // Em caso de erro, redirecionar para HomeUser (que tem botão de login)
          return const HomeUser();
        }

        // Mostrar loading apenas na primeira vez ou quando não há dados ainda
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          print('AuthWrapper: Showing loading...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('AuthWrapper: User found with role: ${user.role}, uid: ${user.uid}, email: ${user.email}');

          // Check for admin role
          if (user.role == 'admin') {
            print('AuthWrapper: Navigating to HomeAdmin');
            return const HomeAdmin();
          } else if (user.role == 'barbeiro') {
            print('AuthWrapper: Navigating to HomeProfessionalPage');
            return const HomeProfessionalPage();
          } else {
            print('AuthWrapper: Navigating to HomeUser (default)');
            // Check if we need to navigate to history
            if (routeName == '/history') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeUser()));
                // Navigate to history after a short delay to ensure HomeUser is loaded
                Future.delayed(const Duration(milliseconds: 100), () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                });
              });
            }
            return const HomeUser();
          }
        } else {
          print('AuthWrapper: No user data, showing HomeUser');
          // Usuário não logado - check if we need to navigate to history
          if (routeName == '/history') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeUser()));
              // Navigate to anonymous appointments after a short delay
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnonymousAppointmentsPage()));
              });
            });
          }
          return const HomeUser();
        }
      },
    );
  }

  @override
  void dispose() {
    // Removed dispose call for AuthController singleton to prevent stream closure issues
    super.dispose();
  }
}
