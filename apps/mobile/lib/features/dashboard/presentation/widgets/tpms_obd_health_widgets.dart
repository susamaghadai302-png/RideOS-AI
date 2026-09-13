import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';

class TpmsCardWidget extends StatelessWidget {
  final double? frontPsi;
  final double? rearPsi;
  final double targetFront;
  final double targetRear;

  const TpmsCardWidget({
    super.key,
    required this.frontPsi,
    required this.rearPsi,
    this.targetFront = 36.0,
    this.targetRear = 42.0,
  });

  @override
  Widget build(BuildContext context) {
    final frontNominal = frontPsi != null && (frontPsi! - targetFront).abs() <= 2.5;
    final rearNominal = rearPsi != null && (rearPsi! - targetRear).abs() <= 2.5;

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
                  color: (frontNominal && rearNominal) ? RoadOSColors.apexEmerald.withValues(alpha: 0.15) : RoadOSColors.errorCrimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (frontNominal && rearNominal) ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
                ),
                child: Text(
                  (frontPsi == null || rearPsi == null) ? 'UNAVAILABLE' : ((frontNominal && rearNominal) ? 'OPTIMAL' : 'CHECK PRESSURE'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: (frontPsi == null || rearPsi == null) ? RoadOSColors.textMuted : ((frontNominal && rearNominal) ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: frontNominal ? RoadOSColors.apexEmerald.withValues(alpha: 0.4) : RoadOSColors.errorCrimson),
                  ),
                  child: Column(
                    children: [
                      const Text('FRONT TIRE', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        frontPsi != null ? '${frontPsi!.toStringAsFixed(1)} PSI' : '-- PSI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: frontPsi == null ? RoadOSColors.textMuted : (frontNominal ? RoadOSColors.platinumWhite : RoadOSColors.errorCrimson),
                        ),
                      ),
                      Text('Target ${targetFront.round()} PSI | 32 degC', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rearNominal ? RoadOSColors.apexEmerald.withValues(alpha: 0.4) : RoadOSColors.errorCrimson),
                  ),
                  child: Column(
                    children: [
                      const Text('REAR TIRE', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        rearPsi != null ? '${rearPsi!.toStringAsFixed(1)} PSI' : '-- PSI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: rearPsi == null ? RoadOSColors.textMuted : (rearNominal ? RoadOSColors.platinumWhite : RoadOSColors.errorCrimson),
                        ),
                      ),
                      Text('Target ${targetRear.round()} PSI | 35 degC', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ObdStatusCardWidget extends StatelessWidget {
  final bool isConnected;
  final int faultCodeCount;
  final String protocol;
  final VoidCallback? onScanPressed;

  const ObdStatusCardWidget({
    super.key,
    this.isConnected = true,
    this.faultCodeCount = 0,
    this.protocol = 'CAN-BUS ISO 15765-4',
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
                      !isConnected 
                          ? 'UNAVAILABLE / DISCONNECTED' 
                          : (faultCodeCount == 0 ? 'NO ACTIVE DIAGNOSTICS' : '$faultCodeCount Active DTC Fault Codes!'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !isConnected ? RoadOSColors.textMuted : (faultCodeCount == 0 ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
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
              Expanded(child: _buildComponentBadge('Engine', healthScore != null ? '99%' : '--', RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Brakes', healthScore != null ? '97%' : '--', RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Tires', healthScore != null ? '95%' : '--', RoadOSColors.solarGold)),
              const SizedBox(width: 8),
              Expanded(child: _buildComponentBadge('Battery', healthScore != null ? '100%' : '--', RoadOSColors.apexEmerald)),
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
