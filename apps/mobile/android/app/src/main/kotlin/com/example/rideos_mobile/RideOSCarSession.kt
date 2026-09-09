package com.example.rideos_mobile

import android.content.Intent
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import androidx.car.app.AppManager
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.ScreenManager
import androidx.car.app.Session
import androidx.car.app.SurfaceCallback
import androidx.car.app.SurfaceContainer
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/**
 * RideOS Car App Session
 *
 * The Session manages the Android Auto connection lifecycle.
 * In Tier 7, we implement SurfaceCallback to capture the hardware Surface 
 * provided by the vehicle, create a VirtualDisplay, and mount a Real Map 
 * Presentation (NavigationViewForAuto) to fulfill the geographic map requirement.
 */
class RideOSCarSession : Session(), SurfaceCallback, DefaultLifecycleObserver {

    private var virtualDisplay: VirtualDisplay? = null
    var mapPresentation: MapPresentation? = null
        private set
        
    private var isSessionResumed = false

    init {
        lifecycle.addObserver(this)
    }

    override fun onCreateScreen(intent: Intent): Screen {
        // Register the SurfaceCallback to project the real map
        carContext.getCarService(AppManager::class.java).setSurfaceCallback(this)
        
        return RideOSNavigationScreen(carContext, this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val dest = intent.data?.getQueryParameter("dest")
        if (dest != null) {
            val screenManager = carContext.getCarService(ScreenManager::class.java)
            screenManager.push(RideOSNavigationScreen(carContext, this, dest))
        }
    }

    // ── Session Lifecycle (Forwarded to MapPresentation) ─────────────────────

    override fun onResume(owner: LifecycleOwner) {
        isSessionResumed = true
        mapPresentation?.notifyStart()
    }

    override fun onPause(owner: LifecycleOwner) {
        isSessionResumed = false
        mapPresentation?.notifyStop()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        mapPresentation?.notifyDestroy()
        mapPresentation?.dismiss()
        mapPresentation = null
        
        virtualDisplay?.release()
        virtualDisplay = null
    }

    // ── SurfaceCallback Implementation (Real Map Projection) ─────────────────

    override fun onSurfaceAvailable(surfaceContainer: SurfaceContainer) {
        val surface = surfaceContainer.surface ?: return
        if (!surface.isValid) return
        
        val width = surfaceContainer.width
        val height = surfaceContainer.height
        val dpi = surfaceContainer.dpi
        
        // Use Android DisplayManager to create a VirtualDisplay mapping to the Car Surface
        val displayManager = carContext.getSystemService(DisplayManager::class.java)
        virtualDisplay = displayManager.createVirtualDisplay(
            "RideOS_AndroidAuto_Map_Display",
            width,
            height,
            dpi,
            surface,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_OWN_CONTENT_ONLY
        )
        
        // Instantiate our MapPresentation which holds the Google Navigation SDK
        virtualDisplay?.display?.let { display ->
            mapPresentation = MapPresentation(carContext, display)
            mapPresentation?.show()
            
            if (isSessionResumed) {
                mapPresentation?.notifyStart()
            }
        }
    }

    override fun onVisibleAreaChanged(visibleArea: Rect) {
        // The Navigation SDK handles dynamic resizing internally if the layout
        // parameters are MATCH_PARENT.
    }

    override fun onStableAreaChanged(stableArea: Rect) {}

    override fun onSurfaceDestroyed(surfaceContainer: SurfaceContainer) {
        mapPresentation?.notifyStop()
        mapPresentation?.dismiss()
        mapPresentation = null
        
        virtualDisplay?.release()
        virtualDisplay = null
    }
    
    override fun onScroll(distanceX: Float, distanceY: Float) {}
    override fun onFling(velocityX: Float, velocityY: Float) {}
    override fun onScale(focusX: Float, focusY: Float, scaleFactor: Float) {}
}
