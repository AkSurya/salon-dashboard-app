import 'package:flutter/material.dart';
import 'dart:async';
import 'package:action_slider/action_slider.dart';
import 'dart:ui';

class EmergencyRequestScreen extends StatefulWidget {
  final String customerName;
  final String service;
  final String requestedTime;

  const EmergencyRequestScreen({
    super.key,
    required this.customerName,
    required this.service,
    required this.requestedTime,
  });

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _timerProgress = 1.0; // Starts full
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();

    // 1. Rhythmic Pulse for background
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // 2. 30-Second Countdown logic
    _startTimer();
  }

  void _startTimer() {
    const totalSeconds = 30;
    int remaining = totalSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining > 0) {
        setState(() {
          remaining--;
          _timerProgress = remaining / totalSeconds;
        });
      } else {
        _countdownTimer.cancel();
        Navigator.pop(context, "EXPIRED");
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.teal.withOpacity(0.2 * _pulseController.value),
                  Colors.black,
                ],
                radius: 1.5,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Adds the "Glass" feel
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _buildEmergencyUI(),
              ),
            ),
          );
        },
        child: _buildEmergencyUI(),
      ),
    );
  }

  Widget _buildEmergencyUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const Spacer(),

          // The Beacon with Countdown Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: _timerProgress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timerProgress < 0.3 ? Colors.orange : Colors.teal,
                  ),
                ),
              ),
              _buildClientInfoCircle(),
            ],
          ),

          const Spacer(),

          const Text("OFFER DELAY IF BUSY:",
              style: TextStyle(color: Colors.white30, letterSpacing: 2, fontSize: 10)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDelayChip("10m"),
              const SizedBox(width: 20),
              _buildDelayChip("20m"),
            ],
          ),

          const SizedBox(height: 60),

          // Master Action: Swipe to Accept
          ActionSlider.standard(
            width: double.infinity,
            child: const Text("SWIPE TO ACCEPT NOW",
                style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 12)),
            action: (controller) async {
              controller.loading();
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) Navigator.pop(context, "NOW");
            },
            backgroundColor: Colors.white.withOpacity(0.05),
            toggleColor: Colors.teal,
            direction: TextDirection.ltr,
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () => Navigator.pop(context, "REJECTED"),
            child: Text("DECLINE", style: TextStyle(color: Colors.red.withOpacity(0.5), letterSpacing: 2)),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildClientInfoCircle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.customerName.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w200, letterSpacing: 8),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.toUpperCase(),
          style: TextStyle(color: Colors.teal.withOpacity(0.8), fontSize: 12, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildDelayChip(String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }
}