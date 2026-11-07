import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/post_category.dart';
import '../forms/emergency/emergency_form.dart';
import '../forms/help/help_form.dart';
import '../forms/news/news_form.dart';
import '../forms/services/service_form.dart';
import '../widgets/category_card.dart';

class CategorySelectorPage extends StatelessWidget {
  const CategorySelectorPage({super.key});

  static const _categories = [
    (
      category: PostCategory.emergency,
      title: 'Emergencia',
      description: 'Alerta crítica o S.O.S.',
      icon: Icons.emergency_outlined,
    ),
    (
      category: PostCategory.help,
      title: 'Ayuda',
      description: 'Cadena de favores sin dinero',
      icon: Icons.volunteer_activism_outlined,
    ),
    (
      category: PostCategory.services,
      title: 'Servicios',
      description: 'Oficios y Visto Bueno',
      icon: Icons.handyman_outlined,
    ),
    (
      category: PostCategory.news,
      title: 'Noticias',
      description: 'Avisos y reportes vecinales',
      icon: Icons.campaign_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '¿Qué deseas publicar hoy?',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona una categoría',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - gap) / 2;
                      final height = _categories
                          .map(
                            (option) => CategoryCard.heightFor(
                              context,
                              width: width,
                              title: option.title,
                              description: option.description,
                            ),
                          )
                          .reduce(math.max);

                      return GridView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          mainAxisExtent: height,
                        ),
                        children: [
                          for (final option in _categories)
                            CategoryCard(
                              title: option.title,
                              description: option.description,
                              icon: option.icon,
                              isUrgent:
                                  option.category == PostCategory.emergency,
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => switch (option.category) {
                                    PostCategory.emergency =>
                                      const EmergencyForm(),
                                    PostCategory.help => const HelpForm(),
                                    PostCategory.services =>
                                      const ServiceForm(),
                                    PostCategory.news => const NewsForm(),
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
