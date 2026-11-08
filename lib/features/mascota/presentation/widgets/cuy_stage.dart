import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/item_mascota.dart';

/// Escenario interactivo del Cuy con fondo, animacion suave de respiracion y accesorio anclado.
class CuyStage extends StatefulWidget {
  const CuyStage({
    super.key,
    this.itemEquipado,
    this.size = 280,
  });

  final ItemMascota? itemEquipado;
  final double size;

  @override
  State<CuyStage> createState() => _CuyStageState();
}

class _CuyStageState extends State<CuyStage> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _respiracion;
  bool _reaccionActiva = false;

  // Punto de anclaje de la cabeza en el lienzo base de 540x540 px
  static const Offset _cuyAnclaje = Offset(270, 110);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _respiracion = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _reaccionarAlToque() {
    setState(() => _reaccionActiva = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _reaccionActiva = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double stageSize = widget.size;
    final double k = stageSize / 540.0;
    final item = widget.itemEquipado;
    final scaleFactor = stageSize / 280.0;

    return Center(
      child: GestureDetector(
        onTap: _reaccionarAlToque,
        child: SizedBox(
          width: stageSize,
          height: stageSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fondo del escenario anclado al piso de la habitacion
              ClipRRect(
                borderRadius: BorderRadius.circular(20 * scaleFactor),
                child: Image.asset(
                  'assets/mascota/fondo.png',
                  width: stageSize,
                  height: stageSize,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // Mascota y accesorio con animacion relacional de balanceo/respiracion
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final offsetY = _reaccionActiva ? (-12.0 * scaleFactor) : (_respiracion.value * scaleFactor);
                  return Transform.translate(
                    offset: Offset(0, offsetY),
                    child: child,
                  );
                },
                child: Stack(
                  children: [
                    // Base del Cuy asentada sobre el suelo
                    Image.asset(
                      'assets/mascota/cuy-base.png',
                      width: stageSize,
                      height: stageSize,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/mascota/cuy-base1.png',
                        width: stageSize,
                        height: stageSize,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.pets,
                          size: 96 * scaleFactor,
                          color: const Color(0xFF006D77),
                        ),
                      ),
                    ),

                    // Accesorio anclado a la cabeza de forma relacional
                    if (item != null)
                      Positioned(
                        left: (_cuyAnclaje.dx + item.dx - (96 * item.escala)) * k,
                        top: (_cuyAnclaje.dy + item.dy - (96 * item.escala)) * k,
                        width: 192 * item.escala * k,
                        height: 192 * item.escala * k,
                        child: item.assetPath.endsWith('.svg')
                            ? SvgPicture.asset(
                                item.assetPath,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                item.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                      ),
                  ],
                ),
              ),

              // Efecto visual al tocar (escalado relacionalmente)
              if (_reaccionActiva)
                Positioned(
                  top: 24 * scaleFactor,
                  child: AnimatedOpacity(
                    opacity: _reaccionActiva ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scaleFactor,
                        vertical: 4 * scaleFactor,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Colors.redAccent, size: 16 * scaleFactor),
                          SizedBox(width: 4 * scaleFactor),
                          Text(
                            '¡Cui cui!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12 * scaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
