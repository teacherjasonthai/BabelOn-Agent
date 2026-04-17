import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

class AudioWaveform extends StatefulWidget {
  final bool isListening;

  const AudioWaveform({
    super.key,
    required this.isListening,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.isListening) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!widget.isListening && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          7,
          (index) => AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final baseHeight = 20.0 + (index - 3).abs() * 8.0;
              final animationValue = _animationController.value;
              final offset = (animationValue * 2 * 3.14159);
              final height = baseHeight +
                  (math.sin(offset + (index * 0.3)) * 15).abs();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 8,
                  height: height,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.primaryRed
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
