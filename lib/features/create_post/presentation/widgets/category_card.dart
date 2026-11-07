import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.isUrgent = false,
  });

  static const _padding = EdgeInsets.all(14);
  static const _iconSize = 40.0;
  static const _titleGap = 12.0;
  static const _descriptionGap = 4.0;

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isUrgent;

  static TextStyle _titleStyle(ThemeData theme) =>
      theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600);

  static TextStyle _descriptionStyle(ThemeData theme) => theme
      .textTheme
      .bodyMedium!
      .copyWith(color: theme.colorScheme.onSurfaceVariant);

  static double heightFor(
    BuildContext context, {
    required double width,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final textWidth = width - _padding.horizontal;

    double textHeight(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return (_padding.vertical +
            _iconSize +
            _titleGap +
            textHeight(title, _titleStyle(theme)) +
            _descriptionGap +
            textHeight(description, _descriptionStyle(theme)))
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: _padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? colors.errorContainer
                        : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isUrgent
                        ? colors.onErrorContainer
                        : colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: _titleGap),
                Text(title, style: _titleStyle(theme)),
                const SizedBox(height: _descriptionGap),
                Text(description, style: _descriptionStyle(theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
