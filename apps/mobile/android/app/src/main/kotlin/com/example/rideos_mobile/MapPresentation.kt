package com.example.rideos_mobile

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.view.Display
import android.view.ViewGroup
import android.widget.FrameLayout
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.PolylineOptions

/**
 * Android Auto Virtual Display Presentation
 * 
 * Maps the standard Google Maps MapView onto the
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

    private lateinit var mapView: MapView
    private var googleMap: GoogleMap? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Instantiate the standard Google MapView
        mapView = MapView(context)
        val layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        mapView.layoutParams = layoutParams
        
        setContentView(mapView)
        
        // Initialize the view with an empty bundle
        mapView.onCreate(savedInstanceState)
        
        // Asynchronously acquire the GoogleMap surface
        mapView.getMapAsync { map ->
            googleMap = map
            map.uiSettings.isMapToolbarEnabled = false
            map.uiSettings.isZoomControlsEnabled = false
            map.uiSettings.isCompassEnabled = false
            
            // Set regional fallback location (Bhubaneswar, Odisha) until canonical updates arrive
            val defaultLoc = LatLng(20.2961, 85.8245)
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
        if (::mapView.isInitialized) {
            mapView.onStart()
            mapView.onResume()
        }
    }

    fun notifyStop() {
        if (::mapView.isInitialized) {
            mapView.onPause()
            mapView.onStop()
        }
    }

    fun notifyDestroy() {
        if (::mapView.isInitialized) {
            mapView.onDestroy()
        }
    }
}
