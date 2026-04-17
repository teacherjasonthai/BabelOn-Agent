import 'package:flutter/material.dart';

class ListenTimer extends StatefulWidget {
  final bool isListening;

  const ListenTimer({
    super.key,
    required this.isListening,
  });

  @override
  State<ListenTimer> createState() => _ListenTimerState();
}

class _ListenTimerState extends State<ListenTimer> {
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _startTimer();
  }

  void _startTimer() {
    if (widget.isListening && !_stopwatch.isRunning) {
      _stopwatch.start();
    } else if (!widget.isListening && _stopwatch.isRunning) {
      _stopwatch.stop();
    }
  }

  @override
  void didUpdateWidget(ListenTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        final elapsed = _stopwatch.elapsed;
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;
        final timeString =
            '$minutes:${seconds.toString().padLeft(2, '0')} secs';

        return Text(
          timeString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}
