import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/safety_engine/models/safety_event_models.dart';
import '../../../../core/safety_engine/services/safety_event_engine.dart';

class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({super.key});

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen> {
  final _safetyEngine = SafetyEventEngine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.shield_rounded, color: RoadOSColors.apexEmerald, size: 20),
            SizedBox(width: 8),
            Text(
              'SAFETY & SOS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(
        child: StreamBuilder<CrashCountdownState>(
          stream: _safetyEngine.countdownStateStream,
          initialData: _safetyEngine.countdownState,
          builder: (context, snapshot) {
            final isCountdown = snapshot.data == CrashCountdownState.countdownActive;
            final isConfirmed = snapshot.data == CrashCountdownState.confirmedEmergency;
  
            return Stack(
              children: [
                ListView(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: MediaQuery.of(context).padding.top + 56),
                children: [
                  _buildSafetyStatusOverview(),
                  const SizedBox(height: 20),
                  _buildBigSosButton(),
                  const SizedBox(height: 20),
                  _buildSafetyScoreCard(),
                  const SizedBox(height: 20),
                  _buildEmergencyContactsSection(),
                  const SizedBox(height: 20),
                  _buildSafetyHistorySection(),
                  const SizedBox(height: 20),
                  _buildDeveloperTestModeSection(),
                ],
              ),
              if (isCountdown) _buildCountdownOverlay(),
              if (isConfirmed) _buildEmergencyConfirmedOverlay(),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildSafetyStatusOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: RoadOSColors.apexEmerald, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('STATUS: SAFE', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  SizedBox(height: 2),
                  Text('Multi-Signal Fallback & Crash Sentinel Active', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigSosButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.emergency_rounded, size: 28),
        label: const Text(
          'EMERGENCY SOS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _safetyEngine.triggerManualSos(),
      ),
    );
  }

  Widget _buildSafetyScoreCard() {
    final score = _safetyEngine.calculateRiderSafetyScore();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TRANSPARENT SAFETY SCORE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Text('${score.overallScore} / 100', style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...score.subScores.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
                    Text('${e.value}%', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(color: RoadOSColors.borderTranslucent, height: 20),
          const Text('Positive Riding Habits:', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...score.positiveFactors.map((f) => Text('| $f', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final contacts = _safetyEngine.emergencyContacts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EMERGENCY CONTACTS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: RoadOSColors.electricBlue, size: 20),
                onPressed: _showAddContactDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...contacts.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: RoadOSColors.electricBlue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${c.phoneNumber} (${c.relationship})', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    Switch(
                      value: c.isEnabled,
                      activeColor: RoadOSColors.apexEmerald,
                      onChanged: (val) {
                        setState(() {
                          _safetyEngine.toggleEmergencyContact(c.id, val);
                        });
                      },
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSafetyHistorySection() {
    final history = _safetyEngine.safetyHistory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SAFETY INCIDENT LOG', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Zero safety incidents recorded. Safe riding!', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
              ),
            )
          else
            ...history.take(5).map((evt) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        evt.isSimulated ? Icons.bug_report_rounded : Icons.warning_amber_rounded,
                        color: evt.severity == SafetySeverity.critical ? Colors.redAccent : RoadOSColors.warningAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (evt.isSimulated)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: RoadOSColors.neonViolet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                                    child: const Text('SIM', style: TextStyle(color: RoadOSColors.neonViolet, fontSize: 7, fontWeight: FontWeight.bold)),
                                  ),
                                Text(evt.description, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            Text('${evt.source} | ${evt.confidence.name.toUpperCase()} CONFIDENCE', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDeveloperTestModeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.neonViolet.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.science_rounded, color: RoadOSColors.neonViolet, size: 16),
              SizedBox(width: 8),
              Text(
                'SAFETY TEST MODE (BENCH SIMULATOR)',
                style: TextStyle(color: RoadOSColors.neonViolet, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSimBtn('Simulate Crash Suspected', () {
                _safetyEngine.evaluateMultiSignalEvent(
                  peakGForce: 5.2,
                  speedDropKmh: 45.0,
                  vehicleConnectionLost: true,
                  isStationaryAfterImpact: true,
                  isSimulated: true,
                );
              }),
              _buildSimBtn('Simulate Pothole (False Positive)', () {
                _safetyEngine.evaluateMultiSignalEvent(
                  peakGForce: 3.2,
                  speedDropKmh: 0.0,
                  vehicleConnectionLost: false,
                  isStationaryAfterImpact: false,
                  isSimulated: true,
                );
                showLuxSnack(context, 'Simulated pothole shock filtered as false positive', variant: LuxSnackVariant.info);
              }),
              _buildSimBtn('Simulate Manual SOS', () {
                _safetyEngine.triggerManualSos(isSimulated: true);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        foregroundColor: RoadOSColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text('CRASH / IMPACT DETECTED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Are you OK? Alerting emergency contacts in:', style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent, width: 4),
            ),
            child: Text(
              '${_safetyEngine.secondsRemaining}',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.apexEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _safetyEngine.cancelCountdownRiderSafe(),
                  child: const Text("I'M OK / CANCEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _safetyEngine.confirmEmergencyNow(),
                  child: const Text('GET HELP NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyConfirmedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emergency_share_rounded, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text('EMERGENCY WORKFLOW ACTIVE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          const Text(
            'GPS coordinates, vehicle telemetry, and incident timestamp packaged for emergency dispatch.\n[TEST MODE: Zero real external SMS/calls sent during dev testing]',
            style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.cardSurface,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _safetyEngine.cancelCountdownRiderSafe(),
            child: const Text('DISMISS EMERGENCY ALERT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showLuxDialog(
      context: context,
      child: LuxDialog(
        title: 'Add Emergency Contact',
        icon: Icons.person_add_alt_1_rounded,
        variant: LuxSnackVariant.info,
        confirmLabel: 'SAVE',
        cancelLabel: 'CANCEL',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: RoadOSColors.textMuted))),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: RoadOSColors.textMuted))),
            const SizedBox(height: 8),
            TextField(controller: relCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Relationship', labelStyle: TextStyle(color: RoadOSColors.textMuted))),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
            setState(() {
              _safetyEngine.addEmergencyContact(EmergencyContact(
                id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
                relationship: relCtrl.text.trim().isEmpty ? 'Contact' : relCtrl.text.trim(),
              ));
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
