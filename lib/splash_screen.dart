import 'package:flutter/material.dart';
import 'user/pages/home_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    // Fade in
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Hold for 1 second, then fade out
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        _opacity = 0.0;
      });
    });

    // Navigate to home after total duration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeUser()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final logoSize = screenSize.width * 0.5; // 50% of screen width for responsiveness

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // #1A1A1A
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB22222).withOpacity(0.5), // #B22222 glow
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo_falcao.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
