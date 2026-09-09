package com.example.rideos_mobile.aaos

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AaosStateBridge : MethodChannel.MethodCallHandler {

    var navigationListener: NavigationStateListener? = null

    interface NavigationStateListener {
        fun onNavigationUpdate(
            instruction: String,
            stepDistanceMeters: Double,
            etaMinutes: Int,
            totalDistanceKm: Double,
            destinationTitle: String,
            currentLat: Double,
            currentLng: Double
        )
        fun onNavigationIdle()
    }

    fun init() {
        RideOSAaosService.methodChannel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "onNavigationUpdate" -> {
                val instruction = call.argument<String>("instruction") ?: ""
                val stepDistanceMeters = call.argument<Double>("stepDistanceMeters") ?: 0.0
                val etaMinutes = call.argument<Int>("etaMinutes") ?: 0
                val totalDistanceKm = call.argument<Double>("totalDistanceKm") ?: 0.0
                val destinationTitle = call.argument<String>("destinationTitle") ?: "Destination"
                val currentLat = call.argument<Double>("currentLat") ?: 0.0
                val currentLng = call.argument<Double>("currentLng") ?: 0.0

                navigationListener?.onNavigationUpdate(
                    instruction, stepDistanceMeters, etaMinutes, totalDistanceKm, destinationTitle, currentLat, currentLng
                )
                result.success(true)
            }
            "onNavigationIdle" -> {
                navigationListener?.onNavigationIdle()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    fun pushLocation(lat: Double, lng: Double, speed: Double, heading: Double) {
        RideOSAaosService.methodChannel?.invokeMethod("pushLocation", mapOf(
            "lat" to lat,
            "lng" to lng,
            "speed" to speed,
            "heading" to heading
        ))
    }
    
    fun stopNavigation() {
        RideOSAaosService.methodChannel?.invokeMethod("stopNavigation", null)
    }
}
