import 'package:flutter/material.dart';

class WorkoutHeader extends StatelessWidget {
  final String title;
  final String time;
  final double progress;
  final VoidCallback onBack;

  const WorkoutHeader({
    super.key,
    required this.title,
    required this.time,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101820),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF233241)),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF00E5C3),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: const Color(0xFF111820),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E5C3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
