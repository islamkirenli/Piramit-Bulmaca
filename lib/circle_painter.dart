import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pyramid_puzzle/global_properties.dart';

class CirclePainterWidget extends StatefulWidget {
  final double initialSides;
  final double size;
  final Color color;
  final List<String> letters; // Gösterilecek harfler
  final List<int> selectedIndexes; // Seçilen harflerin indeksleri
  final List<Offset> linePoints;
  final Offset? temporaryLineEnd;
  final Animation<double> letterShuffleAnimation; // Harf animasyonu

  const CirclePainterWidget({
    Key? key,
    this.initialSides = 7.0,
    this.size = 200,
    this.color = Colors.blue,
    required this.letters,
    required this.selectedIndexes,
    required this.linePoints,
    this.temporaryLineEnd,
    required this.letterShuffleAnimation,
  }) : super(key: key);

  @override
  CirclePainterWidgetState createState() => CirclePainterWidgetState();
}

class CirclePainterWidgetState extends State<CirclePainterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sidesAnimation;
  late double _currentSides;

  @override
  void initState() {
    super.initState();
    _currentSides = widget.initialSides;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sidesAnimation = Tween<double>(
      begin: _currentSides,
      end: _currentSides,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  /// Kenar sayısını azaltma işlemi, dışarıdan tetiklenebilir hale getirildi.
  void reduceSides() {
    if (_currentSides > 3) {
      setState(() {
        _currentSides--; // Kenar sayısını azalt
        _sidesAnimation = Tween<double>(
          begin: _sidesAnimation.value, // Mevcut değer
          end: _currentSides,          // Yeni değer
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      });
      _controller.forward(from: 0); // Animasyonu yeniden başlat
    }
  }

  void setSides(double newSides) {
    setState(() {
      _currentSides = newSides;
      _sidesAnimation = Tween<double>(
        begin: _sidesAnimation.value,
        end: _currentSides,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sidesAnimation, // Kenar sayısı animasyonunu dinleyen yapı
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PolygonPainter(
            sides: _sidesAnimation.value, // Güncel kenar sayısı
            color: widget.color,
            letters: widget.letters,
            selectedIndexes: widget.selectedIndexes,
            linePoints: widget.linePoints,
            temporaryLineEnd: widget.temporaryLineEnd,
            letterShuffleAnimation: widget.letterShuffleAnimation, // Animasyonu aktarıyoruz
          ),
        );
      },
    );
  }
}

class PolygonPainter extends CustomPainter {
  final double sides;
  final Color color;
  final List<String> letters; // Gösterilecek harfler
  final List<int> selectedIndexes; // Seçilen harflerin indeksleri
  final List<Offset> linePoints;
  final Offset? temporaryLineEnd;
  final Animation<double> letterShuffleAnimation; // Harf animasyonu

  PolygonPainter({
    required this.sides,
    required this.color,
    required this.letters,
    required this.selectedIndexes,
    required this.linePoints,
    this.temporaryLineEnd,
    required this.letterShuffleAnimation,
  }) : super(repaint: letterShuffleAnimation); // Animasyon değişince yeniden boyama

  @override
  void paint(Canvas canvas, Size size) {
    // Dairenin dolgu rengi için Paint
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // Daireyi dolgu rengiyle çiziyoruz
    canvas.drawCircle(center, radius, paint);

    // Daireye kenar çizgisi eklemek için yeni bir Paint nesnesi oluşturuyoruz
    final Paint borderPaint = Paint()
      ..color = Colors.black   // Kenar çizgilerinin rengi
      ..strokeWidth = 2.0      // Kenar çizgilerinin kalınlığı
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // Harfler arası çizgiler için Paint
    final Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Çemberlerin yarıçapı
    final double circleRadius = 20.0;

    // Harfler arası çizgiler
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

    // Seçilen harfler için çemberleri çiziyoruz
    final Paint circlePaintFill = Paint()
      ..color = const Color.fromARGB(255, 39, 225, 45)
      ..style = PaintingStyle.fill;

    final Paint circlePaintStroke = Paint()
      ..color = const Color.fromARGB(255, 44, 78, 61)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < linePoints.length; i++) {
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintFill);
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintStroke);
    }

    // Harfleri yerleştirmek için TextPainter
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    // Harflerin yerleştirileceği yarıçap: Dairenin kenarından 30px içeride
    final double letterRadius = radius - 30;

    for (int i = 0; i < sides; i++) {
      final double angle = -pi / 2 + (2 * pi / letters.length) * i;
      final double dx = center.dx + letterRadius * cos(angle);
      final double dy = center.dy + letterRadius * sin(angle);
      final Offset letterPosition = Offset(dx, dy);

      // Seçilen harfler için daire çizimi
      if (selectedIndexes.contains(i)) {
        final Paint circlePaint = Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(letterPosition, 25, circlePaint);
      }

      // Harf çizimi; animasyon ölçek değeri uygulanıyor:
      if (i < letters.length) {
        canvas.save();
        // Harfin merkezine gitmek için translate
        canvas.translate(letterPosition.dx, letterPosition.dy);
        // letterShuffleAnimation.value (0.0 -> 1.0) ölçek olarak uygulanıyor
        double scale = letterShuffleAnimation.value;
        canvas.scale(scale, scale);
        textPainter.text = TextSpan(
          text: letters[i],
          style: GlobalProperties.globalTextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        // (0,0) harfin merkezi kabul edilerek offset hesaplanıyor
        final Offset offset = Offset(-textPainter.width / 2, -textPainter.height / 2);
        textPainter.paint(canvas, offset);
        canvas.restore();
      }
    }
  }

  Offset _getCircleEdge(Offset center, Offset target, double radius) {
    final vector = target - center;
    final normalized = vector / vector.distance;
    return center + normalized * radius;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
