import 'package:flutter/material.dart';
import '../../admin/model/profissional_model.dart';

class ProfessionalCard extends StatefulWidget {
  final ProfissionalModel professional;
  final bool isSelected;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ProfessionalCard> createState() => ProfessionalCardState();
}

class ProfessionalCardState extends State<ProfessionalCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.professional;

    final borderRadius = BorderRadius.circular(18);
    final activeBorder = const Color(0xFFB22222);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_hovering ? 1.01 : 1.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: borderRadius,
          border: Border.all(
            color: widget.isSelected ? activeBorder : Colors.transparent,
            width: widget.isSelected ? 1.2 : 0,
          ),
          boxShadow: [
            if (_hovering)
              BoxShadow(
                color: const Color(0xFFB22222).withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
child: (p.fotoUrl != null && p.fotoUrl!.trim().isNotEmpty)
                            ? Image.network(
                                p.fotoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 38, color: Colors.grey);
                                },
                              )
                            : const Icon(Icons.person, size: 38, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.especialidade ?? 'Especialista',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? const Color(0xFFB22222)
                                  : Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.isSelected ? 'Selecionado' : 'Selecionar',
                              style: TextStyle(
                                color: widget.isSelected ? Colors.white : Colors.white70,
                                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
