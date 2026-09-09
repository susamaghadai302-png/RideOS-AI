package com.example.rideos_mobile

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.view.Display
import android.view.ViewGroup
import android.widget.FrameLayout
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PolylineOptions
import com.google.android.libraries.navigation.NavigationViewForAuto

/**
 * Android Auto Virtual Display Presentation
 * 
 * Maps the official Google Navigation SDK NavigationViewForAuto onto the 
 * Android Auto Surface provided by the vehicle DHU.
 * 
 * This presentation maintains strict boundary safety by merely acting as a 
 * "dumb" projection surface. It does NOT invoke a secondary NavigationApi 
 * route calculator. Instead, it consumes canonical coordinates from the 
 * existing Tier 4 NavigationBloc and renders them onto a real geographic map.
 */
class MapPresentation(
    outerContext: Context, 
    display: Display
) : Presentation(outerContext, display) {

    private lateinit var navigationView: NavigationViewForAuto
    private var googleMap: GoogleMap? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Instantiate the official Android Auto Navigation View
        navigationView = NavigationViewForAuto(context)
        val layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        navigationView.layoutParams = layoutParams
        
        setContentView(navigationView)
        
        // Initialize the view with an empty bundle
        navigationView.onCreate(savedInstanceState)
        
        // Asynchronously acquire the GoogleMap surface
        navigationView.getMapAsync { map ->
            googleMap = map
            map.uiSettings.isMapToolbarEnabled = false
            map.uiSettings.isZoomControlsEnabled = false
            map.uiSettings.isCompassEnabled = false
            
            // Set a default location until canonical updates arrive
            val defaultLoc = LatLng(37.7749, -122.4194)
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(defaultLoc, 15f))
        }
    }
    
    /**
     * Consumes canonical route updates from NavigationBloc and renders them 
     * on the actual geographic map surface.
     */
    fun updateMapState(currentLat: Double, currentLng: Double) {
        val loc = LatLng(currentLat, currentLng)
        googleMap?.let { map ->
            map.animateCamera(CameraUpdateFactory.newLatLng(loc))
            
            // In a full implementation, we would draw the canonical route polyline here.
            // For now, we center the real map on the vehicle and draw a marker to satisfy
            // the visual DHU map requirements.
            map.clear()
            map.addMarker(MarkerOptions().position(loc).title("Vehicle"))
        }
    }

    // ── Lifecycle Forwarding ────────────────────────────────────────────────

    fun notifyStart() {
        if (::navigationView.isInitialized) {
            navigationView.onStart()
            navigationView.onResume()
        }
    }

    fun notifyStop() {
        if (::navigationView.isInitialized) {
            navigationView.onPause()
            navigationView.onStop()
        }
    }

    fun notifyDestroy() {
        if (::navigationView.isInitialized) {
            navigationView.onDestroy()
        }
    }
}
