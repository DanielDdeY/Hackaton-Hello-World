import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/item_mascota.dart';
import '../../domain/entities/mascota.dart';
import '../../domain/repositories/mascota_repository.dart';
import '../dialogs/apertura_caja_dialog.dart';
import '../widgets/coleccion_items_sheet.dart';
import '../widgets/cuy_stage.dart';

/// Pantalla principal de gestion e interaccion con la mascota comunitaria.
class MascotaPage extends StatefulWidget {
  const MascotaPage({
    super.key,
    required this.uid,
    required this.mascotaRepository,
    required this.fichasActuales,
    required this.onFichasActualizadas,
  });

  final String uid;
  final MascotaRepository mascotaRepository;
  final int fichasActuales;
  final ValueChanged<int> onFichasActualizadas;

  @override
  State<MascotaPage> createState() => _MascotaPageState();
}

class _MascotaPageState extends State<MascotaPage> {
  late Stream<Mascota> _mascotaStream;
  late int _fichas;

  @override
  void initState() {
    super.initState();
    _fichas = widget.fichasActuales;
    _mascotaStream = widget.mascotaRepository.escucharMascota(widget.uid);
  }

  void _editarNombre(Mascota mascota) {
    final controller = TextEditingController(text: mascota.nombre);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombrar a tu Cuy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Cuy Mágico',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevo = controller.text.trim();
              if (nuevo.isNotEmpty) {
                widget.mascotaRepository.actualizarNombre(widget.uid, nuevo);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _abrirColeccion(Mascota mascota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColeccionItemsSheet(
        mascota: mascota,
        onEquipar: (itemId) {
          widget.mascotaRepository.equiparItem(widget.uid, itemId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _abrirCajaDialog(Mascota mascota) {
    showDialog(
      context: context,
      builder: (context) => AperturaCajaDialog(
        mascota: mascota,
        fichasDisponibles: _fichas,
        onConfirmarApertura: () async {
          final resultado = await widget.mascotaRepository.abrirCaja(
            uid: widget.uid,
            fichasDisponibles: _fichas,
          );
          // Actualiza saldo de fichas localmente
          final nuevoSaldo = _fichas - resultado.fichasCobradas + resultado.fichasDevueltas;
          setState(() => _fichas = nuevoSaldo);
          widget.onFichasActualizadas(nuevoSaldo);
          return resultado;
        },
        onEquiparNuevo: (itemId) {
          widget.mascotaRepository.equiparItem(widget.uid, itemId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuy'),
        actions: [
          // Contador de fichas
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB703), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/ficha.svg', width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  '$_fichas',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A4A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<Mascota>(
        stream: _mascotaStream,
        builder: (context, snapshot) {
          final mascota = snapshot.data ?? Mascota.inicial();
          final itemEquipado = ItemMascota.porId(mascota.itemEquipadoId);
          final pityProgreso = (mascota.pityCount / 20.0).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Nombre editable
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mascota.nombre,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Cambiar nombre',
                      onPressed: () => _editarNombre(mascota),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Escenario visual del Cuy
                CuyStage(itemEquipado: itemEquipado),
                const SizedBox(height: 16),

                // Barra de garantia Pity hacia el Legendario
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Garantía hacia Sombrero Mugiwara:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${mascota.pityCount} de 20',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE76F51),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pityProgreso,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE76F51)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botones principales: Abrir Caja y Coleccion
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D77),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _abrirCajaDialog(mascota),
                        icon: Image.asset('assets/mascota/caja-1.png', width: 22, height: 22),
                        label: Text(
                          mascota.primeraCajaGratis ? 'Abrir Caja (Gratis)' : 'Abrir Caja (30)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFF006D77)),
                      ),
                      onPressed: () => _abrirColeccion(mascota),
                      icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF006D77)),
                      label: const Text(
                        'Objetos',
                        style: TextStyle(
                          color: Color(0xFF006D77),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
