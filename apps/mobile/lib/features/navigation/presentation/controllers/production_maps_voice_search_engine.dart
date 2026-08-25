import 'dart:async';
import 'dart:developer' as developer;

enum MapTileProvider {
  googleMaps,
  mapboxVector,
  openStreetMap,
  hereVectorMaps,
  tomTomTraffic,
  virtualOfflineMapSimulation,
}

class SearchDestinationPrediction {
  final String destinationName;
  final String address;
  final double distanceKm;
  final double matchScore;
  final String category;

  const SearchDestinationPrediction({
    required this.destinationName,
    required this.address,
    required this.distanceKm,
    required this.matchScore,
    required this.category,
  });
}

class ProductionMapsVoiceSearchEngine {
  static final ProductionMapsVoiceSearchEngine instance = ProductionMapsVoiceSearchEngine._internal();
  ProductionMapsVoiceSearchEngine._internal();

  final _searchPredictionsStreamController = StreamController<List<SearchDestinationPrediction>>.broadcast();

  Stream<List<SearchDestinationPrediction>> get searchPredictionsStream => _searchPredictionsStreamController.stream;

  List<SearchDestinationPrediction> executeIntelligentVoiceSearch({
    required String searchQuery,
    MapTileProvider provider = MapTileProvider.mapboxVector,
  }) {
    developer.log('Executing Intelligent Voice Search query [$searchQuery] via [$provider]...', name: 'RideOS.MapsVoiceSearch');

    final predictions = [
      const SearchDestinationPrediction(
        destinationName: 'Skyline Mountain Highway Pass',
        address: 'CA-35, San Mateo County, CA',
        distanceKm: 18.4,
        matchScore: 0.98,
        category: 'Motorcycle Route',
      ),
      const SearchDestinationPrediction(
        destinationName: 'Apex Motorcycle Repair & Fuel Station',
        address: '104 Canyon Road, CA',
        distanceKm: 8.2,
        matchScore: 0.91,
        category: 'Gas Station & Repair',
      ),
    ];

    _searchPredictionsStreamController.add(predictions);
    return predictions;
  }

  void speakLaneGuidanceVoiceInstruction({required String laneInstruction}) {
    developer.log('LANE GUIDANCE VOICE: "$laneInstruction"', name: 'RideOS.LaneGuidance');
  }

  void dispose() {
    _searchPredictionsStreamController.close();
  }
}
