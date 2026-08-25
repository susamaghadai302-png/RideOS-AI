import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/cockpit/presentation/screens/cockpit_command_center_screen.dart';
import '../../features/garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../features/navigation/presentation/screens/three_d_navigation_screen.dart';
import '../design_system/premium_navigation.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String garage = '/garage';
  static const String cockpit = '/cockpit';
  static const String showroom = '/showroom';
  static const String navigationHud = '/navigation-hud';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return premiumRoute(const WelcomeScreen());
      case AppRoutes.garage:
        return premiumRoute(const LuxuryGarageShowroomScreen());
      case AppRoutes.cockpit:
        return premiumRoute(const CockpitCommandCenterScreen());
      case AppRoutes.showroom:
        return premiumRoute(const LuxuryGarageShowroomScreen());
      case AppRoutes.navigationHud:
        return premiumRoute(const ThreeDNavigationScreen());

      default:
        return premiumRoute(Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ));
    }
  }
}
