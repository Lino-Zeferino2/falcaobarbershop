import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';


import '../../admin/controller/admin_controller.dart';
import '../../admin/model/post_model.dart';
import '../../admin/model/settings_model.dart';
import 'booking_page.dart';

class PortfolioWorksPage extends StatefulWidget {
  const PortfolioWorksPage({super.key});

  @override
  State<PortfolioWorksPage> createState() => _PortfolioWorksPageState();
}

class _PortfolioWorksPageState extends State<PortfolioWorksPage> {
  final ScrollController _scrollController = ScrollController();

  // Controle de play/pause por card
  late final List<ValueNotifier<bool>> _videoIsPlaying;

  @override
  void initState() {
    super.initState();
    _videoIsPlaying = List<ValueNotifier<bool>>.generate(
      _videoSlugs.length,
      (_) => ValueNotifier<bool>(true),
    );
  }

  @override
  void dispose() {
    for (final n in _videoIsPlaying) {
      n.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // Contador simples pra garantir que o index bate com o card renderizado

  // Vídeos (nomes/slug) usados tanto no mobile quanto no Web.
  // No Web vamos apontar para o caminho público do arquivo.
  final List<String> _videoSlugs = const [
    'afro-elite.mp4',
    'corte-classico.mp4',
    'degrade.mp4',
    'limpeza-facial.mp4',
  ];



  Future<SettingsModel?> _loadSettings() => AdminController().getSettings();

  // dispose removido (já existe outro override ao final do estado)


  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _prettyVideoTitle(String assetPath) {
    final file = assetPath.split('/').last;
    final noExt = file.replaceAll('.mp4', '');
    return noExt
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceFirstMapped(RegExp(r'^(.)'), (m) => m.group(1)!.toUpperCase());
  }

  Widget _videoCard(String assetPath, {required int index}) {
    return GestureDetector(
      onTap: () => _openVideoFullscreen(
  context, 
  assetPath, 
  _prettyVideoTitle(assetPath),  // ← passa o título aqui
),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            border: Border.all(color: const Color(0xFFB22222).withOpacity(0.35)),
          ),
          child:Stack(
        fit: StackFit.expand,
        children: [
                _LocalVideoPlayer(
                  assetPath: assetPath,
                  isPlaying: _videoIsPlaying[index],
                  onPlayerReady: () {},
                ),
                const Positioned(
                  left: 16,
                  top: 16,
                  child: Chip(
                    backgroundColor: Color(0xFFB22222),
                    labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    avatar: Icon(Icons.play_arrow, color: Colors.white),
                    label: Text('Vídeo'),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      _prettyVideoTitle(assetPath),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              ],
            ),
          ),
        
      ),
    );
  }

  Widget _buildHeader(SettingsModel? settings) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D0D),
                Color(0xFF0B0B0B),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
       
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Estilo que fala por si',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 44 : 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  settings?.subDescricao ??
                      'Confira alguns dos nossos cortes e serviços — do clássico ao degradê perfeito.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: isDesktop ? 18 : 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(
                color: Colors.white.withOpacity(0.10),
                thickness: 1,
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB22222).withOpacity(0.10),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('Nossos Trabalhos'),
        centerTitle: false,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<SettingsModel?>(
        future: _loadSettings(),
        builder: (context, settingsSnap) {
          final settings = settingsSnap.data;

          if (settingsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(settings)),

              // Vídeos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Vídeos'),
                      const Text(
                        'Selecionamos nossos melhores momentos para você sentir a diferença.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                          LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 900;
                          // Cards mais largos/altos: menos colunas
                          final crossAxisCount = isDesktop ? 3 : 2;

                          return  GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _videoSlugs.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: isDesktop ? 1.4 : 0.55,
  ),
                            itemBuilder: (context, index) {
                              final slug = _videoSlugs[index];
                              final assetPath = kIsWeb 
    ? 'videos/$slug'  // path relativo na pasta web/
    : 'assets/videos/$slug';  // path local para mobile

                              return _videoCard(
                                assetPath,
                                index: index,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),

              // Fotos (Firebase /posts)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Fotos'),
                      const Text(
                        'Imagens reais do nosso trabalho.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<List<PostModel>>(
                        stream: AdminController().getAllPosts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                'Erro ao carregar fotos.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                'Nenhuma foto disponível no momento.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 900;
                              // Fotos mais amplas e menos colunas
                              final crossAxisCount = isDesktop ? 3 : 2;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: posts.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: isDesktop ? 1.4 : 0.55,
  ),
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  final url = post.imageUrl;

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFB22222).withOpacity(0.25),
                                        ),
                                        color: const Color(0xFF161616),
                                      ),
                                      child: url == null || url.trim().isEmpty
                                          ? const Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.white54,
                                              ),
                                            )
                                          : Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  url,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return const Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          Color(0xFFB22222),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.broken_image_outlined,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Positioned.fill(
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.black.withOpacity(0.0),
                                                          Colors.black.withOpacity(0.35),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          user == null
                              ? 'Logue para agendar e acompanhar seu histórico.'
                              : 'Pronto para agendar? Mostre seu estilo!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BookingPage(
                                  selectedService: null,
                                  selectedBarbearia: null,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('Agendar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB22222),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocalVideoPlayer extends StatefulWidget {
  final String assetPath;
  final ValueListenable<bool> isPlaying;
  final VoidCallback onPlayerReady;

  const _LocalVideoPlayer({
    required this.assetPath,
    required this.isPlaying,
    required this.onPlayerReady,
  });

  @override
  State<_LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<_LocalVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _controller =  VideoPlayerController.networkUrl(Uri.parse(widget.assetPath))
      ..setLooping(true)
      ..setVolume(0);

    widget.isPlaying.addListener(_syncPlayback);

    _controller!.initialize().then((_) {
      if (!mounted) return;

      if (_controller!.value.hasError) {
        debugPrint(
          '[VideoPlayer] Erro ao carregar ${widget.assetPath}: ${_controller?.value.errorDescription ?? _controller?.value}',
        );
        setState(() => _ready = false);
        return;
      }

      setState(() => _ready = true);
      widget.onPlayerReady();

      _syncPlayback();
    }).catchError((e) {
      if (!mounted) return;
      debugPrint('[VideoPlayer] Falha ao inicializar ${widget.assetPath}: $e');
      setState(() => _ready = false);
    });
  }

  void _syncPlayback() {
    if (!_ready) return;
    final shouldPlay = widget.isPlaying.value;
    final ctrl = _controller;
    if (ctrl == null) return;

    if (shouldPlay) {
      if (!ctrl.value.isPlaying) ctrl.play();
    } else {
      if (ctrl.value.isPlaying) ctrl.pause();
    }
  }

  @override
  void dispose() {
    widget.isPlaying.removeListener(_syncPlayback);
    _controller?.dispose();
    super.dispose();
  }


@override
Widget build(BuildContext context) {
  if (!_ready) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB22222),
            Color(0xFF0D0D0D),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 56,
          color: Colors.white70,
        ),
      ),
    );
  }

  return ClipRect(
    child: OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: FittedBox(
        fit: BoxFit.none,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    ),
  );
}






}
void _openVideoFullscreen(BuildContext context, String assetPath, String title)  {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.95),
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: _FullscreenVideoPlayer(assetPath: assetPath),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: const CircleBorder(),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
class _FullscreenVideoPlayer extends StatefulWidget {
  final String assetPath;
  const _FullscreenVideoPlayer({required this.assetPath});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.assetPath))
      ..setLooping(true)
      ..setVolume(1.0);

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      _playing ? _controller.play() : _controller.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          AnimatedOpacity(
            opacity: _playing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
            ),
          ),
        ],
      ),
    );
  }
}

