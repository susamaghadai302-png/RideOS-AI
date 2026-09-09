import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';

class VehicleCompatibilityDetailsModal extends StatelessWidget {
  final String vehicleName;
  final String manufacturer;
  final String year;
  final VehicleVariant? variant;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibilityLevel;

  const VehicleCompatibilityDetailsModal({
    super.key,
    required this.vehicleName,
    required this.manufacturer,
    required this.year,
    this.variant,
    required this.capabilities,
    required this.compatibilityLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF080C1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: RoadOSColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$manufacturer $vehicleName',
                        style: const TextStyle(
                          color: RoadOSColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Model Year $year | ${variant?.variantName ?? "Standard Variant"}',
                        style: const TextStyle(
                          color: RoadOSColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCompatibilityBadge(compatibilityLevel),
              ],
            ),
            const Divider(color: RoadOSColors.borderTranslucent, height: 32),
            const Text(
              'DETECTED CAPABILITIES & SENSORS',
              style: TextStyle(
                color: RoadOSColors.electricBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildCapabilityRow('Real-time Speed (km/h)', capabilities.speed),
            _buildCapabilityRow('Engine RPM & Tachometer', capabilities.rpm),
            _buildCapabilityRow('Battery Voltage & Health', capabilities.batteryVoltage),
            _buildCapabilityRow('Fuel / EV State of Charge', capabilities.fuelLevel != CapabilitySupportLevel.notSupported ? capabilities.fuelLevel : capabilities.batteryLevel),
            _buildCapabilityRow('Engine / Motor Temperature', capabilities.engineTemperature),
            _buildCapabilityRow('Odometer & Trip Distances', capabilities.odometer),
            _buildCapabilityRow('ABS & Traction Control Status', capabilities.absStatus),
            _buildCapabilityRow('OBD-II Diagnostic Codes (DTC)', capabilities.diagnosticCodes),
            _buildCapabilityRow('Smart Display Turn-by-Turn HUD', capabilities.navigationData),
            _buildCapabilityRow('Caller ID & Notification Mirror', capabilities.smartDisplayData),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityBadge(VehicleCompatibilityLevel level) {
    Color color;
    String label;
    switch (level) {
      case VehicleCompatibilityLevel.full:
        color = RoadOSColors.apexEmerald;
        label = 'FULL COMPATIBILITY';
        break;
      case VehicleCompatibilityLevel.partial:
        color = RoadOSColors.warningAmber;
        label = 'PARTIAL COMPATIBILITY';
        break;
      case VehicleCompatibilityLevel.diagnosticOnly:
        color = RoadOSColors.electricBlue;
        label = 'DIAGNOSTIC ONLY';
        break;
      case VehicleCompatibilityLevel.displayOnly:
        color = RoadOSColors.neonViolet;
        label = 'DISPLAY ONLY';
        break;
      case VehicleCompatibilityLevel.gatewayRequired:
        color = Colors.orange;
        label = 'GATEWAY REQUIRED';
        break;
      case VehicleCompatibilityLevel.telematicsOnly:
        color = Colors.teal;
        label = 'TELEMATICS ONLY';
        break;
      case VehicleCompatibilityLevel.notSupported:
        color = RoadOSColors.errorCrimson;
        label = 'NOT SUPPORTED';
        break;
      default:
        color = RoadOSColors.textMuted;
        label = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCapabilityRow(String title, CapabilitySupportLevel support) {
    IconData icon;
    Color color;
    String text;

    switch (support) {
      case CapabilitySupportLevel.supported:
      case CapabilitySupportLevel.readOnly:
      case CapabilitySupportLevel.readWrite:
        icon = Icons.check_circle_rounded;
        color = RoadOSColors.apexEmerald;
        text = support == CapabilitySupportLevel.readWrite ? 'Read / Write' : 'Supported';
        break;
      case CapabilitySupportLevel.notSupported:
        icon = Icons.cancel_rounded;
        color = RoadOSColors.errorCrimson;
        text = 'Unavailable';
        break;
      default:
        icon = Icons.help_outline_rounded;
        color = RoadOSColors.textMuted;
        text = 'Unknown';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13)),
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
