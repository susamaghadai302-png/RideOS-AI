enum MotorcycleOemBrand {
  bmwMotorrad('BMW Motorrad', 'Connectivity OS v3.2'),
  honda('Honda', 'RoadSync System'),
  yamaha('Yamaha', 'Y-Connect Telematics'),
  ktm('KTM', 'MY RIDE Navigation'),
  royalEnfield('Royal Enfield', 'Tripper Navigation'),
  tvs('TVS', 'SmartXonnect'),
  bajaj('Bajaj', 'Ride Connect'),
  suzuki('Suzuki', 'Ride Connect App'),
  hero('Hero', 'xPulse Telematics');

  final String brandName;
  final String apiProtocol;

  const MotorcycleOemBrand(this.brandName, this.apiProtocol);
}

class OemIntegrationAdapter {
  static final OemIntegrationAdapter _instance = OemIntegrationAdapter._internal();
  factory OemIntegrationAdapter() => _instance;
  OemIntegrationAdapter._internal();

  MotorcycleOemBrand _activeBrand = MotorcycleOemBrand.yamaha;

  MotorcycleOemBrand get activeBrand => _activeBrand;

  void selectOemBrand(MotorcycleOemBrand brand) {
    _activeBrand = brand;
  }

  Map<String, dynamic> getOemCapabilities() {
    return {
      'brand': _activeBrand.brandName,
      'protocol': _activeBrand.apiProtocol,
      'supportsTpms': true,
      'supportsCanBusRead': true,
      'supportsHeatedGripsControl': _activeBrand == MotorcycleOemBrand.bmwMotorrad || _activeBrand == MotorcycleOemBrand.ktm,
      'supportsRidingModesToggle': true,
      'supportsQuickshifterStatus': _activeBrand == MotorcycleOemBrand.yamaha || _activeBrand == MotorcycleOemBrand.bmwMotorrad,
    };
  }
}
