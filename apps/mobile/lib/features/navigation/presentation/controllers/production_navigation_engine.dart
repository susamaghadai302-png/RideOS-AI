import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

enum MapProviderType {
  googleMaps,
  mapbox,
  openStreetMap,
  hereMaps,
  tomTom,
}

class NavigationInstructionStep {
  final String instructionText;
  final double distanceToNextTurnMeters;
  final IconData turnIcon;
  final String targetStreetName;

  const NavigationInstructionStep({
    required this.instructionText,
    required this.distanceToNextTurnMeters,
    required this.turnIcon,
    required this.targetStreetName,
  });
}

class FloatingNavigationHudWidget extends StatelessWidget {
  final String currentSpeedKmh;
  final String upcomingInstruction;
  final String distanceToTurn;
  final IconData turnIcon;

  const FloatingNavigationHudWidget({
    super.key,
    required this.currentSpeedKmh,
    required this.upcomingInstruction,
    required this.distanceToTurn,
    required this.turnIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0x3A05080C),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0x4400E5FF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6D00),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(turnIcon, color: Colors.white, size: 28.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  upcomingInstruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  distanceToTurn,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentSpeedKmh,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'KM/H',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductionNavigationEngine {
  static final ProductionNavigationEngine instance = ProductionNavigationEngine._internal();
  ProductionNavigationEngine._internal();

  final _navigationStreamController = StreamController<NavigationInstructionStep>.broadcast();

  Stream<NavigationInstructionStep> get navigationStream => _navigationStreamController.stream;

  void startActiveTurnByTurn({
    required MapProviderType mapProvider,
    required String destination,
  }) {
    developer.log('Starting active turn-by-turn navigation via [$mapProvider] to [$destination]...', name: 'RideOS.NavigationEngine');
    _navigationStreamController.add(
      const NavigationInstructionStep(
        instructionText: 'In 300 meters, turn right onto Canyon Crest Road',
        distanceToNextTurnMeters: 300.0,
        turnIcon: Icons.turn_right_rounded,
        targetStreetName: 'Canyon Crest Road',
      ),
    );
  }

  void dispose() {
    _navigationStreamController.close();
  }
}
