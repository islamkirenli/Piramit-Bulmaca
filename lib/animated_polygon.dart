import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedPolygonWidget extends StatefulWidget {
  final double initialSides;
  final double size;
  final Color color;
  final List<String> letters; // Gösterilecek harfler
  final List<int> selectedIndexes; // Seçilen harflerin indeksleri
  final List<Offset> linePoints;
  final Offset? temporaryLineEnd;

  const AnimatedPolygonWidget({
    Key? key,
    this.initialSides = 7.0,
    this.size = 200,
    this.color = Colors.blue,
    required this.letters, 
    required this.selectedIndexes, 
    required this.linePoints,
    this.temporaryLineEnd,
  }) : super(key: key);

  @override
  AnimatedPolygonWidgetState createState() => AnimatedPolygonWidgetState();
}

class AnimatedPolygonWidgetState extends State<AnimatedPolygonWidget>
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
      duration: const Duration(milliseconds: 500),
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
    print("reduce çağrıldı");
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
      animation: _sidesAnimation, // Animasyonu dinleyen yapı
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PolygonPainter(
            sides: _sidesAnimation.value, // Güncel kenar sayısı
            color: widget.color,          // Çokgenin rengi
            letters: widget.letters,
            selectedIndexes: widget.selectedIndexes,
            linePoints: widget.linePoints,
            temporaryLineEnd: widget.temporaryLineEnd,
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

  PolygonPainter({
    required this.sides,
    required this.color,
    required this.letters,
    required this.selectedIndexes,
    required this.linePoints,
    this.temporaryLineEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Çokgenin kenarlarını çizin
    for (int i = 0; i < sides; i++) {
      final double angle = (i * 2 * pi / sides) - (pi / 2);
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Çizgi boyama için
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Çemberlerin yarıçapı
    final circleRadius = 20.0;

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
      ..color = const Color.fromARGB(255, 39, 225, 45) // Çokgenin dolgu rengi
      ..style = PaintingStyle.fill;

    final circlePaintStroke = Paint()
      ..color = const Color.fromARGB(255, 44, 78, 61) // Çokgenin kenar rengi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < linePoints.length; i++) {
      // Çemberi doldur
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintFill);
      // Çemberin kenarını çiz
      canvas.drawCircle(linePoints[i], circleRadius, circlePaintStroke);
    }

    // Harfleri çizmek için her köşeye yerleştir
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    List<Offset> selectedPoints = []; // Seçilen noktaların pozisyonları

    for (int i = 0; i < sides; i++) {
      final adjustmentFactor = 0.7;
      final dx = center.dx + (radius * adjustmentFactor) * cos(-pi / 2 + (2 * pi / letters.length) * i);
      final dy = center.dy + (radius * adjustmentFactor) * sin(-pi / 2 + (2 * pi / letters.length) * i);
      final letterPosition = Offset(dx, dy);

      // Seçilen harfler için daire çiz
      if (selectedIndexes.contains(i)) {
        final Paint circlePaint = Paint()
          ..color = Colors.red.withOpacity(0.5) // Daire rengi
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(dx, dy), 25, circlePaint); // Dairenin boyutu
        selectedPoints.add(Offset(dx, dy)); // Seçilen noktanın pozisyonunu ekle
      }

      if (i < letters.length) { // Kelimenin harflerini sırayla çiz
        textPainter.text = TextSpan(
          text: letters[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
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