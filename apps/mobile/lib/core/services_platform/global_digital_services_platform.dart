import 'dart:developer' as developer;

class RegisteredServiceInfo {
  final String serviceId;
  final String category; // 'RIDE', 'VEHICLE', 'PAYMENT', 'IDENTITY', 'FLEET', 'AI'
  final String version;
  final String healthStatus;

  const RegisteredServiceInfo({
    required this.serviceId,
    required this.category,
    required this.version,
    required this.healthStatus,
  });
}

class MobilityOffer {
  final String offerId;
  final String offerType; // 'EV_CHARGING', 'ROADSIDE_ASSISTANCE', 'PARKING_SPOT', 'FUEL_DISCOUNT'
  final String providerName;
  final double estimatedCost;
  final String currency;

  const MobilityOffer({
    required this.offerId,
    required this.offerType,
    required this.providerName,
    required this.estimatedCost,
    required this.currency,
  });
}

class GlobalDigitalServicesPlatform {
  static final GlobalDigitalServicesPlatform instance = GlobalDigitalServicesPlatform._internal();
  GlobalDigitalServicesPlatform._internal();

  List<RegisteredServiceInfo> discoverServices() {
    developer.log('Discovering registered digital services...', name: 'RideOS.DigitalServicesPlatform');
    return const [
      RegisteredServiceInfo(serviceId: 'srv_ride_core', category: 'RIDE', version: 'v5.3.0', healthStatus: 'HEALTHY'),
      RegisteredServiceInfo(serviceId: 'srv_ai_inference', category: 'AI', version: 'v5.3.0', healthStatus: 'HEALTHY'),
      RegisteredServiceInfo(serviceId: 'srv_fleet_telematics', category: 'FLEET', version: 'v5.3.0', healthStatus: 'HEALTHY'),
      RegisteredServiceInfo(serviceId: 'srv_payment_vault', category: 'PAYMENT', version: 'v5.3.0', healthStatus: 'HEALTHY'),
    ];
  }

  List<MobilityOffer> getNearbyMobilityOffers({required double lat, required double lng}) {
    return const [
      MobilityOffer(offerId: 'ev_charge_fast_01', offerType: 'EV_CHARGING', providerName: 'ChargePoint SuperFast 150kW', estimatedCost: 12.50, currency: 'USD'),
      MobilityOffer(offerId: 'roadside_help_express', offerType: 'ROADSIDE_ASSISTANCE', providerName: 'AAA Motorcycle Rescue', estimatedCost: 0.00, currency: 'USD'),
      MobilityOffer(offerId: 'parking_reserve_bay', offerType: 'PARKING_SPOT', providerName: 'Secure Bike Park Downtown', estimatedCost: 4.00, currency: 'USD'),
    ];
  }
}
