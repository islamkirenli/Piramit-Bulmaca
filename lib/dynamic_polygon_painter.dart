import 'dart:math';
import 'package:flutter/material.dart';

class DynamicPolygonPainter extends CustomPainter {
  final List<String> letters;
  final List<Offset> linePoints;
  final Offset? temporaryLineEnd;
  final Color polygonFillColor;
  final Color polygonStrokeColor;
  final double polygonStrokeWidth;
  final double animationProgress; // Animasyon ilerleme değeri (0.0 - 1.0 arasında)

  DynamicPolygonPainter({
    required this.letters,
    required this.linePoints,
    this.temporaryLineEnd,
    required this.polygonFillColor,
    required this.polygonStrokeColor,
    this.polygonStrokeWidth = 2.0,
    this.animationProgress = 1.0, // Varsayılan olarak animasyon tamamlanmış
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 * animationProgress; // Animasyona göre yarıçap

    // Çokgen köşelerini hesaplayın
    final points = List.generate(
      letters.length,
      (i) {
        final angle = -pi / 2 + (2 * pi / letters.length) * i;
        final dx = center.dx + radius * cos(angle);
        final dy = center.dy + radius * sin(angle);
        return Offset(dx, dy);
      },
    );

    // Çokgen dolgusunu çizin
    final fillPaint = Paint()
      ..color = polygonFillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addPolygon(points, true), fillPaint);

    // Çokgen kenar çizgisini çizin
    final strokePaint = Paint()
      ..color = polygonStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = polygonStrokeWidth;
    canvas.drawPath(Path()..addPolygon(points, true), strokePaint);

    // Çizgi boyama için
    final linePaint = Paint()
      ..color = polygonStrokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Çemberlerin yarıçapı
    final circleRadius = 20.0 * animationProgress; // Animasyona göre çember boyutu

    // Çizilen harfler arasındaki çizgiler
    for (int i = 0; i < linePoints.length - 1; i++) {
      final start = _getCircleEdge(linePoints[i], linePoints[i + 1], circleRadius);
      final end = _getCircleEdge(linePoints[i + 1], linePoints[i], circleRadius);
      canvas.drawLine(start, end, linePaint);
    }

    // Geçici çizgi
    if (linePoints.isNotEmpty && temporaryLineEnd != null) {
      final start = _getCircleEdge(linePoints.last, temporaryLineEnd!, circleRadius);
      canvas.drawLine(start, temporaryLineEnd!, linePaint);
    }

    // Seçilen harfler için çemberleri çiz
    final circlePaintFill = Paint()
      ..color = polygonStrokeColor // Çokgenin dolgu rengi
      ..style = PaintingStyle.fill;

    final circlePaintStroke = Paint()
      ..color = polygonStrokeColor // Çokgenin kenar rengi
      ..style = PaintingStyle.stroke
      ..strokeWidth = polygonStrokeWidth;

    for (int i = 0; i < linePoints.length; i++) {
      // Çemberi doldur
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintFill);
      // Çemberin kenarını çiz
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintStroke);
    }

    // Harfleri çiz
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Harfleri köşelere dinamik olarak yerleştir
    for (int i = 0; i < letters.length; i++) {
      final adjustmentFactor = 0.7;
      final dx = center.dx + (radius * adjustmentFactor) * cos(-pi / 2 + (2 * pi / letters.length) * i);
      final dy = center.dy + (radius * adjustmentFactor) * sin(-pi / 2 + (2 * pi / letters.length) * i);

      final letterPosition = Offset(dx, dy);

      // Harfleri köşelere yerleştir
      textPainter.text = TextSpan(
        text: letters[i].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 35 * animationProgress, // Animasyona göre yazı boyutu
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();
      final offset = Offset(
        letterPosition.dx - textPainter.width / 2,
        letterPosition.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  Offset _getCircleEdge(Offset center, Offset target, double radius) {
    final vector = target - center;
    final normalized = vector / vector.distance;
    return center + normalized * radius;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

