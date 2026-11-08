final class Recognition {
  const Recognition({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.recipientId,
    required this.recipientName,
    required this.message,
    required this.period,
    required this.createdAt,
    this.districtId,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String recipientId;
  final String recipientName;
  final String? districtId;
  final String message;
  final String period;
  final DateTime createdAt;
}

final class RecognitionDraft {
  RecognitionDraft({
    required this.recipientId,
    required this.recipientName,
    required String message,
    this.districtId,
  }) : message = message.trim();

  static const messageLimit = 280;

  final String recipientId;
  final String recipientName;
  final String? districtId;
  final String message;

  bool get isValid =>
      recipientId.isNotEmpty &&
      !recipientId.contains('/') &&
      recipientName.trim().isNotEmpty &&
      message.isNotEmpty &&
      message.runes.length <= messageLimit;
}
