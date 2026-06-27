import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/testimonial_model.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';
import '../../firestore_instance.dart';

class TestimonialsPage extends StatefulWidget {
  const TestimonialsPage({super.key});

  @override
  State<TestimonialsPage> createState() => _TestimonialsPageState();
}

class _TestimonialsPageState extends State<TestimonialsPage> {
  final AuthController _authController = AuthController();
  User? _currentUser;
  UserModel? _userModel;
  final TextEditingController _testimonialController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

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
          if (mounted) setState(() {});
        } catch (e) {
          print('Error getting current user: $e');
          _userModel = null;
          if (mounted) setState(() {});
        }
      } else {
        _userModel = null;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _submitTestimonial() async {
    if (_testimonialController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escreva um depoimento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final testimonial = TestimonialModel(
        id: firestore.collection('testimonials').doc().id,
        userId: _currentUser?.uid ?? 'anonymous',
        userName: _isAnonymous ? null : _userModel?.name,
        description: _testimonialController.text.trim(),
        imageUrl: null,
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
      );

      await firestore
          .collection('testimonials')
          .doc(testimonial.id)
          .set(testimonial.toMap());

      _testimonialController.clear();
      setState(() {
        _isAnonymous = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depoimento enviado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar depoimento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Depoimentos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          // Add Testimonial Section
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1A1A1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compartilhe sua experiência',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _testimonialController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escreva seu depoimento aqui...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentUser != null)
                  Row(
                    children: [
                      Checkbox(
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFB22222),
                      ),
                      const Text(
                        'Enviar anonimamente',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitTestimonial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enviar Depoimento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Testimonials List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('testimonials')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar depoimentos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum depoimento ainda. Seja o primeiro!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final testimonials = snapshot.data!.docs
                    .map((doc) => TestimonialModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: testimonials.length,
                  itemBuilder: (context, index) {
                    final testimonial = testimonials[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFB22222),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        testimonial.isAnonymous || testimonial.userName == null
                                            ? 'Anônimo'
                                            : testimonial.userName!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${testimonial.createdAt.day}/${testimonial.createdAt.month}/${testimonial.createdAt.year}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              testimonial.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
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

  @override
  void dispose() {
    _testimonialController.dispose();
    super.dispose();
  }
}
