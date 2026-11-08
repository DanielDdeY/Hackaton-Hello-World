import '../../domain/entities/service_category.dart';
import '../../domain/services/service_category_classifier.dart';
import 'service_category_keywords.dart';

/// Último desempate estable, independiente del orden del mapa del diccionario.
/// Se mantiene el orden de las categorías de producto, sin incluir el fallback.
const serviceCategoryPriority = [
  ServiceCategory.food,
  ServiceCategory.homeTrades,
  ServiceCategory.education,
  ServiceCategory.pets,
  ServiceCategory.healthCare,
  ServiceCategory.technology,
  ServiceCategory.transportMoving,
  ServiceCategory.beautySewing,
];

final class KeywordServiceCategoryClassifier
    implements ServiceCategoryClassifier {
  KeywordServiceCategoryClassifier({
    Map<ServiceCategory, ServiceCategoryKeywords> keywords =
        serviceCategoryKeywords,
  }) : _categories = [
         for (final category in serviceCategoryPriority)
           if (keywords[category] case final vocabulary?)
             _PreparedCategory(category, vocabulary),
       ];

  final List<_PreparedCategory> _categories;

  @override
  ServiceCategory classify({
    required String title,
    required String information,
  }) {
    final titleText = _SearchText(_normalize(title));
    // El espacio evita fusionar palabras entre los dos campos. Una frase que
    // cruza el límite se puntúa como información, nunca como título completo.
    final combinedText = _SearchText(_normalize('$title $information'));
    var bestCategory = ServiceCategory.other;
    var best = const _Score(0, 0, 0);

    for (final category in _categories) {
      final score = category.score(titleText, combinedText);
      if (score.total >= 2 && score.isBetterThan(best)) {
        best = score;
        bestCategory = category.category;
      }
    }
    return bestCategory;
  }
}

final class _PreparedCategory {
  _PreparedCategory(this.category, ServiceCategoryKeywords vocabulary)
    : strong = _prepare(vocabulary.strong),
      weak = _prepare(vocabulary.weak) {
    // Una variante con tilde o espacios no debe duplicar un término fuerte.
    weak.removeAll(strong);
  }

  final ServiceCategory category;
  final Set<String> strong;
  final Set<String> weak;

  static Set<String> _prepare(Set<String> terms) {
    final prepared = <String>{};
    for (final term in terms) {
      final normalized = _normalize(term);
      if (normalized.isNotEmpty) prepared.add(normalized);
    }
    return prepared;
  }

  _Score score(_SearchText title, _SearchText combined) {
    var total = 0;
    var titleScore = 0;
    var strongCount = 0;

    void addMatches(Set<String> terms, int weight) {
      for (final term in terms) {
        if (!combined.contains(term)) continue;
        // Cada término cuenta una vez en toda la entrada. Si aparece en ambos
        // campos, prevalece el título (×3); repetirlo no aumenta el puntaje.
        final inTitle = title.contains(term);
        final points = weight * (inTitle ? 3 : 1);
        total += points;
        if (inTitle) titleScore += points;
        if (weight == 2) strongCount++;
      }
    }

    addMatches(strong, 2);
    addMatches(weak, 1);
    return _Score(total, titleScore, strongCount);
  }
}

final class _Score {
  const _Score(this.total, this.title, this.strongCount);

  final int total;
  final int title;
  final int strongCount;

  bool isBetterThan(_Score other) {
    if (total != other.total) return total > other.total;
    if (title != other.title) return title > other.title;
    return strongCount > other.strongCount;
  }
}

final class _SearchText {
  _SearchText(String text)
    : tokens = text.split(' ').toSet(),
      padded = ' $text ';

  final Set<String> tokens;
  final String padded;

  bool contains(String term) =>
      term.contains(' ') ? padded.contains(' $term ') : tokens.contains(term);
}

// Se crean una vez, nunca por palabra dentro de classify(). Se contemplan
// letras latinas habituales y tildes Unicode descompuestas (por ej. n + ◌̃).
final _accentGroups = <RegExp, String>{
  RegExp('[áàâäãåāăą]'): 'a',
  RegExp('[éèêëēĕėęě]'): 'e',
  RegExp('[íìîïĩīĭįı]'): 'i',
  RegExp('[óòôöõøōŏő]'): 'o',
  RegExp('[úùûüũūŭůűų]'): 'u',
  RegExp('[ñńņň]'): 'n',
  RegExp('[çćĉċč]'): 'c',
  RegExp('[ýÿŷ]'): 'y',
  RegExp('[śŝşš]'): 's',
  RegExp('[źżž]'): 'z',
  RegExp('[ŕŗř]'): 'r',
  RegExp('[ďđ]'): 'd',
  RegExp('[ťţ]'): 't',
};
final _combiningMarks = RegExp(r'[\u0300-\u036f]');
final _punctuation = RegExp(r'[^a-z0-9\s]');
final _spaces = RegExp(r'\s+');

String _normalize(String text) {
  var normalized = text.toLowerCase();
  for (final group in _accentGroups.entries) {
    normalized = normalized.replaceAll(group.key, group.value);
  }
  return normalized
      .replaceAll(_combiningMarks, '')
      .replaceAll(_punctuation, ' ')
      .replaceAll(_spaces, ' ')
      .trim();
}
