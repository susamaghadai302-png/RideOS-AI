package com.example.rideos_mobile.aaos

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.LatLng

class AaosMapPresentation(
    outerContext: Context,
    display: Display
) : Presentation(outerContext, display) {

    private lateinit var mapView: MapView
    private var googleMap: GoogleMap? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Ensure standard presentation window parameters
        window?.setType(WindowManager.LayoutParams.TYPE_PRIVATE_PRESENTATION)
        
        // Initialize the Native Google MapView for Android Automotive
        mapView = MapView(context)
        setContentView(mapView)
        
        mapView.onCreate(savedInstanceState)
        
        mapView.getMapAsync { map ->
            googleMap = map
            
            // Automotive-safe constraints
            map.uiSettings.isCompassEnabled = false
            map.uiSettings.isMapToolbarEnabled = false
            map.uiSettings.isZoomControlsEnabled = false // Managed by AAOS templates
        }
    }

    fun updateMapState(currentLat: Double, currentLng: Double) {
        val currentLoc = LatLng(currentLat, currentLng)
        // Ensure we don't calculate routes here. Just visualize the canonical position.
        googleMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(currentLoc, 16f))
    }
    
    // Lifecycle forwarding
    fun onResume() = mapView.onResume()
    fun onPause() = mapView.onPause()
    fun onDestroy() = mapView.onDestroy()
}
