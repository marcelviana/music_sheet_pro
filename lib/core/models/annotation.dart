import 'dart:ui';

class PdfAnnotation {
  final String id;
  final String contentId;
  final int pageNumber;
  final double xPosition;
  final double yPosition;
  final String text;
  final int colorValue;
  final DateTime createdAt;

  PdfAnnotation({
    required this.id,
    required this.contentId,
    required this.pageNumber,
    required this.xPosition,
    required this.yPosition,
    required this.text,
    required this.colorValue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Métodos auxiliares para cor
  Color get color => Color(colorValue);

  // Posição como Offset para UI
  Offset get position => Offset(xPosition, yPosition);

  // Conversão para/do Map para banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentId': contentId,
      'pageNumber': pageNumber,
      'xPosition': xPosition,
      'yPosition': yPosition,
      'text': text,
      'colorValue': colorValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PdfAnnotation.fromMap(Map<String, dynamic> map) {
    return PdfAnnotation(
      id: map['id'],
      contentId: map['contentId'],
      pageNumber: map['pageNumber'],
      xPosition: map['xPosition'],
      yPosition: map['yPosition'],
      text: map['text'],
      colorValue: map['colorValue'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Criar cópia com alterações
  PdfAnnotation copyWith({
    String? id,
    String? contentId,
    int? pageNumber,
    double? xPosition,
    double? yPosition,
    String? text,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      pageNumber: pageNumber ?? this.pageNumber,
      xPosition: xPosition ?? this.xPosition,
      yPosition: yPosition ?? this.yPosition,
      text: text ?? this.text,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
