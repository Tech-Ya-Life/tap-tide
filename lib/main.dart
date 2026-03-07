import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TapTideApp());
}

class TapTideApp extends StatelessWidget {
  const TapTideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Tide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const TapTideHomePage(),
    );
  }
}

class TapTideHomePage extends StatefulWidget {
  const TapTideHomePage({super.key});

  @override
  State<TapTideHomePage> createState() => _TapTideHomePageState();
}

class _TapTideHomePageState extends State<TapTideHomePage> {
  late List<int> numbers;
  int nextExpected = 1;
  int score = 0;
  bool gameOver = false;
  String statusMessage = 'Tap 1 to begin';

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    numbers = List.generate(9, (index) => index + 1);
    numbers.shuffle(Random());
    nextExpected = 1;
    score = 0;
    gameOver = false;
    statusMessage = 'Tap 1 to begin';
    setState(() {});
  }

  void _handleTap(int value) {
    if (gameOver) return;

    if (value == nextExpected) {
      if (nextExpected == 9) {
        setState(() {
          score += 10;
          statusMessage = 'You cleared the board!';
          gameOver = true;
        });
      } else {
        setState(() {
          score += 1;
          nextExpected++;
          statusMessage = 'Good! Tap $nextExpected';
        });
      }
    } else {
      setState(() {
        statusMessage = 'Wrong tile. Game over.';
        gameOver = true;
      });
    }
  }

  Color _tileColor(int value) {
    if (gameOver && value == nextExpected) {
      return const Color(0xFFFF6B35);
    }
    if (value < nextExpected) {
      return const Color(0xFF2DC653);
    }
    return const Color(0xFF0077B6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Tide'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TopPanel(
                score: score,
                nextExpected: nextExpected,
                gameOver: gameOver,
                statusMessage: statusMessage,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: numbers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final value = numbers[index];
                    return GestureDetector(
                      onTap: () => _handleTap(value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _tileColor(value),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startNewGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD60A),
                    foregroundColor: const Color(0xFF1B263B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Restart Game',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopPanel extends StatelessWidget {
  final int score;
  final int nextExpected;
  final bool gameOver;
  final String statusMessage;

  const _TopPanel({
    required this.score,
    required this.nextExpected,
    required this.gameOver,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoChip(label: 'Score', value: '$score'),
              _InfoChip(
                label: 'Next',
                value: gameOver ? '-' : '$nextExpected',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B263B),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0077B6),
          ),
        ),
      ],
    );
  }
}