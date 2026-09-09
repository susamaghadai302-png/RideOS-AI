import CarPlay
import UIKit
import GoogleMaps

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate {

    var interfaceController: CPInterfaceController?
    var mapTemplate: CPMapTemplate?
    var mapView: GMSMapView?
    var navigationSession: CPNavigationSession?
    var currentTrip: CPTrip?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Initialize the root Map Template
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        self.mapTemplate = mapTemplate
        
        // Set root template
        interfaceController.setRootTemplate(mapTemplate, animated: false, completion: nil)
        
        // Initialize Google Maps View on the CarPlay Window
        let carWindow = templateApplicationScene.carWindow
        
        // We use a basic UIViewController to hold the GMSMapView
        let mapViewController = UIViewController()
        
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 15)
        let mapView = GMSMapView.map(withFrame: carWindow.bounds, camera: camera)
        
        // Basic CarPlay map settings
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        
        mapViewController.view = mapView
        self.mapView = mapView
        
        carWindow.rootViewController = mapViewController
        
        // Setup State Bridge to receive updates from Flutter
        CarPlayStateBridge.shared.delegate = self
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        self.mapTemplate = nil
        self.mapView = nil
        self.navigationSession = nil
        CarPlayStateBridge.shared.delegate = nil
    }
}

// MARK: - CarPlayStateBridgeDelegate
extension CarPlaySceneDelegate: CarPlayStateBridgeDelegate {
    
    func onNavigationStarted(destination: String, distanceKm: Double, etaMinutes: Int, currentLat: Double, currentLng: Double) {
        guard let mapTemplate = self.mapTemplate else { return }
        
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLng)))
        let dest = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLng))) // Dummy for now
        dest.name = destination
        
        let routeChoice = CPRouteChoice(summaryVariants: ["Route"], additionalInformationVariants: ["Recommended"], selectionTraits: [])
        
        let trip = CPTrip(origin: origin, destination: dest, routeChoices: [routeChoice])
        self.currentTrip = trip
        
        // Start Navigation Session
        self.navigationSession = mapTemplate.startNavigationSession(for: trip)
        
        // Update Map Camera
        self.updateMapCamera(lat: currentLat, lng: currentLng)
    }
    
    func onNavigationUpdate(instruction: String, stepDistanceMeters: Double, etaMinutes: Int, distanceKm: Double, currentLat: Double, currentLng: Double) {
        guard let session = self.navigationSession else { return }
        
        // Update Maneuver
        let maneuver = CPManeuver()
        maneuver.instructionVariants = [instruction]
        // In a full implementation, we'd add symbols and detailed maneuver types
        
        // Travel Estimates
        let distance = Measurement(value: distanceKm, UnitLength.kilometers)
        let travelEstimates = CPTravelEstimates(distanceRemaining: distance, timeRemaining: TimeInterval(etaMinutes * 60))
        
        session.updateEstimates(travelEstimates, for: maneuver)
        
        self.updateMapCamera(lat: currentLat, lng: currentLng)
    }
    
    func onNavigationEnded() {
        self.navigationSession?.finish()
        self.navigationSession = nil
        self.currentTrip = nil
    }
    
    private func updateMapCamera(lat: Double, lng: Double) {
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        self.mapView?.animate(toLocation: location)
    }
}
