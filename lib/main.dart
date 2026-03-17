import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        useMaterial3: true,
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
  static const int boardSize = 9;
  static const int roundTimeSeconds = 20;

  static const String highScoreKey = 'tap_tide_high_score';
  static const String soundEnabledKey = 'tap_tide_sound_enabled';
  static const String hapticsEnabledKey = 'tap_tide_haptics_enabled';

  final Random _random = Random();

  late List<int> numbers;

  int nextExpected = 1;
  int score = 0;
  int highScore = 0;
  int combo = 0;
  int bestCombo = 0;
  int wavesCleared = 0;
  int timeLeft = roundTimeSeconds;

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  bool gameOver = false;
  bool gameStarted = false;
  bool isCountingDown = false;

  String statusMessage = 'Tap start to begin';
  FeedbackBubble? feedbackBubble;
  int? countdownValue;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    numbers = List.generate(boardSize, (index) => index + 1)..shuffle(_random);
    _loadPreferences();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt(highScoreKey) ?? 0;
      soundEnabled = prefs.getBool(soundEnabledKey) ?? true;
      hapticsEnabled = prefs.getBool(hapticsEnabledKey) ?? true;
    });
  }

  Future<void> _setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundEnabledKey, value);
    setState(() {
      soundEnabled = value;
    });
  }

  Future<void> _setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hapticsEnabledKey, value);
    setState(() {
      hapticsEnabled = value;
    });
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(highScoreKey, score);
      setState(() {
        highScore = score;
      });
    }
  }

  Future<void> _playCorrectFeedback() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> _playComboFeedback() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _playWaveCompleteFeedback() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _playGameOverFeedback() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _beginCountdownAndStart() async {
    _timer?.cancel();

    setState(() {
      numbers = List.generate(boardSize, (index) => index + 1)..shuffle(_random);
      nextExpected = 1;
      score = 0;
      combo = 0;
      bestCombo = 0;
      wavesCleared = 0;
      timeLeft = roundTimeSeconds;
      gameOver = false;
      gameStarted = false;
      isCountingDown = true;
      statusMessage = 'Get ready';
      feedbackBubble = null;
      countdownValue = 3;
    });

    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() {
        countdownValue = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setState(() {
      countdownValue = null;
      isCountingDown = false;
      gameStarted = true;
      statusMessage = 'Go! Tap 1';
    });

    _showFeedback(
      const FeedbackBubble(
        title: 'GO!',
        subtitle: 'Catch the wave',
        backgroundColor: Color(0xFFE0F7EC),
        borderColor: Color(0xFF2DC653),
        textColor: Color(0xFF123524),
      ),
    );

    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || gameOver || !gameStarted) {
        timer.cancel();
        return;
      }

      if (timeLeft <= 1) {
        timer.cancel();
        await _endGame('Wave crashed! Time’s up.');
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  Future<void> _endGame(String reason) async {
    _timer?.cancel();

    final bool isNewBest = score > highScore;

    setState(() {
      gameOver = true;
      gameStarted = false;
      isCountingDown = false;
      statusMessage = reason;
      countdownValue = null;
      feedbackBubble = null;
    });

    await _saveHighScoreIfNeeded();
    await _playGameOverFeedback();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Wave Crashed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B263B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (isNewBest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6D6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFFD60A), width: 2),
                    ),
                    child: const Text(
                      'New Best!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B263B),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Score',
                        value: '$score',
                        valueColor: const Color(0xFF0077B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Best',
                        value: '$highScore',
                        valueColor: const Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Waves',
                        value: '$wavesCleared',
                        valueColor: const Color(0xFF2DC653),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Best Combo',
                        value: 'x$bestCombo',
                        valueColor: const Color(0xFF1B263B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _beginCountdownAndStart();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reshuffleBoard() {
    setState(() {
      numbers.shuffle(_random);
    });
  }

  void _showFeedback(FeedbackBubble bubble) {
    setState(() {
      feedbackBubble = bubble;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (feedbackBubble == bubble) {
        setState(() {
          feedbackBubble = null;
        });
      }
    });
  }

  Future<void> _handleTap(int value) async {
    if (gameOver || !gameStarted || isCountingDown) return;

    if (value == nextExpected) {
      int pointsEarned = 1;
      final int updatedCombo = combo + 1;

      if (updatedCombo >= 3) {
        pointsEarned += updatedCombo ~/ 3;
      }

      setState(() {
        combo = updatedCombo;
        if (combo > bestCombo) {
          bestCombo = combo;
        }
        score += pointsEarned;
      });

      if (combo >= 3) {
        await _playComboFeedback();
      } else {
        await _playCorrectFeedback();
      }

      if (nextExpected == boardSize) {
        setState(() {
          wavesCleared++;
          statusMessage = 'Wave complete!';
          nextExpected = 1;
          combo += 2;
          if (combo > bestCombo) {
            bestCombo = combo;
          }
          score += 5;
          timeLeft = min(timeLeft + 3, roundTimeSeconds);
          numbers = List.generate(boardSize, (index) => index + 1)
            ..shuffle(_random);
        });

        _showFeedback(
          const FeedbackBubble(
            title: 'Wave Complete!',
            subtitle: '+5 Bonus  ·  +3s',
            backgroundColor: Color(0xFFFFF6D6),
            borderColor: Color(0xFFFFD60A),
            textColor: Color(0xFF1B263B),
          ),
        );

        await _playWaveCompleteFeedback();
      } else {
        setState(() {
          nextExpected++;
          statusMessage = 'Nice! Tap $nextExpected';
        });

        if (combo >= 2) {
          _showFeedback(
            FeedbackBubble(
              title: 'Combo x$combo',
              subtitle: '+$pointsEarned points',
              backgroundColor:
                  combo >= 5 ? const Color(0xFFE0F7EC) : const Color(0xFFEAF4FF),
              borderColor:
                  combo >= 5 ? const Color(0xFF2DC653) : const Color(0xFF0077B6),
              textColor: const Color(0xFF1B263B),
            ),
          );
        } else {
          _showFeedback(
            FeedbackBubble(
              title: '+$pointsEarned',
              subtitle: 'Good tap',
              backgroundColor: const Color(0xFFEAF4FF),
              borderColor: const Color(0xFF0077B6),
              textColor: const Color(0xFF1B263B),
            ),
          );
        }

        _reshuffleBoard();
      }
    } else {
      setState(() {
        combo = 0;
      });

      _showFeedback(
        const FeedbackBubble(
          title: 'Combo Lost',
          subtitle: 'Wrong tile',
          backgroundColor: Color(0xFFFFE4E4),
          borderColor: Color(0xFFE53935),
          textColor: Color(0xFF5C1A1A),
        ),
      );

      await _endGame('Wrong tile!');
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> updateSound(bool value) async {
              await _setSoundEnabled(value);
              if (context.mounted) {
                setModalState(() {});
              }
            }

            Future<void> updateHaptics(bool value) async {
              await _setHapticsEnabled(value);
              if (context.mounted) {
                setModalState(() {});
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B263B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('System tap and alert sounds'),
                      value: soundEnabled,
                      onChanged: updateSound,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Vibration / Haptics',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Touch feedback for taps and misses'),
                      value: hapticsEnabled,
                      onChanged: updateHaptics,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _tileColor(int value) {
    if (!gameStarted && !isCountingDown) {
      return const Color(0xFF0077B6);
    }

    if (value < nextExpected && gameStarted) {
      return const Color(0xFF2DC653);
    }

    if (value == nextExpected && gameStarted) {
      return const Color(0xFFFF6B35);
    }

    return const Color(0xFF0077B6);
  }

  double _tileScale(int value) {
    if (gameStarted && value == nextExpected) {
      return 1.04;
    }
    return 1.0;
  }

  List<BoxShadow> _tileShadow(int value) {
    if (gameStarted && value == nextExpected) {
      return const [
        BoxShadow(
          color: Color(0x55FF6B35),
          blurRadius: 16,
          spreadRadius: 2,
          offset: Offset(0, 6),
        ),
      ];
    }

    return const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Tide'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _TopPanel(
                    score: score,
                    highScore: highScore,
                    combo: combo,
                    nextExpected: nextExpected,
                    timeLeft: timeLeft,
                    statusMessage: statusMessage,
                    gameStarted: gameStarted,
                    isCountingDown: isCountingDown,
                    wavesCleared: wavesCleared,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -26,
                    child: Center(
                      child: IgnorePointer(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.25),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: feedbackBubble == null
                              ? const SizedBox(key: ValueKey('empty-bubble'))
                              : _FeedbackBubbleWidget(
                                  key: ValueKey(
                                    '${feedbackBubble!.title}-${feedbackBubble!.subtitle}',
                                  ),
                                  bubble: feedbackBubble!,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 38),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GridView.builder(
                      itemCount: numbers.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final value = numbers[index];
                        final isTapped = gameStarted && value < nextExpected;

                        return GestureDetector(
                          onTap: () => _handleTap(value),
                          child: AnimatedScale(
                            scale: _tileScale(value),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: _tileColor(value),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _tileShadow(value),
                                border: value == nextExpected && gameStarted
                                    ? Border.all(
                                        color: const Color(0xFFFFD60A),
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: isTapped ? 0.35 : 1,
                                  duration: const Duration(milliseconds: 150),
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
                            ),
                          ),
                        );
                      },
                    ),
                    if (isCountingDown && countdownValue != null)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$countdownValue',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0077B6),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCountingDown ? null : _beginCountdownAndStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD60A),
                    foregroundColor: const Color(0xFF1B263B),
                    disabledBackgroundColor: Colors.black12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    gameStarted
                        ? 'Restart Game'
                        : isCountingDown
                            ? 'Starting...'
                            : 'Start Game',
                    style: const TextStyle(
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
  final int highScore;
  final int combo;
  final int nextExpected;
  final int timeLeft;
  final String statusMessage;
  final bool gameStarted;
  final bool isCountingDown;
  final int wavesCleared;

  const _TopPanel({
    required this.score,
    required this.highScore,
    required this.combo,
    required this.nextExpected,
    required this.timeLeft,
    required this.statusMessage,
    required this.gameStarted,
    required this.isCountingDown,
    required this.wavesCleared,
  });

  Color _comboColor() {
    if (combo >= 5) return const Color(0xFF2DC653);
    if (combo >= 2) return const Color(0xFFFF6B35);
    return const Color(0xFF0077B6);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
              _InfoChip(label: 'Best', value: '$highScore'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoChip(
                label: 'Next',
                value: gameStarted ? '$nextExpected' : '-',
              ),
              _InfoChip(label: 'Time', value: '${timeLeft}s'),
              _InfoChip(
                label: 'Combo',
                value: '$combo',
                valueColor: _comboColor(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniWaveBadge(wavesCleared: wavesCleared),
          const SizedBox(height: 12),
          Text(
            isCountingDown ? 'Get ready...' : statusMessage,
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
  final Color valueColor;

  const _InfoChip({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF0077B6),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          child: Text(value),
        ),
      ],
    );
  }
}

class _MiniWaveBadge extends StatelessWidget {
  final int wavesCleared;

  const _MiniWaveBadge({required this.wavesCleared});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF0077B6), width: 1.5),
      ),
      child: Text(
        'Waves Cleared: $wavesCleared',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B263B),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackBubble {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const FeedbackBubble({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _FeedbackBubbleWidget extends StatelessWidget {
  final FeedbackBubble bubble;

  const _FeedbackBubbleWidget({
    super.key,
    required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bubble.backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bubble.borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bubble.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: bubble.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bubble.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: bubble.textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}