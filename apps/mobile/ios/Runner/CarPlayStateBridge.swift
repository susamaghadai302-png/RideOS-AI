import Foundation
import Flutter
import UIKit

protocol CarPlayStateBridgeDelegate: AnyObject {
    func onNavigationStarted(destination: String, distanceKm: Double, etaMinutes: Int, currentLat: Double, currentLng: Double)
    func onNavigationUpdate(instruction: String, stepDistanceMeters: Double, etaMinutes: Int, distanceKm: Double, currentLat: Double, currentLng: Double)
    func onNavigationEnded()
}

class CarPlayStateBridge {
    static let shared = CarPlayStateBridge()
    
    weak var delegate: CarPlayStateBridgeDelegate?
    private var methodChannel: FlutterMethodChannel?
    
    private init() {}
    
    func setupChannel(binaryMessenger: FlutterBinaryMessenger) {
        self.methodChannel = FlutterMethodChannel(name: "com.rideos.mobile/carplay_bridge", binaryMessenger: binaryMessenger)
        
        self.methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "onNavigationStarted":
                if let args = call.arguments as? [String: Any],
                   let destination = args["destinationTitle"] as? String,
                   let distanceKm = args["totalDistanceKm"] as? Double,
                   let etaMinutes = args["etaMinutes"] as? Int,
                   let currentLat = args["currentLat"] as? Double,
                   let currentLng = args["currentLng"] as? Double {
                    self.delegate?.onNavigationStarted(destination: destination, distanceKm: distanceKm, etaMinutes: etaMinutes, currentLat: currentLat, currentLng: currentLng)
                }
                result(true)
                
            case "onNavigationUpdate":
                if let args = call.arguments as? [String: Any],
                   let instruction = args["instruction"] as? String,
                   let stepDistanceMeters = args["stepDistanceMeters"] as? Double,
                   let etaMinutes = args["etaMinutes"] as? Int,
                   let distanceKm = args["totalDistanceKm"] as? Double,
                   let currentLat = args["currentLat"] as? Double,
                   let currentLng = args["currentLng"] as? Double {
                    self.delegate?.onNavigationUpdate(instruction: instruction, stepDistanceMeters: stepDistanceMeters, etaMinutes: etaMinutes, distanceKm: distanceKm, currentLat: currentLat, currentLng: currentLng)
                }
                result(true)
                
            case "onNavigationIdle":
                self.delegate?.onNavigationEnded()
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
