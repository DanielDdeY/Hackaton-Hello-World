import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../create_post/data/services/image_picker_photo_picker.dart';
import '../../create_post/domain/services/photo_picker.dart';
import '../../economy/domain/models/economy_result.dart';
import '../../economy/domain/services/economy_engine.dart';
import '../../economy/presentation/economy_failure_messages.dart';
import '../services/backpack_checklist_store.dart';
import '../services/mlkit_reconocedor_objetos.dart';
import '../services/mochila_estado.dart';
import '../services/mochila_etiquetas_catalogo.dart';
import '../services/reconocedor_objetos.dart';
import 'help_section_card.dart';

/// Tarjeta "Mochila de Emergencia" con checklist persistente (offline),
/// verificación de elementos mediante reconocimiento de imágenes (Google ML Kit)
/// y asignación del bono de preparación vecinal.
class MochilaEmergenciaCard extends StatefulWidget {
  const MochilaEmergenciaCard({
    super.key,
    this.reconocedor,
    this.photoPicker,
  });

  final ReconocedorObjetos? reconocedor;
  final PhotoPicker? photoPicker;

  @override
  State<MochilaEmergenciaCard> createState() => _MochilaEmergenciaCardState();
}

class _MochilaEmergenciaCardState extends State<MochilaEmergenciaCard> {
  late Map<String, bool> _items;
  Map<String, String> _itemPhotos = {};
  bool _bonoReclamado = false;
  bool _reclamando = false;
  ReconocedorObjetos? _reconocedor;

  @override
  void initState() {
    super.initState();
    _reconocedor = widget.reconocedor;
    _items = {
      for (final item in BackpackChecklistStore.defaultItems) item: false,
    };
    _load();
  }

  @override
  void dispose() {
    if (widget.reconocedor == null && _reconocedor != null) {
      _reconocedor!.dispose();
    }
    super.dispose();
  }

  ReconocedorObjetos _obtenerReconocedor() {
    return _reconocedor ??= MlKitReconocedorObjetos();
  }

  Future<void> _load() async {
    final loaded = await BackpackChecklistStore.load();
    final photos = await BackpackChecklistStore.loadItemPhotos();
    final reclamado = await MochilaVerificacion.isBonoReclamado();
    if (mounted) {
      setState(() {
        _items = loaded;
        _itemPhotos = photos;
        _bonoReclamado = reclamado;
      });
    }
  }

  Future<void> _toggle(String item, bool? value) async {
    setState(() => _items[item] = value ?? false);
    await BackpackChecklistStore.save(_items);
  }

  Future<void> _tomarFotoItem(String item) async {
    final picker = widget.photoPicker ??
        context.read<PhotoPicker?>() ??
        ImagePickerPhotoPicker(ImagePicker());

    String? ruta;
    try {
      ruta = await picker.pickFromCamera() ?? await picker.pickFromGallery();
    } catch (e) {
      debugPrint('Error al capturar foto: $e');
    }

    if (ruta == null || !mounted) return;
    final fotoRuta = ruta;

    List<String> etiquetas = const [];
    try {
      final reconocedor = _obtenerReconocedor();
      etiquetas = await reconocedor.detectarEtiquetas(fotoRuta);
    } catch (e) {
      debugPrint('Error en reconocimiento con ML Kit: $e');
    }

    if (!mounted) return;

    final coincidente = MochilaEtiquetasCatalogo.etiquetaCoincidente(item, etiquetas);
    bool confirmar = false;

    if (coincidente != null) {
      confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 36),
              title: const Text('¡Elemento detectado!'),
              content: Text(
                'El modelo reconoció "$coincidente" compatible con "$item".\n\n'
                '¿Deseas verificar este elemento y marcarlo en tu mochila?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Verificar elemento'),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      final sugerencias = etiquetas.isNotEmpty
          ? 'Etiquetas sugeridas: ${etiquetas.take(3).join(', ')}.\n\n'
          : '';
      confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 36),
              title: Text('Foto de $item'),
              content: Text(
                '${sugerencias}No pudimos confirmar automáticamente el objeto. '
                '¿Deseas confirmar y guardar tu foto para "$item"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Guardar foto'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (confirmar && mounted) {
      setState(() {
        _items[item] = true;
        _itemPhotos[item] = fotoRuta;
      });
      await BackpackChecklistStore.save(_items);
      await BackpackChecklistStore.saveItemPhoto(item, fotoRuta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Foto guardada y "$item" verificado.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _abrirVerificadorFotos() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Verificación con fotos (ML Kit)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toma una foto clara de cada elemento para comprobarlo automáticamente.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final item in _items.keys)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  _itemPhotos.containsKey(item)
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: _itemPhotos.containsKey(item)
                                      ? const Color(0xFF16A34A)
                                      : AppColors.secondaryText,
                                ),
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontWeight: _itemPhotos.containsKey(item)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  _itemPhotos.containsKey(item)
                                      ? 'Foto comprobada'
                                      : 'Pendiente de foto',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _itemPhotos.containsKey(item)
                                        ? const Color(0xFF16A34A)
                                        : AppColors.secondaryText,
                                  ),
                                ),
                                trailing: OutlinedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _tomarFotoItem(item);
                                  },
                                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                  label: Text(_itemPhotos.containsKey(item) ? 'Cambiar' : 'Foto'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    side: const BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Listo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reclamarBono() async {
    if (_reclamando || _bonoReclamado) return;
    final engine = context.read<EconomyEngine?>();
    final messenger = ScaffoldMessenger.of(context);
    if (engine == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Inicia sesión para reclamar el bono.')),
      );
      return;
    }
    setState(() => _reclamando = true);
    try {
      final result = await engine.award(
        source: EconomySource.backpackVerified,
        sourceId: MochilaVerificacion.sourceId,
        operationId: engine.newOperationId(),
      );
      await MochilaVerificacion.marcarReclamado();
      if (!mounted) return;
      setState(() {
        _bonoReclamado = true;
        _reclamando = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyApplied
                ? 'Tu bono de preparación ya estaba reclamado.'
                : '¡Bono de preparación reclamado! '
                      '+${EconomyResult.backpackCoins} fichas y '
                      '+${EconomyResult.backpackXp} XP 🎉',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } on EconomyFailure catch (error) {
      if (!mounted) return;
      setState(() => _reclamando = false);
      messenger.showSnackBar(
        SnackBar(content: Text(economyFailureMessage(error))),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _reclamando = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo reclamar el bono. Reintenta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.values.where((v) => v).length;
    final estaCompleta = checkedCount == _items.length && _items.isNotEmpty;

    return HelpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _EmojiBadge(icon: Icons.backpack_outlined, emoji: '🎒'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mochila de Emergencia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _PillBadge(
                      icon: Icons.home_outlined,
                      label: '4 Integrantes en vivienda',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items.keys)
                FilterChip(
                  label: Text(item),
                  avatar: _itemPhotos.containsKey(item)
                      ? const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A))
                      : null,
                  selected: _items[item] ?? false,
                  onSelected: (v) => _toggle(item, v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.secondaryText),
                  labelStyle: const TextStyle(color: AppColors.text),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                estaCompleta
                    ? Icons.verified_outlined
                    : Icons.hourglass_bottom_outlined,
                size: 18,
                color: estaCompleta
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  estaCompleta
                      ? 'Mochila completa'
                      : '$checkedCount de ${_items.length} elementos listos',
                  style: TextStyle(
                    fontSize: 13,
                    color: estaCompleta
                        ? AppColors.primary
                        : AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(
                  _itemPhotos.isEmpty
                      ? 'Verificar con foto'
                      : 'Fotos (${_itemPhotos.length}/10)',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _abrirVerificadorFotos,
              ),
            ],
          ),
          if (estaCompleta) ...[
            const SizedBox(height: 10),
            if (!_bonoReclamado)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _reclamando ? null : _reclamarBono,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _reclamando
                              ? 'Reclamando bono…'
                              : 'Reclamar bono de preparación '
                                  '(+${EconomyResult.backpackCoins} fichas, '
                                  '+${EconomyResult.backpackXp} XP)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Insignia "Vecino preparado" obtenida',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.icon, required this.emoji});

  final IconData icon;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondaryText.withValues(alpha: 0.3),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
