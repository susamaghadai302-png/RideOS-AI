package com.example.rideos_mobile

import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

/**
 * RideOS Android Auto / Car App Service
 *
 * This is the entry point for Android Auto integration using the
 * Android for Cars App Library (androidx.car.app).
 *
 * Architecture:
 * - CarAppService is the system-registered service that Android Auto binds to
 * - RideOSCarSession creates and returns the appropriate Screen for the vehicle display
 * - RideOSNavigationScreen renders the navigation HUD on the car head unit
 *
 * Navigation data flows from the phone app through a shared Riverpod state
 * bridge, exposed via a Flutter MethodChannel. The car session observes this
 * and updates the car screen template accordingly.
 *
 * Limitations:
 * - Full navigation template (NavigationTemplate) requires the
 *   NAVIGATION category in the manifest and Google Play Store review
 * - This implementation correctly declares the category and uses
 *   NavigationTemplate as the primary surface
 * - Without store approval, the navigation template renders in limited mode
 *   on production devices; it works fully on the Desktop Head Unit emulator
 * - Map rendering on the HU is done via SurfaceCallback on supported hosts
 */
class RideOSCarAppService : CarAppService() {

    /**
     * Creates a new car app session when Android Auto connects.
     * The session lifecycle mirrors the car connection lifecycle.
     */
    override fun onCreateSession(): Session {
        return RideOSCarSession()
    }

    /**
     * Host validator controls which Android Auto hosts can bind to this service.
     *
     * ALLOW_ALL_HOSTS is appropriate during development and debugging.
     * In production, restrict to known Google hosts by returning
     * HostValidator.createDefaultHostValidator(packageManager) instead.
     */
    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }
}
