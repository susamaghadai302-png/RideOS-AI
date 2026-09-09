package com.example.rideos_mobile.aaos

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.navigation.NavigationViewForAuto

class AaosMapPresentation(
    outerContext: Context,
    display: Display
) : Presentation(outerContext, display) {

    private lateinit var navigationView: NavigationViewForAuto
    private var googleMap: GoogleMap? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Ensure standard presentation window parameters
        window?.setType(WindowManager.LayoutParams.TYPE_PRIVATE_PRESENTATION)
        
        // Initialize the Native Google Navigation View for Android Automotive
        navigationView = NavigationViewForAuto(context)
        setContentView(navigationView)
        
        navigationView.onCreate(savedInstanceState)
        
        navigationView.getMapAsync { map ->
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
    fun onResume() = navigationView.onResume()
    fun onPause() = navigationView.onPause()
    fun onDestroy() = navigationView.onDestroy()
}
