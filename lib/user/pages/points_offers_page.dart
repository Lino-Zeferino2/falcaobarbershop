import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/user_model.dart';
import '../../firestore_instance.dart';
import 'booking_page.dart';
import 'home_user.dart';

class PointsOffersPage extends StatefulWidget {
  const PointsOffersPage({super.key});

  @override
  State<PointsOffersPage> createState() => _PointsOffersPageState();
}

class _PointsOffersPageState extends State<PointsOffersPage> {
  UserModel? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pointsHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPointsHistory();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await firestore.collection('clientes').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          });
        } else {
          DocumentSnapshot oldUserDoc = await firestore.collection('users').doc(user.uid).get();
          if (oldUserDoc.exists) {
            setState(() {
              _userData = UserModel.fromMap(oldUserDoc.data() as Map<String, dynamic>);
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadPointsHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await firestore
            .collection('clientes')
            .doc(user.uid)
            .collection('pointsHistory')
            .orderBy('date', descending: true)
            .get();
        setState(() {
          _pointsHistory = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
        });
      } catch (e) {
        debugPrint('Error loading points history: $e');
      }
    }
  }

  Future<void> _useOffer(String offerType, int pointsRequired) async {
    if (_userData == null || _userData!.points < pointsRequired) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update user points
      await firestore.collection('clientes').doc(user.uid).update({
        'points': FieldValue.increment(-pointsRequired),
      });

      // Add to history
      await firestore
          .collection('clientes')
          .doc(user.uid)
          .collection('pointsHistory')
          .add({
            'type': 'spent',
            'description': 'Usou oferta: $offerType',
            'points': -pointsRequired,
            'date': Timestamp.now(),
          });

      // Reload data
      await _loadUserData();
      await _loadPointsHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oferta utilizada com sucesso!')),
      );
    } catch (e) {
      debugPrint('Error using offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao utilizar oferta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pontos e Ofertas'),
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFB22222))),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pontos e Ofertas'),
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Você precisa estar logado para acessar esta página.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos e Ofertas'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Olá, ${_userData!.name}! 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tens ${_userData!.points.toStringAsFixed(0)} pontos disponíveis!',
                        style: const TextStyle(color: Color(0xFFB22222), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Agenda e ganha pontos! Troca por descontos e ofertas exclusivas.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Como Funciona
              const Text(
                'Como Funciona',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Color(0xFFB22222)),
                        title: Text('Cada agendamento confirmado = +10 pontos', style: TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        leading: Icon(Icons.cancel, color: Color(0xFFB22222)),
                        title: Text('Cancelamentos até 45min não retiram pontos', style: TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        leading: Icon(Icons.euro, color: Color(0xFFB22222)),
                        title: Text('Cada 100 pontos = 10% de desconto no próximo corte', style: TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        leading: Icon(Icons.star, color: Color(0xFFB22222)),
                        title: Text('Ofertas especiais disponíveis quando atinges certos níveis', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tuas Ofertas Ativas
              const Text(
                'Tuas Ofertas Ativas',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_userData!.points >= 100)
                Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.content_cut, color: Color(0xFFB22222), size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Corte Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Desconto de 10%', style: TextStyle(color: Colors.white70)),
                              Text('100 pts', style: TextStyle(color: Color(0xFFB22222), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _useOffer('Corte Premium - 10% desconto', 100);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeUser(scrollToServices: true)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB22222),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Usar Agora'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_userData!.points >= 250)
                Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.face_retouching_natural, color: Color(0xFFB22222), size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Barba Deluxe', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Grátis com corte', style: TextStyle(color: Colors.white70)),
                              Text('250 pts', style: TextStyle(color: Color(0xFFB22222), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _useOffer('Barba Deluxe grátis', 250);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeUser(scrollToServices: true)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB22222),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reservar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_userData!.points < 100)
                Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Ganhe mais pontos para desbloquear ofertas!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Histórico de Pontos
              const Text(
                'Histórico de Pontos',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _pointsHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum histórico disponível',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pointsHistory.length,
                          itemBuilder: (context, index) {
                            final entry = _pointsHistory[index];
                            final date = (entry['date'] as Timestamp).toDate();
                            final points = entry['points'] as int;
                            final description = entry['description'] as String;
                            return ListTile(
                              leading: Icon(
                                points > 0 ? Icons.add_circle : Icons.remove_circle,
                                color: points > 0 ? Colors.green : Colors.red,
                              ),
                              title: Text(description, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(color: Colors.white70)),
                              trailing: Text(
                                '${points > 0 ? '+' : ''}$points pts',
                                style: TextStyle(
                                  color: points > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão Final
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  BookingPage() )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Agendar Agora e Ganhar Pontos', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
