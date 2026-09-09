import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models.dart';
import '../services/digital_twin_resolver.dart';
import '../services/digital_twin_state_mapper.dart';
import 'renderers/exact_3d_renderer.dart';
import 'renderers/generic_3d_renderer.dart';
import 'renderers/procedural_wireframe_renderer.dart';
import 'renderers/orthographic_2d_renderer.dart';
import '../../../features/vehicle/presentation/bloc/vehicle_bloc.dart';
import '../../../features/vehicle/presentation/bloc/vehicle_state.dart';

class DigitalTwinWidget extends StatelessWidget {
  const DigitalTwinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleBlocState>(
      builder: (context, state) {
        final activeContext = state.activeContext;
        final identity = activeContext.identity;

        // Resolve Digital Twin Fidelity and Asset
        final resolver = DigitalTwinResolver();
        final resolution = resolver.resolve(identity);

        // Map Canonical State -> Visual Digital Twin State
        final visualState = DigitalTwinStateMapper.mapState(activeContext);

        // Render based on actual fidelity (Truthful fallback)
        switch (resolution.fidelity) {
          case DigitalTwinFidelity.level1Exact3D:
            return Exact3DRenderer(
              resolution: resolution,
              state: visualState,
            );
          case DigitalTwinFidelity.level2Category3D:
            return Generic3DRenderer(
              resolution: resolution,
              state: visualState,
            );
          case DigitalTwinFidelity.level3Procedural:
            return ProceduralWireframeRenderer(
              resolution: resolution,
              state: visualState,
            );
          case DigitalTwinFidelity.level42D:
            return Orthographic2DRenderer(
              resolution: resolution,
              state: visualState,
              context: activeContext,
            );
        }
      },
    );
  }
}
