import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/vehicle_mode/vehicle_mode.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_resolution/models/active_vehicle_context.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../squad_ride/presentation/bloc/squad_bloc.dart';
import '../../../squad_ride/presentation/screens/squad_ride_screen.dart';
import '../../../dashcam/presentation/screens/ai_vision_dashcam_screen.dart';
import '../../../dashboard/presentation/screens/home_screen.dart';
import '../../../vehicle_manager/presentation/screens/my_vehicles_screen.dart';
import '../../../connected_vehicle/presentation/screens/connect_vehicle_screen.dart';
import '../../../connected_vehicle/presentation/screens/connection_center_screen.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../garage/presentation/screens/vehicle_maintenance_screen.dart';
import '../../../dashboard/presentation/screens/advanced_realtime_dashboard_screen.dart';
import '../../../documents/presentation/screens/vehicle_documents_screen.dart';
import '../../../diagnostics/presentation/screens/vehicle_health_dashboard_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../profile/presentation/screens/profile_settings_screen.dart';
import '../../../ride_history/presentation/screens/ride_history_screen.dart';
import '../../../safety/presentation/screens/rider_safety_center_screen.dart';
import '../../../vehicle_mode/presentation/screens/car_mode_screen.dart';
import '../../../vehicle_mode/presentation/screens/bike_mode_screen.dart';
import '../../../vehicle_mode/presentation/screens/scooter_mode_screen.dart';

/// Navigation Item Model with Dynamic Accents for Ultra Glass Navigation 2.0
class RoadOSShellNavItem {
  final IconData icon;
  final String label;
  final String category;
  final Color accentColor;
  final Widget screen;

  const RoadOSShellNavItem({
    required this.icon,
    required this.label,
    required this.category,
    required this.accentColor,
    required this.screen,
  });
}

class RoadOSAppShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const RoadOSAppShell({super.key, this.initialIndex = 1});

  @override
  ConsumerState<RoadOSAppShell> createState() => _RoadOSAppShellState();
}

class _RoadOSAppShellState extends ConsumerState<RoadOSAppShell> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _isSidebarExpanded = true;
  bool _isFullscreen = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Standardized Compact Top Bar & Sidebar Header Height
  static const double kHeaderHeight = 56.0;

  List<RoadOSShellNavItem> get _navItems {
    // Drive Hub routes to the correct mode screen based on vehicleModeProvider
    final vehicleMode = ref.watch(vehicleModeProvider);
    final driveScreen = _driveScreenForMode(vehicleMode);
    final driveColor = _driveColorForMode(vehicleMode);
    final driveIcon = _driveIconForMode(vehicleMode);

    return [
      const RoadOSShellNavItem(
        icon: Icons.home_rounded,
        label: 'Home',
        category: 'MAIN',
        accentColor: RoadOSColors.electricBlue,
        screen: HomeScreen(),
      ),
      RoadOSShellNavItem(
        icon: driveIcon,
        label: 'Drive',
        category: 'MAIN',
        accentColor: driveColor,
        screen: driveScreen,
      ),
      const RoadOSShellNavItem(
        icon: Icons.navigation_rounded,
        label: 'Navigation',
        category: 'MAIN',
        accentColor: RoadOSColors.cyberCyan,
        screen: ThreeDNavigationScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.two_wheeler_rounded,
        label: 'My Vehicles',
        category: 'VEHICLE',
        accentColor: RoadOSColors.neonViolet,
        screen: MyVehiclesScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.bluetooth_searching_rounded,
        label: 'Connect',
        category: 'VEHICLE',
        accentColor: RoadOSColors.electricBlue,
        screen: ConnectVehicleScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.view_in_ar_rounded,
        label: '3D Garage',
        category: 'VEHICLE',
        accentColor: RoadOSColors.cyberCyan,
        screen: LuxuryGarageShowroomScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.speed_rounded,
        label: 'Dashboard',
        category: 'VEHICLE',
        accentColor: RoadOSColors.neonViolet,
        screen: AdvancedRealtimeDashboardScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.hub_rounded,
        label: 'Connection Center',
        category: 'VEHICLE',
        accentColor: RoadOSColors.cyberCyan,
        screen: ConnectionCenterScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.analytics_rounded,
        label: 'Trips',
        category: 'TELEMETRY',
        accentColor: RoadOSColors.apexEmerald,
        screen: RideHistoryScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.health_and_safety_rounded,
        label: 'Health',
        category: 'DIAGNOSTICS',
        accentColor: RoadOSColors.apexEmerald,
        screen: VehicleHealthDashboardScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.build_rounded,
        label: 'Maintenance',
        category: 'DIAGNOSTICS',
        accentColor: RoadOSColors.hyperOrange,
        screen: VehicleMaintenanceScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.shield_rounded,
        label: 'Safety',
        category: 'SYSTEM',
        accentColor: Color(0xFFFF4444),
        screen: RiderSafetyCenterScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.videocam_rounded,
        label: 'Dashcam',
        category: 'SYSTEM',
        accentColor: RoadOSColors.neonViolet,
        screen: AiVisionDashcamScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.description_rounded,
        label: 'Documents',
        category: 'SYSTEM',
        accentColor: RoadOSColors.cyberCyan,
        screen: VehicleDocumentsScreen(),
      ),
      const RoadOSShellNavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        category: 'SYSTEM',
        accentColor: RoadOSColors.textSecondary,
        screen: ProfileSettingsScreen(),
      ),
      RoadOSShellNavItem(
        icon: Icons.groups_rounded,
        label: 'Squad Ride',
        category: 'COMMUNITY',
        accentColor: RoadOSColors.cyberCyan,
        screen: _buildSquadRideScreenSafe(),
      ),
      RoadOSShellNavItem(
        icon: Icons.psychology_rounded,
        label: 'AI Co-Pilot',
        category: 'AI & CO-PILOT',
        accentColor: RoadOSColors.neonViolet,
        screen: _buildAiAssistantScreenSafe(),
      ),
    ];
  }

  Widget _driveScreenForMode(VehicleMode mode) {
    switch (mode) {
      case VehicleMode.car:
        return const CarModeScreen();
      case VehicleMode.bike:
        return const BikeModeScreen();
      case VehicleMode.scooter:
        return const ScooterModeScreen();
    }
  }

  Color _driveColorForMode(VehicleMode mode) {
    switch (mode) {
      case VehicleMode.car:
        return RoadOSColors.electricBlue;
      case VehicleMode.bike:
        return RoadOSColors.neonViolet;
      case VehicleMode.scooter:
        return RoadOSColors.apexEmerald;
    }
  }

  IconData _driveIconForMode(VehicleMode mode) {
    switch (mode) {
      case VehicleMode.car:
        return Icons.directions_car_rounded;
      case VehicleMode.bike:
        return Icons.two_wheeler_rounded;
      case VehicleMode.scooter:
        return Icons.electric_scooter_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectNav(int index) {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
    if (kIsWeb) {
      final route = AppRouter.routeForIndex(index);
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(route));
    }
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _toggleSidebar() {
    LuxAudioHapticsService.lightImpact();
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _toggleFullscreen() {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFullscreen ? 'Fullscreen Maximized' : 'Standard Layout Restored'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleSearch() {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeVehicleContextProvider, (previous, next) {
      if (next.profile != null && next.connectionStatus == VehicleConnectionStatus.connected) {
        if (previous?.profile?.id != next.profile!.id || previous?.connectionStatus != VehicleConnectionStatus.connected) {
          final p = next.profile!;
          VehicleMode newMode = VehicleMode.car;
          if (p.isScooter) {
            newMode = VehicleMode.scooter;
          } else if (p.category.toLowerCase().contains('motorcycle') || p.category.toLowerCase().contains('bike')) {
            newMode = VehicleMode.bike;
          }
          ref.read(vehicleModeProvider.notifier).setMode(newMode);
          
        }
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final isTablet = screenWidth >= 640 && screenWidth < 920;
    final activeItem = _navItems[_selectedIndex];

    // Responsive Sidebar Width
    final sidebarWidth = isDesktop ? (_isSidebarExpanded ? 256.0 : 74.0) : (isTablet ? 74.0 : 0.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      // Mobile Slide-out Drawer with ultra glass
      drawer: isDesktop || isTablet ? null : _buildMobileDrawer(context),
      bottomNavigationBar: isDesktop || isTablet ? null : _buildMobileBottomNavBar(context),
      body: CinematicBackground(
        child: Stack(
          children: [
            // Row Layout: [Ultra Glass Sidebar] + [Main Column (Compact Glass TopBar + Content)]
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LEFT ULTRA GLASS SIDEBAR (Desktop & Tablet)
                if (isDesktop || isTablet)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    width: sidebarWidth,
                    child: _buildDesktopGlassSidebar(
                      context,
                      isCompact: isTablet || !_isSidebarExpanded,
                      activeItem: activeItem,
                    ),
                  ),

                // 2. MAIN COLUMN (Compact 56px TopBar + Full Page Content)
                Expanded(
                  child: Column(
                    children: [
                      // Fixed Compact Top Bar (56px)
                      _buildTopBar(
                        context,
                        activeItem: activeItem,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),

                      // Page Content (Fills 100% remaining height & width with ZERO overlap)
                      Expanded(
                        child: ClipRect(
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: _navItems.map((item) => item.screen).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  /// Compact 56px Top Bar Navigation Component with Translucent Liquid Water-Glass & Backdrop Blur
  Widget _buildTopBar(
    BuildContext context, {
    required RoadOSShellNavItem activeItem,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x4A131A32), Color(0x2804060C)],
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0x4500F2FE), width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Hamburger / Toggle Button & Brand (Mobile/Tablet)
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: RoadOSColors.roadCyan, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Open Navigation Drawer',
                  onPressed: () {
                    LuxAudioHapticsService.lightImpact();
                    if (isTablet) {
                      _toggleSidebar();
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),
                const SizedBox(width: 6),
                const RoadOSLogo(size: 24, showWordmark: false),
                const SizedBox(width: 10),
              ],

              // Left Section Header / Title & Compact Contextual Telematics Pill
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        activeItem.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: RoadOSColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (MediaQuery.of(context).size.width >= 480) ...[
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: RoadOSColors.apexEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.40), width: 0.9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: RoadOSColors.apexEmerald,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: RoadOSColors.apexEmerald.withValues(alpha: 0.6),
                                      blurRadius: 3,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'TELEMATICS ACTIVE',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: RoadOSColors.apexEmerald,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Expandable Search Input Field
              if (_isSearchExpanded)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width < 500 ? 110 : 140),
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x3300E5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RoadOSColors.roadCyan.withValues(alpha: 0.45), width: 0.9),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: RoadOSColors.textSecondary.withValues(alpha: 0.7), fontSize: 10.5),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 14, color: RoadOSColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: _toggleSearch,
                      ),
                    ),
                  ),
                ),

              // Right Controls: Quick Search, Fullscreen, Notifications, Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search Trigger Button
                  if (!_isSearchExpanded)
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: RoadOSColors.textSecondary, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Search Destination',
                      onPressed: _toggleSearch,
                    ),

                  // Fullscreen Toggle (Desktop Only)
                  if (isDesktop)
                    IconButton(
                      icon: Icon(
                        _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        color: RoadOSColors.textSecondary,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Maximize Workspace',
                      onPressed: _toggleFullscreen,
                    ),

                   // Notifications Center with Unread Amber Beacon
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded, color: RoadOSColors.textPrimary, size: 18),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: RoadOSColors.hyperOrange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.7),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Safety Center & Alerts',
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      Navigator.push(
                        context,
                        premiumRoute(const RiderSafetyCenterScreen()),
                      );
                    },
                  ),

                  const SizedBox(width: 6),

                  // Rider Profile Avatar with Glow Halo
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final name = state is AuthenticatedState ? state.rider.fullName : 'Rider';
                      return GestureDetector(
                        onTap: () {
                          _onSelectNav(14); // Profile Vault
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: RoadOSGradients.brandCyan,
                            shape: BoxShape.circle,
                            boxShadow: RoadOSShadows.cyanGlow(opacity: 0.3, blur: 8),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'R',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Left Sidebar Component with Translucent Liquid Water-Glass & Matching 56px Header Baseline
  Widget _buildDesktopGlassSidebar(
    BuildContext context, {
    required bool isCompact,
    required RoadOSShellNavItem activeItem,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x4A131A32), Color(0x2804060C)],
            ),
            border: const Border(
              right: BorderSide(color: Color(0x4000F2FE), width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(6, 0),
              ),
              BoxShadow(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.05),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              // Sidebar Header: Exact 56px Height to perfectly align with Top Bar baseline
              Container(
                height: kHeaderHeight,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x2200F2FE), width: 1.0)),
                ),
                child: Row(
                  mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isCompact)
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RoadOSLogo(size: 24, showWordmark: true),
                        ),
                      ),
                    if (isCompact)
                      const Center(
                        child: RoadOSLogo(size: 22, showWordmark: false),
                      ),
                    if (!isCompact)
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: RoadOSColors.textSecondary, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: 'Collapse Sidebar',
                        onPressed: _toggleSidebar,
                      ),
                  ],
                ),
              ),

              // Navigation List Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  children: [
                    ..._buildCategorizedSidebarTiles(isCompact),
                    const Divider(color: Color(0x1400E5FF), height: 16),
                    _buildSidebarLogoutTile(context, isCompact),
                  ],
                ),
              ),

              // Sidebar Footer: Collapse Toggle & System Online Status
              if (isCompact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: RoadOSColors.roadCyan, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Expand Sidebar',
                    onPressed: _toggleSidebar,
                  ),
                ),
              if (!isCompact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x1400E5FF), width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: RoadOSColors.apexEmerald,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RoadOSColors.apexEmerald.withValues(alpha: 0.6),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Rideo Pro v4.0 | Flagship',
                          style: RoadOSTypography.caption(color: RoadOSColors.textMuted).copyWith(fontSize: 9.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSection(String title, bool isCompact) {
    if (isCompact) return const Divider(color: Color(0x1400E5FF), height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: RoadOSColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarTile(int index, bool isCompact) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    final accent = item.accentColor;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0.04)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: accent.withValues(alpha: 0.50), width: 1.0)
            : Border.all(color: Colors.transparent, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: isSelected ? accent : RoadOSColors.textSecondary,
            size: 18,
          ),
          if (!isCompact) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? RoadOSColors.textPrimary : RoadOSColors.textSecondary,
                  letterSpacing: 0.15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: () => _onSelectNav(index),
      borderRadius: BorderRadius.circular(8),
      child: isCompact ? Tooltip(message: '${item.label} | ${item.category}', child: tile) : tile,
    );
  }

  List<Widget> _buildCategorizedSidebarTiles(bool isCompact) {
    final widgets = <Widget>[];
    String? lastCategory;

    for (int i = 0; i < _navItems.length; i++) {
      final item = _navItems[i];
      if (lastCategory != item.category) {
        lastCategory = item.category;
        widgets.add(_buildSidebarSection(lastCategory, isCompact));
      }
      widgets.add(_buildSidebarTile(i, isCompact));
    }
    return widgets;
  }

  Widget _buildSidebarLogoutTile(BuildContext context, bool isCompact) {
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: RoadOSColors.errorCrimson.withValues(alpha: 0.08),
        border: Border.all(color: RoadOSColors.errorCrimson.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          const Icon(
            Icons.logout_rounded,
            color: RoadOSColors.errorCrimson,
            size: 18,
          ),
          if (!isCompact) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Logout Session',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RoadOSColors.errorCrimson,
                  letterSpacing: 0.15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: () {
        LuxAudioHapticsService.lightImpact();
        context.read<AuthBloc>().add(LogoutEvent());
        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.root, (route) => false);
      },
      borderRadius: BorderRadius.circular(8),
      child: isCompact ? Tooltip(message: 'Logout Session', child: tile) : tile,
    );
  }

  static Widget _buildSquadRideScreenSafe() {
    return Builder(
      builder: (context) {
        try {
          context.read<SquadBloc>();
          return const SquadRideScreen();
        } catch (_) {
          return const Scaffold(
            backgroundColor: Color(0xFF03050A),
            body: Center(
              child: Text(
                'Squad Ride',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      },
    );
  }

  static Widget _buildAiAssistantScreenSafe() {
    return Builder(
      builder: (context) {
        try {
          context.read<AiAssistantBloc>();
          return const AiAssistantScreen();
        } catch (_) {
          return const Scaffold(
            backgroundColor: Color(0xFF03050A),
            body: Center(
              child: Text(
                'AI Co-Pilot',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      },
    );
  }

  /// Mobile Slide-out Drawer Navigation with Liquid Water-Glass
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xD0080E24), Color(0xF0030610)],
              ),
              border: Border(
                right: BorderSide(color: Color(0x3500F2FE), width: 1.0),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: kHeaderHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0x2200F2FE))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const RoadOSLogo(size: 26, showWordmark: true),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: RoadOSColors.textSecondary, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = _selectedIndex == index;
                        final accent = item.accentColor;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(colors: [accent.withValues(alpha: 0.28), accent.withValues(alpha: 0.08)])
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.0) : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              item.icon,
                              color: isSelected ? accent : RoadOSColors.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : RoadOSColors.textPrimary,
                              ),
                            ),
                            onTap: () => _onSelectNav(index),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x2200F2FE))),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.logout_rounded, color: RoadOSColors.errorCrimson, size: 20),
                      title: const Text(
                        'Logout Account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: RoadOSColors.errorCrimson,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.read<AuthBloc>().add(LogoutEvent());
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.root, (route) => false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Quick-Access Liquid Water-Glass Bottom Navigation Bar
  Widget _buildMobileBottomNavBar(BuildContext context) {
    final primaryIndices = [0, 6, 5, 7];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x35101A3B), Color(0x25060A18)],
            ),
            border: const Border(top: BorderSide(color: Color(0x3500F2FE), width: 1.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              ...primaryIndices.map((index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: LiquidWaterRipple(
                    borderRadius: 16,
                    rippleColor: isSelected ? RoadOSColors.roadCyan : RoadOSColors.electricIndigo,
                    onTap: () => _onSelectNav(index),
                    child: Center(
                      child: AnimatedContainer(
                        duration: RoadOSMotion.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected ? RoadOSGradients.primaryViolet : null,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: const Color(0x80FFFFFF), width: 1)
                              : null,
                          boxShadow: isSelected ? RoadOSShadows.neonGlow(opacity: 0.4, blur: 10) : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: isSelected ? Colors.white : RoadOSColors.textMuted,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? Colors.white : RoadOSColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Slot 5: "More" Menu Drawer Trigger
              Expanded(
                child: LiquidWaterRipple(
                  borderRadius: 16,
                  onTap: () {
                    LuxAudioHapticsService.selectionClick();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grid_view_rounded, size: 19, color: RoadOSColors.textMuted),
                          SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'MORE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: RoadOSColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
