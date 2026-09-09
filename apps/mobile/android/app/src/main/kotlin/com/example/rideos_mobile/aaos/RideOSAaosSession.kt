package com.example.rideos_mobile.aaos

import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

class RideOSAaosSession : Session(), DefaultLifecycleObserver {

    var mapPresentation: AaosMapPresentation? = null
    private val locationAdapter = NativeLocationAdapter()

    override fun onCreateScreen(intent: Intent): Screen {
        AaosStateBridge.init()
        
        lifecycle.addObserver(this)
        lifecycle.addObserver(locationAdapter)
        
        val screen = AaosNavigationScreen(carContext, this)
        
        // Delay to ensure Surface is ready before presentation creation
        Handler(Looper.getMainLooper()).postDelayed({
            // Projection happens through SurfaceCallback mapped to VirtualDisplay
        }, 500)
        
        return screen
    }

    override fun onDestroy(owner: LifecycleOwner) {
        super.onDestroy(owner)
        mapPresentation?.dismiss()
        mapPresentation = null
    }
}
