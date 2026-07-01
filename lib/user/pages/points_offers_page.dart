// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/user_model.dart';
import '../../firestore_instance.dart';
import 'booking_page.dart';

class PointsOffersPage extends StatefulWidget {
  const PointsOffersPage({super.key});

  @override
  State<PointsOffersPage> createState() => _PointsOffersPageState();
}

class _PointsOffersPageState extends State<PointsOffersPage> {
  UserModel? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pointsHistory = [];
  bool _historyExpanded = false;
  // Níveis do programa
  static const int _nextLevelPoints = 1000;

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
        DocumentSnapshot doc = await firestore.collection('clientes').doc(user.uid).get();
        if (!doc.exists) {
          doc = await firestore.collection('users').doc(user.uid).get();
        }
        if (doc.exists) {
          setState(() => _userData = UserModel.fromMap(doc.data() as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadPointsHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await firestore
          .collection('clientes')
          .doc(user.uid)
          .collection('pointsHistory')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
      setState(() {
        _pointsHistory = snapshot.docs.map((d) => d.data()).toList();
      });
    } catch (e) {
      debugPrint('Error loading points history: $e');
    }
  }

  int get _agendamentosParaProximoNivel {
    if (_userData == null) return 0;
    final pts = _userData!.points;
    final restante = _nextLevelPoints - (pts % _nextLevelPoints);
    return (restante / 10).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFB22222))),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: _buildAppBar(),
        body: const Center(
          child: Text('Precisa de estar autenticado.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final pts = _userData!.points;
    final progress = (pts % _nextLevelPoints) / _nextLevelPoints;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFFB22222),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: () async {
          await _loadUserData();
          await _loadPointsHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPointsCard(pts, progress),
              const SizedBox(height: 28),
              _buildSectionLabel('OFERTAS DISPONÍVEIS'),
              const SizedBox(height: 6),
              const Text('O que podes resgatar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _buildOfferCard(
                icon: Icons.content_cut_outlined,
                title: 'Desconto 10%',
                subtitle: 'No próximo agendamento',
                pts: 100,
                userPts: pts,
              ),
              _buildOfferCard(
                icon: Icons.face_outlined,
                title: 'Barba grátis',
                subtitle: 'Com qualquer corte',
                pts: 250,
                userPts: pts,
              ),
              _buildOfferCard(
                icon: Icons.star_outline,
                title: 'Corte VIP',
                subtitle: 'Corte + Barba + Skincare',
                pts: 500,
                userPts: pts,
              ),
              const SizedBox(height: 28),
              _buildSectionLabel('PROGRAMA DE PONTOS'),
              const SizedBox(height: 6),
              const Text('Como funciona',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _buildHowItWorks(),
              const SizedBox(height: 28),
              _buildSectionLabel('ACTIVIDADE RECENTE'),
              const SizedBox(height: 6),
              const Text('Histórico',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _buildHistory(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                  icon: const Icon(Icons.content_cut, size: 16),
                  label: const Text('Agendar e ganhar pontos', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Pontos e Ofertas'),
      backgroundColor: const Color(0xFF0D0D0D),
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.white.withOpacity(0.06)),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFFB22222), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600));
  }

  Widget _buildPointsCard(double pts, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB22222), Color(0xFF7a0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB22222).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculo decorativo
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Os teus pontos',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                pts.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1),
              ),
              const Text('pontos disponíveis',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0 pts', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    '${pts.toStringAsFixed(0)} / $_nextLevelPoints pts',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text('$_nextLevelPoints pts', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$_agendamentosParaProximoNivel agendamento${_agendamentosParaProximoNivel == 1 ? '' : 's'} até ao próximo nível',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int pts,
    required double userPts,
  }) {
    final unlocked = userPts >= pts;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: unlocked ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? const Color(0xFFB22222).withOpacity(0.3) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFB22222).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFB22222), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB22222).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$pts pts',
                          style: const TextStyle(color: Color(0xFFB22222), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              unlocked
                  ? ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Usar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text('Bloqueado',
                          style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final items = [
      (Icons.calendar_today_outlined, 'Cada agendamento confirmado ganha +10 pontos'),
      (Icons.euro_outlined, '100 pontos = 10% de desconto no próximo corte'),
      (Icons.lock_open_outlined, 'Ofertas especiais desbloqueiam em níveis mais altos'),
      (Icons.info_outline, 'O desconto é aplicado no momento do agendamento'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: i < items.length - 1
                  ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB22222).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$1, color: const Color(0xFFB22222), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.$2,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

Widget _buildHistory() {
  if (_pointsHistory.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.history_outlined, color: Colors.white24, size: 32),
            SizedBox(height: 8),
            Text('Sem actividade ainda.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  const collapsedCount = 4;
  final hasMore = _pointsHistory.length > collapsedCount;
  final visibleHistory = _historyExpanded ? _pointsHistory : _pointsHistory.take(collapsedCount).toList();

  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      children: [
        ...visibleHistory.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final rawPts = item['points'];
          final pts = rawPts is int ? rawPts : (rawPts as double).toInt();
          final isPositive = pts > 0;
          final date = (item['date'] as Timestamp).toDate();
          final desc = item['description'] as String? ?? '';
          final isLastVisible = i == visibleHistory.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: (!isLastVisible || hasMore)
                  ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(desc,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(DateFormat('dd MMM yyyy').format(date),
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}$pts pts',
                  style: TextStyle(
                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        if (hasMore)
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: () => setState(() => _historyExpanded = !_historyExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _historyExpanded ? 'Ver menos' : 'Ver mais (${_pointsHistory.length - collapsedCount})',
                    style: const TextStyle(
                      color: Color(0xFFB22222),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _historyExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFB22222),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
}