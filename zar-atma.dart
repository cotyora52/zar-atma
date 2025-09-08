import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DicePage(),
    );
  }
}

class DicePage extends StatefulWidget {
  @override
  _DicePageState createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  final Random _random = Random();
  int _diceCount = 2; // başlangıçta 2 zar
  int _dice1 = 1;
  int _dice2 = 1;

  void _rollDice() {
    setState(() {
      _dice1 = _random.nextInt(6) + 1;
      _dice2 = _random.nextInt(6) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _rollDice,
        onDoubleTap: _rollDice,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: DicePainter(_dice1),
                    child: Container(),
                  ),
                ),
                if (_diceCount == 2)
                  Expanded(
                    child: CustomPaint(
                      painter: DicePainter(_dice2),
                      child: Container(),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.white,  // beyaz arka plan
                foregroundColor: Colors.grey[800], // ikon rengi gri
                child: const Icon(Icons.settings),
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white, // seçenek ekranı beyaz
                    context: context,
                    builder: (context) {
                      return SizedBox(
                        height: 150,
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text(
                                "1 Zar",
                                style: TextStyle(color: Colors.grey), // gri yazı
                              ),
                              onTap: () {
                                setState(() {
                                  _diceCount = 1;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text(
                                "2 Zar",
                                style: TextStyle(color: Colors.grey), // gri yazı
                              ),
                              onTap: () {
                                setState(() {
                                  _diceCount = 2;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DicePainter extends CustomPainter {
  final int number;
  DicePainter(this.number);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundColor = _getDiceColor(number);

    // Arka plan
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    // Nokta rengi -> arka planın biraz açık tonu
    final hsl = HSLColor.fromColor(backgroundColor);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
        .toColor();

    final dotPaint = Paint()
      ..color = lighter
      ..style = PaintingStyle.fill;

    // Nokta yarıçapı → ekran kısa kenarının 1/18'i
    final double r = size.shortestSide / 18;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Kare içine yerleştirme
    final double squareOffsetX = size.width / 6;
    final double squareOffsetY = size.height / 6;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }

    switch (number) {
      case 1:
        drawDot(cx, cy);
        break;
      case 2:
        drawDot(cx - squareOffsetX, cy - squareOffsetY);
        drawDot(cx + squareOffsetX, cy + squareOffsetY);
        break;
      case 3:
        drawDot(cx - squareOffsetX, cy - squareOffsetY);
        drawDot(cx, cy);
        drawDot(cx + squareOffsetX, cy + squareOffsetY);
        break;
      case 4:
        drawDot(cx - squareOffsetX, cy - squareOffsetY);
        drawDot(cx + squareOffsetX, cy - squareOffsetY);
        drawDot(cx - squareOffsetX, cy + squareOffsetY);
        drawDot(cx + squareOffsetX, cy + squareOffsetY);
        break;
      case 5:
        drawDot(cx - squareOffsetX, cy - squareOffsetY);
        drawDot(cx + squareOffsetX, cy - squareOffsetY);
        drawDot(cx, cy);
        drawDot(cx - squareOffsetX, cy + squareOffsetY);
        drawDot(cx + squareOffsetX, cy + squareOffsetY);
        break;
      case 6:
        for (int i = -1; i <= 1; i++) {
          drawDot(cx - squareOffsetX, cy + i * squareOffsetY);
          drawDot(cx + squareOffsetX, cy + i * squareOffsetY);
        }
        break;
    }
  }

  Color _getDiceColor(int number) {
    switch (number) {
      case 1:
        return const Color(0xFFE53935); // Warm Red
      case 2:
        return const Color(0xFFFFB300); // Bright Yellow
      case 3:
        return const Color(0xFF1565C0); // Deep Blue
      case 4:
        return const Color(0xFFFB8C00); // Vibrant Orange
      case 5:
        return const Color(0xFF2E7D32); // Emerald Green
      case 6:
        return const Color(0xFF9575CD); // Lilac
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
