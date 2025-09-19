import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class QuizTimer extends StatefulWidget {
  final int totalTimeInMinutes;
  final VoidCallback? onTimeUp;
  final bool isPaused;
  final bool showWarning;

  const QuizTimer({
    super.key,
    required this.totalTimeInMinutes,
    this.onTimeUp,
    this.isPaused = false,
    this.showWarning = true,
  });

  @override
  State<QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<QuizTimer>
    with TickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  bool _isWarningShown = false;
  bool _isCriticalTime = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalTimeInMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(seconds: _totalSeconds),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _startTimer();
    _progressController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            _checkWarningTime();
          } else {
            _timer.cancel();
            widget.onTimeUp?.call();
          }
        });
      }
    });
  }

  void _checkWarningTime() {
    // Show warning when 5 minutes left
    if (_remainingSeconds <= 300 && !_isWarningShown && widget.showWarning) {
      _isWarningShown = true;
      _showTimeWarning();
    }

    // Critical time when 1 minute left
    if (_remainingSeconds <= 60 && !_isCriticalTime) {
      _isCriticalTime = true;
      _pulseController.repeat(reverse: true);
    }
  }

  void _showTimeWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.white,
              ),
              SizedBox(width: 8),
              Text('Waktu tersisa 5 menit!'),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final progress = _remainingSeconds / _totalSeconds;
    
    if (progress > 0.5) {
      return AppColors.success;
    } else if (progress > 0.2) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  IconData _getTimerIcon() {
    final progress = _remainingSeconds / _totalSeconds;
    
    if (progress > 0.5) {
      return Icons.timer;
    } else if (progress > 0.2) {
      return Icons.timer_outlined;
    } else {
      return Icons.timer_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isCriticalTime ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getTimerColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTimerColor(),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTimerIcon(),
                  color: _getTimerColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTimerColor(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CircularQuizTimer extends StatefulWidget {
  final int totalTimeInMinutes;
  final VoidCallback? onTimeUp;
  final bool isPaused;
  final double size;

  const CircularQuizTimer({
    super.key,
    required this.totalTimeInMinutes,
    this.onTimeUp,
    this.isPaused = false,
    this.size = 80,
  });

  @override
  State<CircularQuizTimer> createState() => _CircularQuizTimerState();
}

class _CircularQuizTimerState extends State<CircularQuizTimer>
    with TickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalTimeInMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            if (_remainingSeconds <= 60) {
              _rotationController.repeat();
            }
          } else {
            _timer.cancel();
            widget.onTimeUp?.call();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final progress = _remainingSeconds / _totalSeconds;
    
    if (progress > 0.5) {
      return AppColors.success;
    } else if (progress > 0.2) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / _totalSeconds;
    
    return RotationTransition(
      turns: _rotationController,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            // Background circle
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grey100,
              ),
            ),
            // Progress circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
              ),
            ),
            // Time text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: _getTimerColor(),
                    size: widget.size * 0.25,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: widget.size * 0.15,
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactQuizTimer extends StatefulWidget {
  final int totalTimeInMinutes;
  final VoidCallback? onTimeUp;
  final bool isPaused;

  const CompactQuizTimer({
    super.key,
    required this.totalTimeInMinutes,
    this.onTimeUp,
    this.isPaused = false,
  });

  @override
  State<CompactQuizTimer> createState() => _CompactQuizTimerState();
}

class _CompactQuizTimerState extends State<CompactQuizTimer> {
  late Timer _timer;
  late int _remainingSeconds;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalTimeInMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer.cancel();
            widget.onTimeUp?.call();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final progress = _remainingSeconds / _totalSeconds;
    
    if (progress > 0.5) {
      return AppColors.success;
    } else if (progress > 0.2) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTimerColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: _getTimerColor(),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(),
            ),
          ),
        ],
      ),
    );
  }
}