package com.example.rideos_mobile.aaos

import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.example.rideos_mobile.aaos.RideOSAaosService

class NativeLocationAdapter : DefaultLifecycleObserver, LocationListener {

    private var locationManager: LocationManager? = null

    override fun onCreate(owner: LifecycleOwner) {
        super.onCreate(owner)
        // Note: In a production app, we check for ACCESS_FINE_LOCATION first.
        // AAOS typically grants this if requested in manifest and accepted by user.
        try {
            val context = RideOSAaosService.flutterEngine?.let {
                // Since this runs within the service context, we can fetch system service
                // Alternatively passed from Session's carContext.
                null
            }
        } catch (e: Exception) {
            // Permissions or missing context
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        super.onResume(owner)
        // Request location updates
    }

    override fun onPause(owner: LifecycleOwner) {
        super.onPause(owner)
        locationManager?.removeUpdates(this)
    }

    override fun onLocationChanged(location: Location) {
        // Push canonical hardware location UP to the headless Dart NavigationGateway
        AaosStateBridge.pushLocation(
            lat = location.latitude,
            lng = location.longitude,
            speed = (location.speed * 3.6).toDouble(), // m/s to km/h
            heading = location.bearing.toDouble()
        )
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}
