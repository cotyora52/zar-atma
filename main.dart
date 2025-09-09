import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  const DicePage({super.key});

  @override
  State<DicePage> createState() => DicePageState();
}

class DicePageState extends State<DicePage> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final AudioPlayer _player = AudioPlayer();
  int _diceCount = 2;
  int _dice1 = 1;
  int _dice2 = 1;

  late AnimationController _controller;

  // Shake detection
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  final double shakeThreshold = 15.0;

  // Toplamı gösterme ayarı
  bool _showTotal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // shake.mp3 süresi
    );

    accelerometerEventStream().listen((AccelerometerEvent event) {
      double deltaX = (event.x - _lastX).abs();
      double deltaY = (event.y - _lastY).abs();
      double deltaZ = (event.z - _lastZ).abs();

      if (deltaX + deltaY + deltaZ > shakeThreshold) {
        _rollDice();
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  void _rollDice() async {
    _player.play(AssetSource('sounds/shake.mp3'));
    _controller.forward(from: 0);

    int finalDice1 = _random.nextInt(6) + 1;
    int finalDice2 = _random.nextInt(6) + 1;

    int elapsed = 0;
    const interval = 50; // her 50ms rastgele sayı
    Timer.periodic(const Duration(milliseconds: interval), (timer) {
      elapsed += interval;
      if (elapsed >= 1500) {
        timer.cancel();
        setState(() {
          _dice1 = finalDice1;
          if (_diceCount == 2) _dice2 = finalDice2;
        });
        _player.play(AssetSource('sounds/dice_hit.mp3'));
      } else {
        setState(() {
          _dice1 = _random.nextInt(6) + 1;
          if (_diceCount == 2) _dice2 = _random.nextInt(6) + 1;
        });
      }
    });
  }

  void _selectDiceCount(int count) {
    setState(() {
      _diceCount = count;
      if (count == 1) _dice2 = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Zar Sayısı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ListTile(
                title: const Text('1 Zar', style: TextStyle(color: Colors.black)),
                onTap: () {
                  _selectDiceCount(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('2 Zar', style: TextStyle(color: Colors.black)),
                onTap: () {
                  _selectDiceCount(2);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Toplamı Göster', style: TextStyle(color: Colors.black)),
                value: _showTotal,
                onChanged: (value) {
                  setModalState(() {
                    _showTotal = value;
                  });
                  setState(() {
                    _showTotal = value;
                  });
                },
              ),
              const Divider(),
              const ListTile(
                title: Text('Uygulama Bilgileri', style: TextStyle(color: Colors.black)),
                subtitle: Text('Tasarım: Cotyora', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDice(int number, bool invert) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = sin(_controller.value * pi * 10) * 10;
        return Transform.translate(
          offset: Offset(invert ? -offset : offset, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: DicePainter(number),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = _dice1 + ( _diceCount == 2 ? _dice2 : 0);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _rollDice,
              onDoubleTap: _rollDice,
              child: Column(
                children: [
                  Expanded(child: _buildDice(_dice1, false)),
                  if (_diceCount == 2)
                    Expanded(child: _buildDice(_dice2, true)),
                ],
              ),
            ),
            if (_showTotal)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSettings,
        backgroundColor: Colors.white,
        child: const Icon(Icons.settings, color: Colors.grey),
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

    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    final hsl = HSLColor.fromColor(backgroundColor);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
        .toColor();

    final dotPaint = Paint()
      ..color = lighter
      ..style = PaintingStyle.fill;

    final double r = size.shortestSide / 18;
    final cx = size.width / 2;
    final cy = size.height / 2;
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
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFFB300);
      case 3:
        return const Color(0xFF1565C0);
      case 4:
        return const Color(0xFFFB8C00);
      case 5:
        return const Color(0xFF2E7D32);
      case 6:
        return const Color(0xFF9575CD);
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) {
    return oldDelegate.number != number;
  }
}
