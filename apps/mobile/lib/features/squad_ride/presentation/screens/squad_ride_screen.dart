import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../../obd_tpms/presentation/widgets/connected_platform_widgets.dart';
import '../bloc/squad_bloc.dart';
import '../bloc/squad_event.dart';
import '../bloc/squad_state.dart';
import '../../domain/entities/squad_entity.dart';

class SquadRideScreen extends StatefulWidget {
  const SquadRideScreen({super.key});

  @override
  State<SquadRideScreen> createState() => _SquadRideScreenState();
}

class _SquadRideScreenState extends State<SquadRideScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _micMuted = false;
  final String _selectedChannel = 'APEX RIDERS MOTO CH 1';
  final String _squadPin = '8924';

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _showJoinSquadDialog() {
    LuxAudioHapticsService.selectionClick();
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('JOIN SQUAD RIDE', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtrl,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          decoration: const InputDecoration(
            hintText: 'Enter 6-Character Squad Code',
            hintStyle: TextStyle(color: RoadOSColors.textMuted, letterSpacing: 1.0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: RoadOSColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textCtrl.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                LuxAudioHapticsService.heavyImpact();
                Navigator.pop(context);
                context.read<SquadBloc>().add(JoinSquadEvent(squadCode: code));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.hyperOrange),
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SquadBloc, SquadState>(
      builder: (context, state) {
        final List<SquadMemberEntity> activeMembers = 
            state is SquadActiveState ? state.squad.members : [];
        final String displayPin = state is SquadActiveState ? state.squad.squadCode : _squadPin;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RoadOSVisualEnvironment(
            environmentType: RoadOSEnvironmentType.radar,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: LuxResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Squad Control Header Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wifi_tethering_rounded, color: RoadOSColors.apexEmerald, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Squad PIN: $displayPin | Mesh Radio Active',
                                style: const TextStyle(fontSize: 11, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group_add_rounded, color: RoadOSColors.hyperOrange, size: 20),
                            onPressed: _showJoinSquadDialog,
                            tooltip: 'Join Squad',
                          ),
                          IconButton(
                            icon: Icon(
                              _micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              color: _micMuted ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald,
                              size: 20,
                            ),
                            onPressed: () {
                              LuxAudioHapticsService.selectionClick();
                              setState(() => _micMuted = !_micMuted);
                            },
                            tooltip: _micMuted ? 'Unmute Mesh Mic' : 'Mute Mesh Mic',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live 360 Squad Radar Canvas
                  _buildRadarCanvas(),
                  const SizedBox(height: 16),

                  // Mesh Voice Radio Card
                  _buildVoiceChannelCard(),
                  const SizedBox(height: 16),

                  // Active Squad Riders List
                  if (state is SquadLoadingState)
                    const Center(child: CircularProgressIndicator(color: RoadOSColors.cyberCyan))
                  else if (state is SquadFailureState)
                    Text('Error: ${state.errorMessage}', style: const TextStyle(color: RoadOSColors.errorCrimson))
                  else ...[
                    Text('ACTIVE SQUAD RIDERS (${activeMembers.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
                    const SizedBox(height: 8),
                    ...activeMembers.map((rider) => _buildRiderTile(rider)),
                    if (activeMembers.isEmpty)
                      const Text('No active members yet. Invite friends!', style: TextStyle(color: RoadOSColors.textMuted)),
                  ],
                  const SizedBox(height: 16),

                  const AntiTheftGuardWidget(),
                ],
              ),
            ),
          ),
        ),
        ),
      );
    });
  }

  Widget _buildRadarCanvas() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoadOSColors.hyperOrange.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(double.infinity, 220),
              painter: SquadRadarPainter(progress: _radarController.value),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVoiceChannelCard() {
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LuxGradients.quantumCyan,
                  shape: BoxShape.circle,
                ),
                child: Icon(_micMuted ? Icons.mic_off_rounded : Icons.graphic_eq_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedChannel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                  Text(
                    _micMuted ? 'Microphone Muted' : 'VOX Auto Voice Transmit Active',
                    style: TextStyle(fontSize: 9, color: _micMuted ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              LuxAudioHapticsService.selectionClick();
              setState(() => _micMuted = !_micMuted);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _micMuted ? RoadOSColors.errorCrimson.withValues(alpha: 0.2) : RoadOSColors.cyberCyan.withValues(alpha: 0.2),
              foregroundColor: _micMuted ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan,
              elevation: 0,
              side: BorderSide(color: _micMuted ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: Text(_micMuted ? 'UNMUTE' : 'MUTE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderTile(SquadMemberEntity rider) {
    // Determine color based on ID to keep the aesthetic alive
    final colors = [RoadOSColors.cyberCyan, RoadOSColors.hyperOrange, RoadOSColors.apexEmerald, Color(0xFFB388FF)];
    final color = colors[rider.riderId.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RoadOSCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(Icons.two_wheeler_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.fullName + (rider.isCreator ? ' (Lead)' : ''), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                    Text(rider.speedKmh != null ? '${rider.speedKmh!.toStringAsFixed(1)} km/h | Connected' : 'Connected', style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
                  ],
                ),
              ],
            ),
            Text(
              'Live',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class SquadRadarPainter extends CustomPainter {
  final double progress;

  SquadRadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 400.0;
    final center = Offset(width / 2, height / 2);
    final maxRadius = math.max(10.0, math.min(width, height) * 0.42);

    // Concentric Radar Rings
    final ringPaint = Paint()
      ..color = RoadOSColors.hyperOrange.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (maxRadius / 3) * i, ringPaint);
    }

    // Rotating Radar Sweep Scanner
    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          RoadOSColors.hyperOrange.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.15, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Self Rider Pointer (Center)
    canvas.drawCircle(center, 6, Paint()..color = RoadOSColors.hyperOrange);

    // Squad Member Blips
    final leadPos = Offset(center.dx + 45, center.dy - 35);
    final marcusPos = Offset(center.dx - 25, center.dy + 30);
    final elenaPos = Offset(center.dx - 60, center.dy + 50);

    _drawRiderBlip(canvas, leadPos, RoadOSColors.cyberCyan, 'Alex');
    _drawRiderBlip(canvas, marcusPos, RoadOSColors.hyperOrange, 'Marcus');
    _drawRiderBlip(canvas, elenaPos, RoadOSColors.apexEmerald, 'Elena');
  }

  void _drawRiderBlip(Canvas canvas, Offset pos, Color color, String name) {
    canvas.drawCircle(pos, 6, Paint()..color = color);
    canvas.drawCircle(pos, 10, Paint()..color = color.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant SquadRadarPainter oldDelegate) => true;
}
