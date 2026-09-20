import 'dart:async';

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/theme_engine.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/bluetooth/models/bluetooth_connection_state.dart' as app_state;
import '../../../../core/bluetooth/web/web_bluetooth_manager.dart';
import '../../../../core/bluetooth/web/web_bluetooth_models.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/models/vehicle_identity.dart';
import '../../../../core/vehicle_resolution/models/vehicle_identity_resolution_result.dart';
import '../../../../core/vehicle_resolution/services/vehicle_identity_resolver.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import '../../../../core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import '../../../../core/vehicle_connectivity/services/automatic_vehicle_identifier.dart';
import '../../../../core/vehicle_connectivity/services/vehicle_compatibility_evaluator.dart';
import '../../../../core/vehicle_connectivity/services/paired_vehicle_memory_service.dart';
import '../../../../core/vehicle_connectivity/services/connection_recovery_engine.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'connection_diagnostics_screen.dart';
import 'vehicle_compatibility_details_modal.dart';
import 'vehicle_catalog_browser_screen.dart';
import 'live_vehicle_dashboard_modal.dart';
import 'add_vehicle_modal.dart';
import 'manual_vehicle_selector_modal.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../../core/graphics/liquid_glass_engine.dart';

/// Single unified Radio & Bluetooth Connection State Machine
enum ConnectVehicleRadioState {
  idle,
  ready,
  scanning,
  deviceSelected,
  connecting,
  connected,
  disconnected,
  cancelled,
  permissionDenied,
  unsupported,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECT VEHICLE SCREEN — Luxury BLE Scanner
//  Full functional logic with unified state machine and persistent storage.
//  UI built with LuxThemeEngine / RoadOSCard / AnimatedRadar / 3D press.
// ─────────────────────────────────────────────────────────────────────────────

class ConnectVehicleScreen extends ConsumerStatefulWidget {
  const ConnectVehicleScreen({super.key});

  @override
  ConsumerState<ConnectVehicleScreen> createState() => _ConnectVehicleScreenState();
}

class _ConnectVehicleScreenState extends ConsumerState<ConnectVehicleScreen>
    with TickerProviderStateMixin {

  // ── Unified Connection State Machine ───────────────────────────────────────
  ConnectVehicleRadioState _radioState = ConnectVehicleRadioState.idle;

  // ── Native BLE state ───────────────────────────────────────────────────────
  Stream<List<ScanResult>>? _scanStream;
  bool _isScanning = false;
  String? _connectingDeviceId;
  final _memoryService    = PairedVehicleMemoryService();
  final _recoveryEngine   = ConnectionRecoveryEngine();
  List<PairedVehicleRecord> _pairedVehicles = [];

  // ── Web Bluetooth state ────────────────────────────────────────────────────
  final WebBluetoothManager _webBleManager = WebBluetoothManager();
  WebBleSupportInfo? _webBleSupport;
  WebBleDevice? _connectedWebDevice;
  bool _isWebBleScanning = false;
  String? _webBleStatusMessage;
  StreamSubscription<String>? _webBleDisconnectSub;
  VehicleIdentityResolutionResult? _webBleResolutionResult;

  // ── Luxury animation controllers ───────────────────────────────────────────
  late AnimationController _radarCtrl;   // radar sweep ring
  late AnimationController _pulseCtrl;   // icon pulse on scanning
  late AnimationController _scanBorderCtrl; // glowing scan border

  @override
  void initState() {
    super.initState();
    _loadPairedVehicles();

    // Radar sweep — 2.8 s loop
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    // Pulse — 1.4 s loop
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Scanning glow border — 1.8 s loop
    _scanBorderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    if (kIsWeb) {
      _initWebBluetooth();
    } else {
      _startScan();
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _scanBorderCtrl.dispose();
    if (!kIsWeb) _stopScan();
    _webBleDisconnectSub?.cancel();
    super.dispose();
  }

  // ── Unified Web Bluetooth Logic ────────────────────────────────────────────

  Future<void> _initWebBluetooth() async {
    final support = await _webBleManager.checkSupport();
    if (mounted) {
      setState(() {
        _webBleSupport = support;
        if (!support.isSupported) {
          _radioState = ConnectVehicleRadioState.unsupported;
          _webBleStatusMessage = support.reason;
        } else {
          _radioState = ConnectVehicleRadioState.ready;
          _webBleStatusMessage = 'Web Bluetooth Ready | Standby';
        }
      });
    }

    _webBleDisconnectSub = _webBleManager.onDeviceDisconnected.listen((deviceId) {
      if (mounted) {
        setState(() {
          _connectedWebDevice = _connectedWebDevice?.copyWith(isConnected: false) ??
              WebBleDevice(id: deviceId, name: 'BLE Vehicle', isConnected: false, services: const [], connectedAt: DateTime.now());
          _radioState = ConnectVehicleRadioState.disconnected;
          _webBleStatusMessage = 'Device disconnected. Ready to reconnect.';
        });
      }
    });
  }

  Future<void> _loadPairedVehicles() async {
    final list = await _memoryService.getPairedVehicles();
    if (mounted) setState(() => _pairedVehicles = list);
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _radioState = ConnectVehicleRadioState.scanning;
    });
    try {
      final stream = await BluetoothEngine().scanner.startScan();
      if (mounted) setState(() => _scanStream = stream);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _radioState = ConnectVehicleRadioState.error;
        });
        showLuxSnack(context, 'Scan error: $e', variant: LuxSnackVariant.error);
      }
    }
  }

  Future<void> _stopScan() async {
    await BluetoothEngine().scanner.stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _radioState = ConnectVehicleRadioState.ready;
      });
    }
  }

  Future<void> _scanForWebBleDevice() async {
    if (_radioState == ConnectVehicleRadioState.scanning) return; // double-click protection

    setState(() {
      _isWebBleScanning = true;
      _radioState = ConnectVehicleRadioState.scanning;
      _webBleStatusMessage = 'Opening browser Bluetooth device picker...';
    });

    try {
      final reqResult = await _webBleManager.requestDevice();

      if (reqResult.cancelled) {
        setState(() {
          _isWebBleScanning = false;
          _radioState = ConnectVehicleRadioState.cancelled;
          _webBleStatusMessage = 'Scanning cancelled.';
        });
        return;
      }

      if (!reqResult.success || reqResult.deviceId == null) {
        final err = reqResult.error ?? 'Device not selected';
        final isPermission = err.toLowerCase().contains('permission') ||
            err.toLowerCase().contains('denied') ||
            err.toLowerCase().contains('securityerror') ||
            err.toLowerCase().contains('not allowed');

        setState(() {
          _isWebBleScanning = false;
          _radioState = isPermission
              ? ConnectVehicleRadioState.permissionDenied
              : ConnectVehicleRadioState.error;
          _webBleStatusMessage = isPermission
              ? 'Bluetooth permission was denied. Allow Bluetooth access in browser settings and try again.'
              : 'BLE Notice: $err';
        });
        return;
      }

      final deviceId   = reqResult.deviceId!;
      final deviceName = reqResult.deviceName ?? 'Unknown BLE Vehicle';

      setState(() {
        _radioState = ConnectVehicleRadioState.deviceSelected;
        _webBleStatusMessage = 'Device Selected: $deviceName';
      });

      // Automatically transition to connecting GATT services
      setState(() {
        _radioState = ConnectVehicleRadioState.connecting;
        _webBleStatusMessage = 'Connecting to $deviceName via GATT...';
      });

      final gattResult = await _webBleManager.connectGatt(deviceId);

      if (gattResult.success) {
        final connectedDev = WebBleDevice(
          id: deviceId,
          name: deviceName,
          isConnected: true,
          services: gattResult.services,
          connectedAt: DateTime.now(),
        );
        setState(() {
          _connectedWebDevice = connectedDev;
          _isWebBleScanning   = false;
          _radioState = ConnectVehicleRadioState.connected;
          _webBleStatusMessage = 'Connected to $deviceName';
        });
        _linkWebDeviceToVehicleContext(connectedDev);
        await _loadPairedVehicles();
      } else {
        setState(() {
          _isWebBleScanning   = false;
          _radioState = ConnectVehicleRadioState.error;
          _webBleStatusMessage = 'GATT connection failed: ${gattResult.error}';
        });
      }
    } catch (e) {
      final err = e.toString();
      final isPermission = err.toLowerCase().contains('permission') ||
          err.toLowerCase().contains('denied') ||
          err.toLowerCase().contains('securityerror') ||
          err.toLowerCase().contains('not allowed');

      setState(() {
        _isWebBleScanning   = false;
        _radioState = isPermission
            ? ConnectVehicleRadioState.permissionDenied
            : ConnectVehicleRadioState.error;
        _webBleStatusMessage = isPermission
            ? 'Bluetooth permission was denied. Allow Bluetooth access in browser settings and try again.'
            : 'Web Bluetooth: $err';
      });
    }
  }

  Future<void> _reconnectWebBleDevice(String deviceId) async {
    if (_radioState == ConnectVehicleRadioState.connecting) return;

    setState(() {
      _radioState = ConnectVehicleRadioState.connecting;
      _webBleStatusMessage = 'Reconnecting to BLE vehicle...';
    });

    try {
      final gattResult = await _webBleManager.connectGatt(deviceId);
      if (gattResult.success) {
        final reconnectedDev = WebBleDevice(
          id: deviceId,
          name: _connectedWebDevice?.name ?? 'BLE Vehicle',
          isConnected: true,
          services: gattResult.services,
          connectedAt: DateTime.now(),
        );
        setState(() {
          _connectedWebDevice = reconnectedDev;
          _radioState = ConnectVehicleRadioState.connected;
          _webBleStatusMessage = 'Reconnected to ${reconnectedDev.name}';
        });
        _linkWebDeviceToVehicleContext(reconnectedDev);
        await _loadPairedVehicles();
      } else {
        setState(() {
          _radioState = ConnectVehicleRadioState.error;
          _webBleStatusMessage = 'Reconnection failed: ${gattResult.error}';
        });
      }
    } catch (e) {
      setState(() {
        _radioState = ConnectVehicleRadioState.error;
        _webBleStatusMessage = 'Reconnection error: $e';
      });
    }
  }

  Future<void> _disconnectWebBleDevice() async {
    if (_connectedWebDevice != null) {
      await _webBleManager.disconnect(_connectedWebDevice!.id);
      setState(() {
        _connectedWebDevice  = _connectedWebDevice!.copyWith(isConnected: false);
        _radioState = ConnectVehicleRadioState.disconnected;
        _webBleStatusMessage = 'Disconnected from Bluetooth device.';
      });
    }
  }

  void _linkWebDeviceToVehicleContext(WebBleDevice dev) {
    final resolution = VehicleIdentityResolver().resolveBleDevice(
      deviceName: dev.name,
      deviceId: dev.id,
      gattServices: dev.services.map((s) => s.uuid).toList(),
      transportType: ConnectionTransportType.ble,
    );
    setState(() => _webBleResolutionResult = resolution);

    final profile = resolution.profile ?? VehicleProfile(
      id: 'web_ble_${dev.id}',
      manufacturer: dev.name.contains(' ') ? dev.name.split(' ').first : 'Connected',
      model: dev.name,
      variant: 'Bluetooth Vehicle CCU',
      year: 2024,
      category: 'Motorcycle',
      protocolAdapter: 'web_bluetooth_gatt',
      model3DUrl: '',
      thumbnailUrl: 'assets/garage/generic_bike.png',
      isVerified: false,
    );

    ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
    Global3DStateBridge().loadVehicle(profile);
    ref.read(myVehiclesProvider.notifier).addVehicle(profile);
  }

  void _showCompatibilityModal(IdentificationResult result) {
    showLuxSheet(
      context: context,
      title: 'Compatibility Details',
      accentColor: RoadOSColors.electricBlue,
      builder: (_) => VehicleCompatibilityDetailsModal(
        vehicleName: result.model ?? result.brand,
        manufacturer: result.brand,
        year: result.modelYear != null ? result.modelYear.toString() : '2024',
        variant: VehicleVariant(
          variantId: 'var_${result.protocolAdapterId}',
          variantName: result.variant ?? 'Standard',
          displayType: result.displayType,
          hasBluetooth: true,
          hasTelematicsUnit: true,
          primaryConnectivity: VehicleConnectivityType.ble,
          protocolAdapterId: result.protocolAdapterId,
          capabilities: result.capabilities,
          compatibilityLevel: result.compatibilityLevel,
        ),
        capabilities: result.capabilities,
        compatibilityLevel: result.compatibilityLevel,
      ),
    );
  }

  void _openAddVehicleModal() {
    LuxAudioHapticsService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      useSafeArea: true,
      builder: (ctx) => AddVehicleModal(
        onVehicleSaved: () => _loadPairedVehicles(),
      ),
    );
  }

  void _openManualVehicleSelector() {
    LuxAudioHapticsService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      useSafeArea: true,
      builder: (ctx) => ManualVehicleSelectorModal(
        onVehicleConnected: () => _loadPairedVehicles(),
      ),
    );
  }

  void _openLiveDashboard(VehicleProfile profile) {
    showLuxSheet(
      context: context,
      title: profile.fullName,
      accentColor: RoadOSColors.apexEmerald,
      builder: (_) => LiveVehicleDashboardModal(profile: profile),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final btState     = ref.watch(bluetoothStateProvider);
    final activeCtx   = ref.watch(activeVehicleContextProvider);
    final isDark      = LuxThemeEngine().isDarkMode;
    final scanning    = _isScanning || _isWebBleScanning;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: CinematicBackground(
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── BLE link status card ──────────────────────────────────
              _buildBluetoothStatus(btState, activeCtx, isDark),
              const SizedBox(height: 10),

              // ── Web BLE environment badge ─────────────────────────────
              if (kIsWeb) ...[
                _buildWebBluetoothSupportBanner(isDark),
                const SizedBox(height: 10),
              ],

              // ── Connection recovery status ────────────────────────────
              _buildRecoveryStatus(isDark),

              // ── Paired vehicles horizontal strip ──────────────────────
              if (_pairedVehicles.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPairedVehiclesSection(activeCtx, isDark),
              ],

              const SizedBox(height: 14),

              // ── Discovered devices header ─────────────────────────────
              _buildScanHeader(scanning, isDark),
              const SizedBox(height: 10),

              // ── Main content — scanner / device list ──────────────────
              Expanded(
                child: kIsWeb
                    ? _buildWebBleContentArea(isDark)
                    : StreamBuilder<List<ScanResult>>(
                        stream: _scanStream ?? FlutterBluePlus.scanResults,
                        builder: (ctx, snapshot) {
                          final results = snapshot.data ?? [];
                          if (results.isEmpty) {
                            return _buildLuxEmptyState(scanning, isDark);
                          }
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 380),
                                transitionBuilder: (child, anim) => SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.18),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: FadeTransition(opacity: anim, child: child),
                                ),
                                child: _buildLuxDeviceCard(
                                  results[i],
                                  isDark,
                                  key: ValueKey(results[i].device.remoteId.str),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFF0066FF)],
        ).createShader(bounds),
        child: Text(
          'CONNECT VEHICLE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Vehicle Catalog',
          icon: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF00F2FE)),
          onPressed: () {
            LuxAudioHapticsService.lightImpact();
            Navigator.push(context, premiumRoute(const VehicleCatalogBrowserScreen()));
          },
        ),
        IconButton(
          tooltip: 'Connection Diagnostics',
          icon: const Icon(Icons.analytics_outlined, color: Color(0xFF00F2FE)),
          onPressed: () {
            LuxAudioHapticsService.lightImpact();
            Navigator.push(context, premiumRoute(const ConnectionDiagnosticsScreen()));
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BLE STATUS CARD (luxury upgrade of original _buildBluetoothStatus)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBluetoothStatus(
    app_state.BluetoothConnectionState state,
    dynamic activeCtx,
    bool isDark,
  ) {
    final isConnected = _radioState == ConnectVehicleRadioState.connected ||
        _connectedWebDevice?.isConnected == true ||
        state == app_state.BluetoothConnectionState.live ||
        state == app_state.BluetoothConnectionState.connected;

    final isConnecting = _radioState == ConnectVehicleRadioState.connecting;
    final isScanning = _radioState == ConnectVehicleRadioState.scanning || _isScanning || _isWebBleScanning;
    final isCancelled = _radioState == ConnectVehicleRadioState.cancelled;
    final isPermissionDenied = _radioState == ConnectVehicleRadioState.permissionDenied;
    final isUnsupported = _radioState == ConnectVehicleRadioState.unsupported;
    final isDisconnected = _radioState == ConnectVehicleRadioState.disconnected;
    final isError = _radioState == ConnectVehicleRadioState.error;

    final Color accentColor = isConnected
        ? const Color(0xFF00E676)
        : (isConnecting || isScanning
            ? const Color(0xFF00F2FE)
            : (isPermissionDenied
                ? const Color(0xFFFF3B5C)
                : (isCancelled || isUnsupported || isError
                    ? Colors.amber
                    : const Color(0xFF00F2FE))));

    final IconData statusIcon = isConnected
        ? Icons.bluetooth_connected_rounded
        : (isConnecting
            ? Icons.sync_rounded
            : (isScanning
                ? Icons.bluetooth_searching_rounded
                : (isPermissionDenied
                    ? Icons.block_rounded
                    : (isCancelled || isError || isUnsupported
                        ? Icons.info_outline_rounded
                        : Icons.bluetooth_rounded))));

    final String statusTitle = isConnected
        ? 'ACTIVE VEHICLE LINK'
        : (isConnecting
            ? 'CONNECTING GATT'
            : (isScanning
                ? 'SCANNING RADIO'
                : (isPermissionDenied
                    ? 'PERMISSION DENIED'
                    : (isCancelled
                        ? 'SCAN CANCELLED'
                        : (isUnsupported
                            ? 'BROWSER UNSUPPORTED'
                            : (isDisconnected
                                ? 'DISCONNECTED'
                                : (isError ? 'CONNECTION NOTICE' : 'RADIO READY')))))));

    final String statusSubtitle = isConnected
        ? (_connectedWebDevice != null
            ? _connectedWebDevice!.name
            : (activeCtx.hasActiveVehicle ? activeCtx.profile!.fullName : 'Vehicle CCU Connected'))
        : (_webBleStatusMessage ??
            (isScanning ? 'Auto-discovering 2015+ protocols...' : 'BLE Scanner Standby'));

    return AnimatedBuilder(
      animation: _scanBorderCtrl,
      builder: (ctx, _) {
        final glowAlpha = isScanning
            ? (0.2 + _scanBorderCtrl.value * 0.35)
            : (isConnected ? 0.30 : 0.06);

        return RoadOSCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status orb
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isScanning ? glowAlpha : 0.40),
                    width: isScanning ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: glowAlpha), blurRadius: 16),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.inter(
                        color: isConnected
                            ? const Color(0xFF00E676)
                            : (isCancelled || isError || isUnsupported
                                ? Colors.amber
                                : (isPermissionDenied
                                    ? const Color(0xFFFF3B5C)
                                    : const Color(0xFF64748B))),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons
              if (isConnected) ...[
                _LuxPillButton(
                  label: 'DASHBOARD',
                  icon: Icons.dashboard_rounded,
                  color: const Color(0xFF00E676),
                  onTap: () {
                    if (activeCtx.hasActiveVehicle) _openLiveDashboard(activeCtx.profile!);
                  },
                ),
                const SizedBox(width: 6),
                _LuxPillButton(
                  label: 'DISC.',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF3B5C),
                  onTap: () async {
                    LuxAudioHapticsService.mediumImpact();
                    if (kIsWeb) {
                      await _disconnectWebBleDevice();
                    } else {
                      await BluetoothEngine().disconnect();
                      await GenericVehicleConnectivityEngine().disconnectVehicle();
                      _recoveryEngine.reset();
                    }
                  },
                ),
              ] else if (isPermissionDenied) ...[
                _Lux3DButton(
                  label: 'TRY AGAIN',
                  accentColor: const Color(0xFFFF3B5C),
                  isLoading: isScanning,
                  onTap: _scanForWebBleDevice,
                ),
              ] else if (isDisconnected && _connectedWebDevice != null) ...[
                _Lux3DButton(
                  label: isConnecting ? 'CONNECTING...' : 'RECONNECT',
                  accentColor: const Color(0xFF00F2FE),
                  isLoading: isConnecting,
                  onTap: () => _reconnectWebBleDevice(_connectedWebDevice!.id),
                ),
              ] else
                _Lux3DButton(
                  label: isScanning ? 'SCANNING...' : 'SCAN FOR BLE',
                  accentColor: const Color(0xFF00F2FE),
                  isLoading: isScanning,
                  onTap: () {
                    if (kIsWeb) {
                      _scanForWebBleDevice();
                    } else {
                      if (isScanning) {
                        _stopScan();
                      } else {
                        _startScan();
                      }
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SCAN HEADER WITH ANIMATED RADAR LABEL
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildScanHeader(bool scanning, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (scanning)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F2FE),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE)
                            .withValues(alpha: 0.4 + _pulseCtrl.value * 0.5),
                        blurRadius: 6 + _pulseCtrl.value * 4,
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              'DISCOVERED TWO-WHEELERS',
              style: GoogleFonts.robotoMono(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            LuxAudioHapticsService.lightImpact();
            _openAddVehicleModal();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.35)),
              color: const Color(0xFF00F2FE).withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 12, color: Color(0xFF00F2FE)),
                const SizedBox(width: 4),
                Text(
                  'ADD VEHICLE',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF00F2FE),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LUXURY EMPTY STATE — Animated Radar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLuxEmptyState(bool scanning, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Spatial Scanning Chamber
            AnimatedBuilder(
              animation: Listenable.merge([_radarCtrl, _pulseCtrl]),
              builder: (_, __) {
                return SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Core 3D Rings
                      for (int i = 0; i < 4; i++)
                        SpatialFloatingWidget(
                          tiltX: 0.0,
                          tiltY: 0.0,
                          zDepth: 0.0,
                          child: Container(
                            width: 120.0 + (i * 40.0),
                            height: 120.0 + (i * 40.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00F2FE).withValues(alpha: scanning ? 0.4 - (i * 0.1) : 0.1),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        
                      // Spatial Glowing Center Core
                      SpatialFloatingWidget(
                        zDepth: 0.0,
                        tiltX: 0.0,
                        tiltY: 0.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              const Color(0xFF00F2FE).withValues(alpha: 0.3),
                              const Color(0xFF00F2FE).withValues(alpha: 0.05),
                            ]),
                            border: Border.all(
                              color: const Color(0xFF00F2FE).withValues(alpha: scanning ? 0.6 : 0.3),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: scanning ? 0.4 : 0.1),
                                blurRadius: 40,
                                spreadRadius: scanning ? 10 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            scanning ? Icons.radar_rounded : Icons.bluetooth_searching_rounded,
                            color: const Color(0xFF00F2FE),
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          const SizedBox(height: 32),
          
          SpatialFloatingWidget(
            zDepth: 15,
            tiltX: 0.05,
            child: Text(
              scanning ? 'SCANNING 3D CHAMBER...' : 'CHAMBER READY',
              style: GoogleFonts.outfit(
                color: scanning ? const Color(0xFF00F2FE) : const Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              kIsWeb
                  ? 'Tap "SCAN FOR BLE DEVICES" to pair with your vehicle.'
                  : 'Ensure ignition is ON, Bluetooth pairing active.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          SpatialFloatingWidget(
            zDepth: 25,
            tiltX: -0.1, // tilt up towards the user
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (kIsWeb) ...[
                  _Lux3DButton(
                    label: 'INITIATE SCAN',
                    accentColor: const Color(0xFF00F2FE),
                    isLoading: _isWebBleScanning,
                    onTap: _scanForWebBleDevice,
                  ),
                  const SizedBox(width: 10),
                ],
                _LuxOutlinedButton(
                  label: 'MANUAL SELECTION',
                  icon: Icons.two_wheeler_rounded,
                  color: const Color(0xFF00F2FE),
                  onTap: _openManualVehicleSelector,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  // ─────────────────────────────────────────────────────────────────────────
  //  LUXURY DEVICE CARD (BLE scan result — slide-in on appear)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLuxDeviceCard(ScanResult result, bool isDark, {Key? key}) {
    final mac  = result.device.remoteId.str;
    final rssi = result.rssi;

    final idResult    = AutomaticVehicleIdentifier().identifyFromScan(
      device: result.device,
      advertisementData: result.advertisementData,
    );
    final evaluation  = VehicleCompatibilityEvaluator().evaluate(idResult.capabilities);
    final isConnecting = _connectingDeviceId == mac;

    final accentColor = idResult.isIdentified
        ? const Color(0xFF00F2FE)   // quantum cyan for identified
        : const Color(0xFF8A2BE2);  // neon violet for unknown

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _scanBorderCtrl,
        builder: (_, __) {
          final borderAlpha = idResult.isIdentified
              ? (0.25 + _scanBorderCtrl.value * 0.25)
              : 0.15;

          return RoadOSCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Device icon orb
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: borderAlpha),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: borderAlpha * 0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        idResult.isIdentified
                            ? Icons.two_wheeler_rounded
                            : Icons.bluetooth_searching_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Device info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idResult.displayName,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MAC: $mac  |  RSSI: $rssi dBm  |  ${evaluation.overallScorePercentage}% Support',
                            style: GoogleFonts.robotoMono(
                              color: const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Connect / loading
                    if (isConnecting)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    else
                      _Lux3DConnectButton(
                        label: idResult.isIdentified ? 'CONNECT' : 'PAIR',
                        accentColor: accentColor,
                        onTap: () => _doConnect(result, idResult),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Diagnostic row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          idResult.diagnosticReason,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showCompatibilityModal(idResult),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (evaluation.category == CompatibilityScoreCategory.fullyCompatible
                                    ? const Color(0xFF00E676)
                                    : Colors.amber)
                                .withValues(alpha: 0.40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              evaluation.categoryLabel,
                              style: GoogleFonts.outfit(
                                color: evaluation.category == CompatibilityScoreCategory.fullyCompatible
                                    ? const Color(0xFF00E676)
                                    : Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 13, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Connect logic (100% preserved) ─────────────────────────────────────────
  Future<void> _doConnect(ScanResult result, IdentificationResult idResult) async {
    final mac = result.device.remoteId.str;
    LuxAudioHapticsService.heavyImpact();
    setState(() => _connectingDeviceId = mac);
    try {
      await BluetoothEngine().connectAndResolve(result.device, true);
      final connected = await GenericVehicleConnectivityEngine().connectVehicle(
        targetIdentifier: mac,
        protocolAdapterId: idResult.protocolAdapterId,
      );

      if (connected) {
        _recoveryEngine.trackActiveConnection(
          targetIdentifier: mac,
          protocolAdapterId: idResult.protocolAdapterId,
        );

        final profile = VehicleProfile(
          id: 'veh_$mac',
          manufacturer: idResult.brand,
          model: idResult.model ?? 'Two-Wheeler',
          variant: idResult.variant ?? 'Connected',
          year: idResult.modelYear ?? 2024,
          category: idResult.vehicleType,
          protocolAdapter: idResult.protocolAdapterId,
          model3DUrl: '',
          thumbnailUrl: 'assets/garage/generic_bike.png',
          isVerified: idResult.isIdentified,
        );

        await _memoryService.savePairedVehicle(PairedVehicleRecord(
          id: profile.id,
          deviceIdentifier: mac,
          brand: idResult.brand,
          model: idResult.model ?? 'Two-Wheeler',
          variant: idResult.variant ?? 'Standard',
          modelYear: idResult.modelYear ?? 2024,
          category: idResult.vehicleType,
          fuelType: 'Petrol',
          protocolAdapterId: idResult.protocolAdapterId,
          capabilities: idResult.capabilities,
          compatibilityLevel: idResult.compatibilityLevel,
          pairedAt: DateTime.now(),
          lastConnectedAt: DateTime.now(),
        ));

        ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
        Global3DStateBridge().loadVehicle(profile);
        await _loadPairedVehicles();
        LuxAudioHapticsService.successPattern();
        _openLiveDashboard(profile);
      } else {
        if (mounted) {
          showLuxSnack(context, 'Vehicle connection failed. Retry.', variant: LuxSnackVariant.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showLuxSnack(context, 'Connection error: $e', variant: LuxSnackVariant.error);
      }
    } finally {
      if (mounted) setState(() => _connectingDeviceId = null);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WEB BLUETOOTH CONTENT AREA (100% preserved logic, luxury wrapper)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWebBleContentArea(bool isDark) {
    if (_connectedWebDevice != null) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [_buildConnectedWebDeviceCard(_connectedWebDevice!, isDark)],
      );
    }
    return _buildLuxEmptyState(_isWebBleScanning, isDark);
  }

  Widget _buildWebBluetoothSupportBanner(bool isDark) {
    final support     = _webBleSupport;
    final isSupported = support?.isSupported ?? false;
    final accentColor = isSupported ? const Color(0xFF00E676) : Colors.amber;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.40), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isSupported ? Icons.bluetooth_searching_rounded : Icons.info_outline_rounded,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSupported
                          ? 'Web Bluetooth Active (macOS Chrome | Secure Context)'
                          : 'Web Bluetooth Notice',
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      support?.reason ?? 'Checking browser compatibility...',
                      style: GoogleFonts.inter(
                        color: accentColor.withValues(alpha: 0.75),
                        fontSize: 10.5,
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

  Widget _buildConnectedWebDeviceCard(WebBleDevice dev, bool isDark) {
    final resolution    = _webBleResolutionResult;
    final statusCat     = resolution?.statusCategory ?? 'IDENTIFIED';
    final isVerifiedExact = resolution?.isVerified ?? false;
    final is3dReady     = resolution?.hasVerified3DModel ?? false;

    final badgeColor = statusCat == 'UNKNOWN'
        ? Colors.amber
        : (statusCat == 'MODEL_VALIDATION_PENDING'
            ? const Color(0xFF00F2FE)
            : const Color(0xFF00E676));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RoadOSCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name, badge, disconnect
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.40), width: 1),
                  ),
                  child: Icon(
                    isVerifiedExact ? Icons.verified_rounded : Icons.bluetooth_connected_rounded,
                    color: badgeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolution?.profile?.fullName ?? dev.name,
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${dev.id} | REAL BLE DETECTED',
                        style: GoogleFonts.robotoMono(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (dev.isConnected) ...[
                  _LuxOutlinedButton(
                    label: 'DASHBOARD',
                    icon: Icons.dashboard_rounded,
                    color: const Color(0xFF00E676),
                    onTap: () {
                      final activeProfile = ref.read(activeVehicleContextProvider).profile;
                      if (activeProfile != null) {
                        _openLiveDashboard(activeProfile);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _LuxOutlinedButton(
                    label: 'DISCONNECT',
                    icon: Icons.close_rounded,
                    color: const Color(0xFFFF3B5C),
                    onTap: _disconnectWebBleDevice,
                  ),
                ] else ...[
                  _Lux3DButton(
                    label: _radioState == ConnectVehicleRadioState.connecting ? 'CONNECTING...' : 'RECONNECT',
                    accentColor: const Color(0xFF00F2FE),
                    isLoading: _radioState == ConnectVehicleRadioState.connecting,
                    onTap: () => _reconnectWebBleDevice(dev.id),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Status badges
            Row(
              children: [
                _LuxBadge(label: statusCat, color: badgeColor, icon: isVerifiedExact ? Icons.check_circle_rounded : Icons.info_outline_rounded),
                const SizedBox(width: 8),
                Flexible(
                  child: _LuxBadge(
                    label: is3dReady ? '3D MODEL: OEM VERIFIED' : '3D MODEL: PENDING',
                    color: is3dReady ? const Color(0xFF00E676) : const Color(0xFF64748B),
                    icon: is3dReady ? Icons.view_in_ar_rounded : Icons.hourglass_empty_rounded,
                    maxWidth: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // GATT services inspector (100% preserved)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GATT SERVICES (${dev.services.length})',
                          style: GoogleFonts.robotoMono(color: const Color(0xFF00F2FE), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      Text('ACTIVE GATT SERVER',
                          style: GoogleFonts.robotoMono(color: const Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dev.services.isEmpty)
                    Text('No primary services exposed',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11))
                  else
                    ...dev.services.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.hub_rounded, color: Color(0xFF00F2FE), size: 13),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${s.name} (${s.characteristicsCount} chars)',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                              ),
                              Text(
                                s.uuid.length > 8 ? '${s.uuid.substring(0, 8)}…' : s.uuid,
                                style: GoogleFonts.robotoMono(color: const Color(0xFF64748B), fontSize: 10),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RECOVERY STATUS (100% logic preserved, luxury styling)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRecoveryStatus(bool isDark) {
    return StreamBuilder<RecoveryStatusSnapshot>(
      stream: _recoveryEngine.statusStream,
      initialData: _recoveryEngine.currentSnapshot,
      builder: (ctx, snapshot) {
        final r = snapshot.data;
        if (r == null ||
            r.state == ConnectionRecoveryState.idle ||
            r.state == ConnectionRecoveryState.monitoring) {
          return const SizedBox.shrink();
        }

        Color color = RoadOSColors.warningAmber;
        String text = 'Connection Lost — Auto-reconnecting attempt ${r.attemptCount}/${r.maxAttempts}...';

        if (r.state == ConnectionRecoveryState.reconnected) {
          color = RoadOSColors.apexEmerald;
          text  = 'Connection successfully restored!';
        } else if (r.state == ConnectionRecoveryState.recoveryFailed) {
          color = RoadOSColors.errorCrimson;
          text  = 'Automatic reconnection failed. Please restart vehicle ignition.';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.40)),
          ),
          child: Row(
            children: [
              Icon(Icons.sync_problem_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAIRED VEHICLES SECTION (100% logic preserved, luxury styling)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPairedVehiclesSection(dynamic activeCtx, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY SAVED VEHICLES',
          style: GoogleFonts.robotoMono(
            color: const Color(0xFF00F2FE),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _pairedVehicles.length,
            itemBuilder: (ctx, i) {
              final v = _pairedVehicles[i];
              final isActive = activeCtx.hasActiveVehicle && activeCtx.profile?.id == v.id;
              final accentColor = isActive ? const Color(0xFF00E676) : const Color(0xFF00F2FE);

              return GestureDetector(
                onTap: () async {
                  LuxAudioHapticsService.mediumImpact();
                  final success = await _memoryService.connectAutomatically(v);
                  if (success) {
                    final profile = VehicleProfile(
                      id: v.id,
                      manufacturer: v.brand,
                      model: v.model,
                      variant: v.variant,
                      year: v.modelYear,
                      category: v.category,
                      fuelType: v.fuelType,
                      protocolAdapter: v.protocolAdapterId,
                      model3DUrl: '',
                      thumbnailUrl: 'assets/garage/generic_bike.png',
                      isVerified: true,
                    );
                    ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
                    Global3DStateBridge().loadVehicle(profile);
                    _openLiveDashboard(profile);
                  }
                },
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor.withValues(alpha: isActive ? 0.55 : 0.20)),
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.10), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              v.fullName,
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 14),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            v.compatibilityLevel.name.toUpperCase(),
                            style: GoogleFonts.robotoMono(
                              color: v.compatibilityLevel == VehicleCompatibilityLevel.full
                                  ? const Color(0xFF00E676)
                                  : Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              'AUTO CONNECT',
                              style: GoogleFonts.outfit(
                                color: accentColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PRIVATE LUXURY UI COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

/// 3D press connect button with heavy haptic (primary CTA)
class _Lux3DConnectButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _Lux3DConnectButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_Lux3DConnectButton> createState() => _Lux3DConnectButtonState();
}

class _Lux3DConnectButtonState extends State<_Lux3DConnectButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _scale = 0.92);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width 3D press button for primary actions
class _Lux3DButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _Lux3DButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<_Lux3DButton> createState() => _Lux3DButtonState();
}

class _Lux3DButtonState extends State<_Lux3DButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _scale = 0.94);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.80)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              // Contact shadow
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.40),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
              // Ambient shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Outlined pill button for secondary actions
class _LuxOutlinedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _LuxOutlinedButton({required this.label, required this.color, required this.onTap, this.icon});

  @override
  State<_LuxOutlinedButton> createState() => _LuxOutlinedButtonState();
}

class _LuxOutlinedButtonState extends State<_LuxOutlinedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _scale = 0.94);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color.withValues(alpha: 0.12),
                widget.color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.color.withValues(alpha: 0.4), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 14),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill button (status bar actions)
class _LuxPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LuxPillButton({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  State<_LuxPillButton> createState() => _LuxPillButtonState();
}

class _LuxPillButtonState extends State<_LuxPillButton> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _scale = 0.93); },
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: widget.color),
              const SizedBox(width: 4),
              Text(widget.label,
                  style: GoogleFonts.outfit(
                    color: widget.color, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small labelled status badge
class _LuxBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool maxWidth;
  const _LuxBadge({required this.label, required this.color, required this.icon, this.maxWidth = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: maxWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RADAR SWEEP LINE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class SweepLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi / 2,
        colors: [
          Colors.transparent,
          const Color(0xFF00F2FE).withValues(alpha: 0.0),
          const Color(0xFF00F2FE).withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep tip line
    final tipPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, Offset(center.dx, center.dy - radius), tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
