import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/keyword_service_category_classifier.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/service_category_keywords.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_category.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/service_category_classifier.dart';

void main() {
  final ServiceCategoryClassifier classifier =
      KeywordServiceCategoryClassifier();

  group('Los 16 casos de aceptación del documento', () {
    final cases = <(String, String, ServiceCategory)>[
      ('Venta de postres', 'Tortas y alfajores caseros', ServiceCategory.food),
      (
        'Gasfitero profesional',
        'Reparo caños y goteras',
        ServiceCategory.homeTrades,
      ),
      ('Clases de inglés', 'Reforzamiento escolar', ServiceCategory.education),
      ('Paseo de perros', 'Cuido a tu mascota', ServiceCategory.pets),
      (
        'Enfermera a domicilio',
        'Inyecciones y adulto mayor',
        ServiceCategory.healthCare,
      ),
      (
        'Reparación de laptops',
        'Formateo y antivirus',
        ServiceCategory.technology,
      ),
      (
        'Mudanzas y fletes',
        'Camioneta con ayudante',
        ServiceCategory.transportMoving,
      ),
      ('Costurera', 'Arreglo de ropa y bastas', ServiceCategory.beautySewing),
      ('Servicio especial', 'Consultar por mensaje', ServiceCategory.other),
      (
        'Delivery de almuerzos',
        'Entrego en la manzana C',
        ServiceCategory.food,
      ),
      ('Cuidado del pie diabético', 'A domicilio', ServiceCategory.healthCare),
      ('Limpieza facial', 'Cuidado de la piel', ServiceCategory.beautySewing),
      ('Limpieza de casas', 'Por horas', ServiceCategory.homeTrades),
      (
        'Reparación de celulares',
        'Cambio de pantalla',
        ServiceCategory.technology,
      ),
      ('Gasfitero', 'reparo caños', ServiceCategory.homeTrades),
      ('TORTAS Y POSTRES', 'ÁÉÍÓÚ', ServiceCategory.food),
    ];

    for (final (title, information, expected) in cases) {
      test(title, () {
        expect(
          classifier.classify(title: title, information: information),
          expected,
        );
      });
    }
  });

  group('Normalización y límites', () {
    test('tolera puntuación, espacios, tildes y ñ', () {
      expect(
        classifier.classify(
          title: '  ¡GASFÍTERO!\n',
          information: 'REPARO—CAÑOS',
        ),
        ServiceCategory.homeTrades,
      );
      expect(
        classifier.classify(title: '  pie---DIABÉTICO  ', information: ''),
        ServiceCategory.healthCare,
      );
    });

    test('tolera diacríticos precompuestos y combinantes', () {
      expect(
        classifier.classify(title: 'ca\u006e\u0303os', information: ''),
        ServiceCategory.homeTrades,
      );
      expect(
        classifier.classify(title: 'PÓSTRËS', information: ''),
        ServiceCategory.food,
      );
    });

    test('no encuentra palabras dentro de otras palabras', () {
      for (final title in ['redistribuir', 'pasteleroide', 'llaveinventada']) {
        expect(
          classifier.classify(title: title, information: ''),
          ServiceCategory.other,
        );
      }
    });

    test('las frases también tienen límites de palabra', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.healthCare: ServiceCategoryKeywords(
            strong: {'pie diabetico'},
          ),
        },
      );
      expect(
        classifier.classify(title: 'pie', information: 'diabético'),
        ServiceCategory.healthCare,
      );
      expect(
        classifier.classify(title: 'ciempié diabético', information: ''),
        ServiceCategory.other,
      );
      expect(
        classifier.classify(title: 'pie diabeticox', information: ''),
        ServiceCategory.other,
      );
    });

    test('no fusiona última palabra del título y primera de información', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(strong: {'pan'}),
          ServiceCategory.technology: ServiceCategoryKeywords(
            strong: {'pantalla'},
          ),
        },
      );
      expect(
        classifier.classify(title: 'pan', information: 'talla'),
        ServiceCategory.food,
      );
    });

    test('entrada vacía o sin palabras reconocidas usa Otros', () {
      for (final title in ['', '   ', '?! 🎉', 'Consulta por mensaje']) {
        expect(
          classifier.classify(title: title, information: ''),
          ServiceCategory.other,
        );
      }
    });
  });

  group('Puntuación y desempates reproducibles', () {
    test('título ×3, información ×1', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(
            strong: {'torta', 'postre'},
          ),
          ServiceCategory.technology: ServiceCategoryKeywords(
            strong: {'laptop'},
          ),
        },
      );
      expect(
        classifier.classify(title: 'laptop', information: 'torta postre'),
        ServiceCategory.technology,
      );
    });

    test('un fuerte pesa el doble de un débil', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(weak: {'casero'}),
          ServiceCategory.technology: ServiceCategoryKeywords(
            strong: {'laptop'},
          ),
        },
      );
      expect(
        classifier.classify(title: 'casero laptop', information: ''),
        ServiceCategory.technology,
      );
    });

    test('el umbral es 2 y un término repetido no lo aumenta', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(
            weak: {'casero', 'dulce'},
          ),
        },
      );
      expect(
        classifier.classify(title: '', information: 'casero casero casero'),
        ServiceCategory.other,
      );
      expect(
        classifier.classify(title: '', information: 'casero dulce'),
        ServiceCategory.food,
      );
      expect(
        classifier.classify(title: 'casero', information: ''),
        ServiceCategory.food,
      );
    });

    test(
      'no duplica términos entre campos ni con tildes en el diccionario',
      () {
        final classifier = KeywordServiceCategoryClassifier(
          keywords: const {
            ServiceCategory.food: ServiceCategoryKeywords(
              strong: {'torta', ' tortá '},
              weak: {'TORTA'},
            ),
            ServiceCategory.technology: ServiceCategoryKeywords(
              strong: {'laptop', 'celular'},
            ),
          },
        );
        expect(
          classifier.classify(
            title: 'laptop torta torta',
            information: 'torta celular',
          ),
          ServiceCategory.technology,
        );
      },
    );

    test('con igual total gana el mayor puntaje del título', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(
            strong: {'torta', 'postre', 'alfajor'},
          ),
          ServiceCategory.technology: ServiceCategoryKeywords(
            strong: {'laptop'},
          ),
        },
      );
      expect(
        classifier.classify(
          title: 'laptop',
          information: 'torta postre alfajor',
        ),
        ServiceCategory.technology,
      );
    });

    test('con igual total y título gana la cantidad de fuertes', () {
      final classifier = KeywordServiceCategoryClassifier(
        keywords: const {
          ServiceCategory.food: ServiceCategoryKeywords(
            weak: {'casero', 'dulce'},
          ),
          ServiceCategory.technology: ServiceCategoryKeywords(
            strong: {'laptop'},
          ),
        },
      );
      expect(
        classifier.classify(title: '', information: 'casero dulce laptop'),
        ServiceCategory.technology,
      );
    });

    test('el desempate final no depende del orden del mapa', () {
      const entries = {
        ServiceCategory.food: ServiceCategoryKeywords(strong: {'torta'}),
        ServiceCategory.technology: ServiceCategoryKeywords(strong: {'laptop'}),
      };
      for (final keywords in [
        entries,
        Map.fromEntries(entries.entries.toList().reversed),
      ]) {
        final classifier = KeywordServiceCategoryClassifier(keywords: keywords);
        expect(
          classifier.classify(title: 'torta laptop', information: ''),
          ServiceCategory.food,
        );
      }
    });

    test(
      'preparar el diccionario no conserva colecciones mutables externas',
      () {
        final terms = {'laptop'};
        final keywords = {
          ServiceCategory.technology: ServiceCategoryKeywords(strong: terms),
        };
        final classifier = KeywordServiceCategoryClassifier(keywords: keywords);
        terms.clear();
        keywords.clear();
        expect(
          classifier.classify(title: 'laptop', information: ''),
          ServiceCategory.technology,
        );
      },
    );
  });

  group('Regresiones del diccionario original', () {
    test('manzana y términos retirados no clasifican lenguaje cotidiano', () {
      for (final title in [
        'manzana B',
        'Van por esa vía',
        'sal',
        'pie',
        'pay',
        'can',
        'res',
        'agua',
        'red',
        'batería',
        'tequeyoyo',
      ]) {
        expect(
          classifier.classify(title: title, information: ''),
          ServiceCategory.other,
          reason: title,
        );
      }
    });

    test('recorta los tres términos con espacios iniciales', () {
      for (final (title, expected) in [
        ('sangrecita', ServiceCategory.food),
        ('cielo raso', ServiceCategory.homeTrades),
        ('electrodoméstico', ServiceCategory.homeTrades),
      ]) {
        expect(classifier.classify(title: title, information: ''), expected);
      }
    });

    test('resuelve ambigüedades con frases', () {
      for (final (title, expected) in [
        ('jugo de manzana', ServiceCategory.food),
        ('arroz aeropuerto', ServiceCategory.food),
        ('traslado aeropuerto', ServiceCategory.transportMoving),
        ('pescado perico', ServiceCategory.food),
        ('ave perico', ServiceCategory.pets),
        ('clases de batería', ServiceCategory.education),
        ('batería de celular', ServiceCategory.technology),
        ('batería descargada', ServiceCategory.transportMoving),
      ]) {
        expect(
          classifier.classify(title: title, information: ''),
          expected,
          reason: title,
        );
      }
    });

    test('vocabulario local válido conservado', () {
      for (final title in [
        'inchicapi',
        'patarashca',
        'shambar',
        'kiwicha',
        'pallar',
        'cecina',
      ]) {
        expect(
          classifier.classify(title: title, information: ''),
          ServiceCategory.food,
        );
      }
    });

    test('claves estables únicas y prioridad completa sin Otros', () {
      expect(ServiceCategory.values.map((c) => c.key).toSet().length, 9);
      expect(ServiceCategory.values.map((c) => c.key), [
        'food',
        'home_trades',
        'education',
        'pets',
        'health_care',
        'technology',
        'transport_moving',
        'beauty_sewing',
        'other',
      ]);
      expect(
        serviceCategoryPriority.toSet(),
        ServiceCategory.values.toSet()..remove(ServiceCategory.other),
      );
      expect(
        serviceCategoryKeywords.keys.toSet(),
        serviceCategoryPriority.toSet(),
      );
    });
  });
}
