package com.example.rideos_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Template
import androidx.car.app.navigation.model.Destination
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.navigation.model.RoutingInfo
import androidx.car.app.navigation.model.Step
import androidx.car.app.navigation.model.TravelEstimate
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/**
 * RideOS Navigation Screen for Android Auto
 */
class RideOSNavigationScreen(
    carContext: CarContext,
    private val session: RideOSCarSession,
    private val destinationName: String? = null
) : Screen(carContext), DefaultLifecycleObserver {

    // Navigation state updated from Flutter via MethodChannel -> Broadcast
    private var currentInstruction: String = "Starting navigation..."
    private var currentDistanceMeters: Double = 0.0
    private var etaMinutes: Int = 0
    private var distanceKm: Double = 0.0
    private var isNavigating: Boolean = false
    private var destinationTitle: String = destinationName ?: "Destination"

    private val navReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.rideos.mobile.NAV_UPDATE") {
                updateNavigationState(
                    instruction = intent.getStringExtra("instruction") ?: "",
                    stepDistanceMeters = intent.getDoubleExtra("stepDistanceMeters", 0.0),
                    etaMins = intent.getIntExtra("etaMinutes", 0),
                    totalDistKm = intent.getDoubleExtra("totalDistanceKm", 0.0),
                    destTitle = intent.getStringExtra("destinationTitle") ?: "Destination",
                    currentLat = intent.getDoubleExtra("currentLat", 0.0),
                    currentLng = intent.getDoubleExtra("currentLng", 0.0)
                )
            } else if (intent?.action == "com.rideos.mobile.NAV_STOP") {
                stopNavigation()
            }
        }
    }

    init {
        lifecycle.addObserver(this)
    }

    override fun onCreate(owner: LifecycleOwner) {
        val filter = IntentFilter().apply {
            addAction("com.rideos.mobile.NAV_UPDATE")
            addAction("com.rideos.mobile.NAV_STOP")
        }
        carContext.registerReceiver(navReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    override fun onDestroy(owner: LifecycleOwner) {
        try {
            carContext.unregisterReceiver(navReceiver)
        } catch (e: Exception) {
            // Ignored
        }
    }

    override fun onGetTemplate(): Template {
        return if (isNavigating) {
            buildNavigationTemplate()
        } else {
            buildIdleTemplate()
        }
    }

    private fun buildNavigationTemplate(): Template {
        val step = Step.Builder(currentInstruction)
            .build()

        val dest = Destination.Builder()
            .setName(destinationTitle)
            .build()

        val travelEstimate = TravelEstimate.Builder(
            currentDistanceKm(),
            java.time.ZonedDateTime.now().plusMinutes(etaMinutes.toLong())
        ).build()

        val routingInfo = RoutingInfo.Builder()
            .setCurrentStep(step, currentDistanceToStep())
            .build()

        return NavigationTemplate.Builder()
            .setNavigationInfo(routingInfo)
            .setDestinationTravelEstimate(travelEstimate)
            .setActionStrip(buildActionStrip())
            .build()
    }

    private fun buildIdleTemplate(): Template {
        return MessageTemplate.Builder(
            if (destinationName != null) "Navigating to $destinationName" else "RideOS Navigation\nReady to start"
        )
            .setTitle("RideOS")
            .addAction(
                Action.Builder()
                    .setTitle("Open on Phone")
                    .setOnClickListener { carContext.startActivity(
                        carContext.packageManager.getLaunchIntentForPackage(carContext.packageName)
                            ?: return@setOnClickListener
                    )}
                    .build()
            )
            .build()
    }

    private fun buildActionStrip() = androidx.car.app.model.ActionStrip.Builder()
        .addAction(
            Action.Builder()
                .setTitle("Mute")
                .setOnClickListener { /* Mute via MethodChannel */ }
                .build()
        )
        .build()

    // ── State update methods called from PhoneVehicleStateBridge ─────────────

    fun updateNavigationState(
        instruction: String,
        stepDistanceMeters: Double,
        etaMins: Int,
        totalDistKm: Double,
        destTitle: String,
        currentLat: Double,
        currentLng: Double
    ) {
        currentInstruction = instruction
        currentDistanceMeters = stepDistanceMeters
        etaMinutes = etaMins
        distanceKm = totalDistKm
        destinationTitle = destTitle
        isNavigating = true
        
        session.mapPresentation?.updateMapState(currentLat, currentLng)
        
        invalidate()
    }

    fun stopNavigation() {
        isNavigating = false
        invalidate()
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private fun currentDistanceKm(): androidx.car.app.model.Distance {
        val meters = (currentDistanceMeters).toLong().coerceAtLeast(0)
        return if (meters < 1000) {
            androidx.car.app.model.Distance.create(meters.toDouble(), androidx.car.app.model.Distance.UNIT_METERS)
        } else {
            androidx.car.app.model.Distance.create(distanceKm, androidx.car.app.model.Distance.UNIT_KILOMETERS)
        }
    }

    private fun currentDistanceToStep(): androidx.car.app.model.Distance {
        val meters = currentDistanceMeters.toLong().coerceAtLeast(0)
        return if (meters < 1000) {
            androidx.car.app.model.Distance.create(meters.toDouble(), androidx.car.app.model.Distance.UNIT_METERS)
        } else {
            androidx.car.app.model.Distance.create(meters / 1000.0, androidx.car.app.model.Distance.UNIT_KILOMETERS)
        }
    }
}
