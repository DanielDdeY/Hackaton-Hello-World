import 'package:flutter/material.dart';

/// Datos personales del vecino con protección de privacidad en el teléfono y accesos rápidos.
class PerfilDatosPersonales extends StatefulWidget {
  const PerfilDatosPersonales({
    super.key,
    required this.zona,
    required this.telefono,
    required this.bio,
    required this.onEditar,
    required this.onContactosSos,
  });

  final String zona;
  final String telefono;
  final String bio;
  final VoidCallback onEditar;
  final VoidCallback onContactosSos;

  @override
  State<PerfilDatosPersonales> createState() => _PerfilDatosPersonalesState();
}

class _PerfilDatosPersonalesState extends State<PerfilDatosPersonales> {
  bool _telefonoVisible = false;

  String _enmascarar(String tel) {
    final limpio = tel.trim();
    if (limpio.isEmpty) return 'No indicado';
    if (limpio.length <= 4) return limpio;
    final prefijo = limpio.substring(0, 3);
    final sufijo = limpio.substring(limpio.length - 2);
    return '$prefijo ••• •$sufijo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_pin_outlined, size: 20, color: Color(0xFF006D77)),
            const SizedBox(width: 8),
            Text(
              'Información del vecino',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.bio.isNotEmpty) ...[
                  Text(
                    'Biografía',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.bio, style: theme.textTheme.bodyMedium),
                  const Divider(height: 20),
                ],
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: Color(0xFF006D77)),
                  title: const Text('Ubicación'),
                  subtitle: Text(
                    widget.zona.isEmpty ? 'No indicada' : widget.zona,
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined, color: Color(0xFF006D77)),
                  title: const Text('Teléfono celular'),
                  subtitle: Text(
                    _telefonoVisible ? widget.telefono : _enmascarar(widget.telefono),
                  ),
                  trailing: widget.telefono.trim().isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            _telefonoVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF6B7280),
                          ),
                          tooltip: _telefonoVisible ? 'Ocultar número' : 'Mostrar número',
                          onPressed: () => setState(() => _telefonoVisible = !_telefonoVisible),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onContactosSos,
                icon: const Icon(Icons.contact_phone_outlined, size: 18),
                label: const Text('Contactos SOS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF006D77)),
                  foregroundColor: const Color(0xFF006D77),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onEditar,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar datos'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

