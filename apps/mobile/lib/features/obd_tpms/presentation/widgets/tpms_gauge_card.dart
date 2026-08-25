import 'package:flutter/material.dart';

class TpmsGaugeCard extends StatelessWidget {
  final double frontPsi;
  final double rearPsi;

  const TpmsGaugeCard({
    super.key,
    required this.frontPsi,
    required this.rearPsi,
  });

  @override
  Widget build(BuildContext context) {
    final frontLow = frontPsi < 28.0;
    final rearLow = rearPsi < 28.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: (frontLow || rearLow)
            ? const BorderSide(color: Colors.redAccent, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TIRE PRESSURE (TPMS)',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Icon(
                  (frontLow || rearLow) ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: (frontLow || rearLow) ? Colors.redAccent : const Color(0xFF00E676),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: frontLow ? const Color(0xFF450A0A) : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('FRONT TIRE', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '$frontPsi PSI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: frontLow ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rearLow ? const Color(0xFF450A0A) : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('REAR TIRE', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '$rearPsi PSI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: rearLow ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
