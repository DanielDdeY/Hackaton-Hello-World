import 'package:flutter/material.dart';

class FeedMessage extends StatelessWidget {
  const FeedMessage(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}

Future<void> showFeedDetail(
  BuildContext context,
  List<Widget> Function(BuildContext context) content,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.35,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        children: content(context),
      ),
    ),
  );
}

class FeedPhoto extends StatelessWidget {
  const FeedPhoto({super.key, required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: label,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Cargando foto',
                    ),
                  ),
                ),
          errorBuilder: (_, _, _) => const Center(
            child: Tooltip(
              message: 'Foto no disponible',
              child: Icon(
                Icons.broken_image_outlined,
                semanticLabel: 'Foto no disponible',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeedPhotos extends StatefulWidget {
  const FeedPhotos({super.key, required this.urls, required this.isUploading});

  final List<String> urls;
  final bool isUploading;

  @override
  State<FeedPhotos> createState() => _FeedPhotosState();
}

class _FeedPhotosState extends State<FeedPhotos> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isUploading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            LinearProgressIndicator(semanticsLabel: 'Subiendo fotos'),
            SizedBox(height: 8),
            Text('Subiendo fotos…'),
          ],
        ),
      );
    }
    final urls = widget.urls;
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: FeedPhoto(url: urls.first, label: 'Foto de la publicación'),
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => FeedPhoto(
              url: urls[index],
              label: 'Foto ${index + 1} de ${urls.length}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Foto ${_page + 1} de ${urls.length}'),
      ],
    );
  }
}
