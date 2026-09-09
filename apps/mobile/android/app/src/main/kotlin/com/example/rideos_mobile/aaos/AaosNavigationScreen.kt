package com.example.rideos_mobile.aaos

import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.SurfaceCallback
import androidx.car.app.SurfaceContainer
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.Distance
import androidx.car.app.navigation.model.Destination
import androidx.car.app.navigation.model.Maneuver
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.navigation.model.RoutingInfo
import androidx.car.app.navigation.model.Step
import androidx.car.app.navigation.model.TravelEstimate
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

class AaosNavigationScreen(
    carContext: CarContext,
    private val session: RideOSAaosSession
) : Screen(carContext), DefaultLifecycleObserver, AaosStateBridge.NavigationStateListener {

    private var virtualDisplay: VirtualDisplay? = null
    
    // Canonical State received from Dart
    private var isNavigating = false
    private var currentInstruction = "Calculating route..."
    private var currentDistanceMeters = 0.0
    private var etaMinutes = 0
    private var distanceKm = 0.0
    private var destinationTitle = "Destination"

    init {
        lifecycle.addObserver(this)
        AaosStateBridge.navigationListener = this
    }

    private val surfaceCallback = object : SurfaceCallback {
        override fun onSurfaceAvailable(surfaceContainer: SurfaceContainer) {
            val surface = surfaceContainer.surface ?: return
            
            // Unpack physical dimensions from AAOS vehicle screen
            val width = surfaceContainer.width
            val height = surfaceContainer.height
            val dpi = surfaceContainer.dpi
            
            val displayManager = carContext.getSystemService(DisplayManager::class.java)
            virtualDisplay = displayManager.createVirtualDisplay(
                "RideOSAaosDisplay",
                width,
                height,
                dpi,
                surface,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_OWN_CONTENT_ONLY
            )
            
            virtualDisplay?.display?.let { display ->
                val presentation = AaosMapPresentation(carContext, display)
                presentation.show()
                session.mapPresentation = presentation
            }
        }

        override fun onSurfaceDestroyed(surfaceContainer: SurfaceContainer) {
            session.mapPresentation?.dismiss()
            session.mapPresentation = null
            virtualDisplay?.release()
            virtualDisplay = null
        }
    }

    override fun onGetTemplate(): androidx.car.app.model.Template {
        // Automotive Native UI Template
        val builder = NavigationTemplate.Builder()
        builder.setActionStrip(
            androidx.car.app.model.ActionStrip.Builder()
                .addAction(
                    Action.Builder()
                        .setTitle("Stop")
                        .setOnClickListener {
                            AaosStateBridge.stopNavigation()
                        }
                        .build()
                )
                .build()
        )
        
        if (isNavigating) {
            val maneuver = Maneuver.Builder(Maneuver.TYPE_UNKNOWN).build()
            val step = Step.Builder(currentInstruction)
                .setManeuver(maneuver)
                .build()

            val routingInfo = RoutingInfo.Builder()
                .setCurrentStep(step, Distance.create(currentDistanceMeters, Distance.UNIT_METERS))
                .build()
                
            builder.setNavigationInfo(routingInfo)

            val dest = Destination.Builder()
                .setName(destinationTitle)
                .build()
                
            val travelEstimate = TravelEstimate.Builder(
                Distance.create(distanceKm, Distance.UNIT_KILOMETERS),
                androidx.car.app.model.DateTimeWithZone.create(
                    System.currentTimeMillis() + (etaMinutes * 60000L),
                    java.util.TimeZone.getDefault()
                )
            ).build()

            builder.setDestinationTravelEstimate(travelEstimate)
        }
        
        return builder.build()
    }

    override fun onNavigationUpdate(
        instruction: String,
        stepDistanceMeters: Double,
        etaMins: Int,
        totalDistanceKm: Double,
        destTitle: String,
        currentLat: Double,
        currentLng: Double
    ) {
        currentInstruction = instruction
        currentDistanceMeters = stepDistanceMeters
        etaMinutes = etaMins
        distanceKm = totalDistanceKm
        destinationTitle = destTitle
        isNavigating = true
        
        session.mapPresentation?.updateMapState(currentLat, currentLng)
        invalidate()
    }

    override fun onNavigationIdle() {
        isNavigating = false
        invalidate()
    }

    override fun onCreate(owner: LifecycleOwner) {
        super.onCreate(owner)
        carContext.getCarService(androidx.car.app.AppManager::class.java)
            .setSurfaceCallback(surfaceCallback)
    }
}
