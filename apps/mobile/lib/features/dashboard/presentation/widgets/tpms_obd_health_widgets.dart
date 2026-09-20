import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';

class TpmsCardWidget extends StatelessWidget {
  final List<double?> tirePressures;
  final List<String> tireLabels;
  final double? targetPressure;

  const TpmsCardWidget({
    super.key,
    required this.tirePressures,
    required this.tireLabels,
    this.targetPressure,
  });

  @override
  Widget build(BuildContext context) {
    bool allNominal = true;
    bool anyUnavailable = false;

    for (var psi in tirePressures) {
      if (psi == null || targetPressure == null) {
        anyUnavailable = true;
        allNominal = false;
        break;
      }
      if ((psi - targetPressure!).abs() > 2.5) {
        allNominal = false;
      }
    }

    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tire_repair_rounded, color: RoadOSColors.apexEmerald, size: 20),
                  SizedBox(width: 8),
                  Text('ANIMATED TPMS SENSORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: anyUnavailable ? RoadOSColors.textMuted.withValues(alpha: 0.15) : (allNominal ? RoadOSColors.apexEmerald.withValues(alpha: 0.15) : RoadOSColors.errorCrimson.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: anyUnavailable ? RoadOSColors.textMuted : (allNominal ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson)),
                ),
                child: Text(
                  anyUnavailable ? 'UNAVAILABLE' : (allNominal ? 'OPTIMAL' : 'CHECK PRESSURE'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: anyUnavailable ? RoadOSColors.textMuted : (allNominal ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(tirePressures.length, (index) {
              final psi = tirePressures[index];
              final isNominal = psi != null && targetPressure != null && (psi - targetPressure!).abs() <= 2.5;
              final label = tireLabels.length > index ? tireLabels[index] : 'TIRE ${index + 1}';
              return _buildTireWidget(label, psi, isNominal, targetPressure);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTireWidget(String label, double? psi, bool isNominal, double? target) {
    return Container(
      width: 140, // Fixed width for wrap layout
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: psi == null ? RoadOSColors.textMuted : (isNominal ? RoadOSColors.apexEmerald.withValues(alpha: 0.4) : RoadOSColors.errorCrimson)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            psi != null ? '${psi.toStringAsFixed(1)} PSI' : 'UNAVAILABLE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: psi == null ? RoadOSColors.textMuted : (isNominal ? RoadOSColors.platinumWhite : RoadOSColors.errorCrimson),
            ),
          ),
          Text(target != null ? 'Target ${target.round()} PSI' : 'Target UNAVAILABLE', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}

class ObdStatusCardWidget extends StatelessWidget {
  final bool isConnected;
  final int? faultCodeCount;
  final String protocol;
  final VoidCallback? onScanPressed;

  const ObdStatusCardWidget({
    super.key,
    this.isConnected = false,
    this.faultCodeCount,
    this.protocol = 'UNAVAILABLE',
    this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.memory_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text('OBD-II DIAGNOSTICS BUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected ? RoadOSColors.apexEmerald.withValues(alpha: 0.15) : RoadOSColors.errorCrimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isConnected ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'LINKED' : 'DISCONNECTED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE PROTOCOL: $protocol',
                      style: const TextStyle(fontSize: 10, color: RoadOSColors.starlightSilver, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !isConnected || faultCodeCount == null
                          ? 'UNAVAILABLE / DISCONNECTED' 
                          : (faultCodeCount == 0 ? 'NO ACTIVE DIAGNOSTICS' : '$faultCodeCount Active DTC Fault Codes!'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !isConnected || faultCodeCount == null ? RoadOSColors.textMuted : (faultCodeCount == 0 ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  if (onScanPressed != null) {
                    onScanPressed!();
                  } else {
                    showLuxSnack(context, 'Scanning OBD-II Diagnostic Bus (ISO 15765-4)...', variant: LuxSnackVariant.info);
                  }
                },
                icon: const Icon(Icons.analytics_outlined, size: 14),
                label: const Text('SCAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                  foregroundColor: RoadOSColors.cyberCyan,
                  elevation: 0,
                  side: const BorderSide(color: RoadOSColors.cyberCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiHealthScoreWidget extends StatelessWidget {
  final double? healthScore;

  const AiHealthScoreWidget({
    super.key,
    required this.healthScore,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('AI HEALTH SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text(
                healthScore != null ? '${healthScore!.round()}/100' : '--',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: RoadOSColors.hyperOrange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildComponentBadge('Engine', healthScore != null ? 'UNAVAILABLE' : '--', RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Brakes', healthScore != null ? 'UNAVAILABLE' : '--', RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Tires', healthScore != null ? 'UNAVAILABLE' : '--', RoadOSColors.solarGold)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Battery', healthScore != null ? 'UNAVAILABLE' : '--', RoadOSColors.apexEmerald)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
