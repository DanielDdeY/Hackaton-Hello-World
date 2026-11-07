import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/app_colors.dart';

class SimulacroVideoPage extends StatefulWidget {
  const SimulacroVideoPage({super.key});

  static const videoId = 'f9h9EIuuWs8';

  @override
  State<SimulacroVideoPage> createState() => _SimulacroVideoPageState();
}

class _SimulacroVideoPageState extends State<SimulacroVideoPage> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _playerSubscription;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        interfaceLanguage: 'es',
      ),
      onWebResourceError: (_) {
        if (mounted) setState(() => _hasLoadError = true);
      },
    );
    unawaited(_controller.cueVideoById(videoId: SimulacroVideoPage.videoId));

    _playerSubscription = _controller.stream.listen((value) {
      if (value.hasError && mounted) {
        setState(() => _hasLoadError = true);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_playerSubscription.cancel());
    unawaited(_controller.close());
    super.dispose();
  }

  void _retry() {
    setState(() => _hasLoadError = false);
    unawaited(_controller.cueVideoById(videoId: SimulacroVideoPage.videoId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulacro de emergencia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Prepárate practicando',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Realizar simulacros ayuda a saber cómo actuar y a proteger '
              'a quienes te rodean durante una emergencia.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
            if (_hasLoadError) ...[
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el video. Revisa tu conexión e inténtalo '
                'de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
