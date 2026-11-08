import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/item_mascota.dart';
import '../../domain/entities/mascota.dart';
import '../../domain/services/caja_sorpresas_service.dart';

/// Modal interactivo para confirmar y animar la apertura de una caja de sorpresas.
class AperturaCajaDialog extends StatefulWidget {
  const AperturaCajaDialog({
    super.key,
    required this.mascota,
    required this.fichasDisponibles,
    required this.onConfirmarApertura,
    required this.onEquiparNuevo,
  });

  final Mascota mascota;
  final int fichasDisponibles;
  final Future<ResultadoAperturaCaja> Function() onConfirmarApertura;
  final ValueChanged<String> onEquiparNuevo;

  @override
  State<AperturaCajaDialog> createState() => _AperturaCajaDialogState();
}

enum _FaseApertura { confirmacion, animando, resultado }

class _AperturaCajaDialogState extends State<AperturaCajaDialog>
    with SingleTickerProviderStateMixin {
  _FaseApertura _fase = _FaseApertura.confirmacion;
  ResultadoAperturaCaja? _resultado;
  String? _error;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    setState(() {
      _fase = _FaseApertura.animando;
      _error = null;
    });

    _shakeController.repeat(reverse: true);

    try {
      final resultado = await widget.onConfirmarApertura();
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      _shakeController.stop();
      setState(() {
        _resultado = resultado;
        _fase = _FaseApertura.resultado;
      });
    } catch (e) {
      if (!mounted) return;
      _shakeController.stop();
      setState(() {
        _fase = _FaseApertura.confirmacion;
        _error = e.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: switch (_fase) {
          _FaseApertura.confirmacion => _buildConfirmacion(context),
          _FaseApertura.animando => _buildAnimando(context),
          _FaseApertura.resultado => _buildResultado(context),
        },
      ),
    );
  }

  Widget _buildConfirmacion(BuildContext context) {
    final esGratis = widget.mascota.primeraCajaGratis;
    final costo = esGratis ? 0 : CajaSorpresasService.costoCaja;
    final puedePagar = widget.fichasDisponibles >= costo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Caja de Sorpresas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Image.asset(
          'assets/mascota/caja-1.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        if (esGratis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: const Text(
              '¡Tu primera caja es GRATIS!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Costo: ', style: TextStyle(fontSize: 15)),
              SvgPicture.asset('assets/ficha.svg', width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                '$costo fichas',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'Garantía: ${widget.mascota.pityCount}/20 para Legendario',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D77),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: puedePagar ? _abrir : null,
              child: Text(esGratis ? '¡Abrir gratis!' : 'Abrir caja'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimando(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¡Abriendo caja de sorpresas...!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final angle = (_shakeController.value - 0.5) * 0.2;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: Image.asset(
            'assets/mascota/caja-1.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        const Text('¿Qué accesorio saldrá?', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildResultado(BuildContext context) {
    final resultado = _resultado!;
    final item = resultado.item;
    final esNuevo = resultado.esNuevo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          esNuevo ? '¡Nuevo Objeto Desbloqueado!' : '¡Objeto Repetido!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: esNuevo ? const Color(0xFF2E7D32) : const Color(0xFFD48B00),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Visualizacion del item obtenido
        SizedBox(
          height: 100,
          child: item.assetPath.endsWith('.svg')
              ? SvgPicture.asset(item.assetPath, fit: BoxFit.contain)
              : Image.asset(item.assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text(
          item.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: item.rareza == RarezaItem.legendario
                ? const Color(0xFFFFECE0)
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.rareza.etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: item.rareza == RarezaItem.legendario
                  ? const Color(0xFFE76F51)
                  : const Color(0xFF0077B6),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Mensaje de reembolso o nuevo
        if (!esNuevo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/ficha.svg', width: 16, height: 16),
                const SizedBox(width: 6),
                Text(
                  '¡Reembolso de +${resultado.fichasDevueltas} fichas!',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D6200)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Botones de accion
        if (esNuevo)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Guardar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  widget.onEquiparNuevo(item.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Equipárselo'),
              ),
            ],
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
      ],
    );
  }
}
