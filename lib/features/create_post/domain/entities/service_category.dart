/// Claves persistentes; las etiquetas pueden cambiar sin migrar publicaciones.
enum ServiceCategory {
  food('food', 'Comida'),
  homeTrades('home_trades', 'Hogar y Oficios'),
  education('education', 'Educación'),
  pets('pets', 'Mascotas'),
  healthCare('health_care', 'Salud y Cuidado'),
  technology('technology', 'Tecnología'),
  transportMoving('transport_moving', 'Transporte y Mudanza'),
  beautySewing('beauty_sewing', 'Belleza y Costura'),
  other('other', 'Otros');

  const ServiceCategory(this.key, this.label);

  final String key;
  final String label;
}
