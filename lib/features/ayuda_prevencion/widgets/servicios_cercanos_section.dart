import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../models/nearby_service.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import 'help_section_card.dart';

/// Estados de la búsqueda de servicios cercanos.
enum NearbyStatus { initial, loading, success, empty, error }

/// Sección "Cerca de ti": GPS + Overpass API (OpenStreetMap).
class ServiciosCercanosSection extends StatefulWidget {
  const ServiciosCercanosSection({super.key});

  @override
  State<ServiciosCercanosSection> createState() =>
      _ServiciosCercanosSectionState();
}

class _ServiciosCercanosSectionState extends State<ServiciosCercanosSection> {
  NearbyStatus _status = NearbyStatus.initial;
  List<NearbyService> _services = const [];
  String? _errorMessage;

  Future<void> _search() async {
    setState(() {
      _status = NearbyStatus.loading;
      _errorMessage = null;
    });

    final location = await LocationService.getCurrentPosition();
    if (!location.isSuccess) {
      setState(() {
        _status = NearbyStatus.error;
        _errorMessage = location.error;
      });
      return;
    }

    try {
      final position = location.position!;
      final services = await OverpassService.findNearby(
        lat: position.latitude,
        lon: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _services = services;
        _status = services.isEmpty ? NearbyStatus.empty : NearbyStatus.success;
      });
    } on OverpassException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = NearbyStatus.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = NearbyStatus.error;
        _errorMessage = 'Error inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HelpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.near_me, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cerca de ti',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _status == NearbyStatus.loading ? null : _search,
                icon: _status == NearbyStatus.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  _status == NearbyStatus.initial ? 'Buscar' : 'Actualizar',
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Hospitales, clínicas, policía y bomberos según tu ubicación '
            '(OpenStreetMap).',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 12),
          ..._buildBody(),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    switch (_status) {
      case NearbyStatus.initial:
        return const [
          _InfoBox(
            icon: Icons.gps_fixed,
            text: 'Presiona "Buscar" para encontrar servicios cerca de ti.',
          ),
        ];
      case NearbyStatus.loading:
        return const [
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ];
      case NearbyStatus.empty:
        return const [
          _InfoBox(
            icon: Icons.search_off,
            text: 'No se encontraron servicios en un radio de 3 km.',
          ),
        ];
      case NearbyStatus.error:
        return [
          _InfoBox(
            icon: Icons.error_outline,
            text: _errorMessage ?? 'No se pudo completar la búsqueda.',
            isError: true,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _search,
              child: const Text('Reintentar'),
            ),
          ),
        ];
      case NearbyStatus.success:
        return [
          for (final service in _services.take(10))
            _ServiceTile(service: service),
        ];
    }
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final NearbyService service;

  Future<void> _call(BuildContext context) async {
    final uri = service.dialUri;
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo llamar a ${service.name}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCall = service.dialUri != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
                Text(
                  [
                    service.formattedDistance,
                    if (service.category != null) service.category!,
                    if (service.phoneNumber != null) service.phoneNumber!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canCall ? () => _call(context) : null,
            icon: Icon(
              Icons.phone,
              size: 20,
              color: canCall ? AppColors.primary : AppColors.secondaryText,
            ),
            tooltip: canCall ? 'Llamar' : 'Sin teléfono registrado',
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : AppColors.secondaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}
