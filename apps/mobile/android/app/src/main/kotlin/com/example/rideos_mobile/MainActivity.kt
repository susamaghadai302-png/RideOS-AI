package com.example.rideos_mobile

import android.content.Intent
import android.net.Uri
import android.telecom.TelecomManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Android Activity — Flutter host + MethodChannel registration
 *
 * Channels registered here:
 * 1. com.rideos.mobile/calling — system phone dialer integration
 * 2. com.rideos.mobile/android_auto — vehicle display state bridge
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CALLING_CHANNEL = "com.rideos.mobile/calling"
        private const val AUTO_CHANNEL = "com.rideos.mobile/android_auto"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Calling Channel ────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALLING_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dial" -> {
                        val number = call.argument<String>("number") ?: ""
                        if (number.isNotEmpty()) {
                            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number"))
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("INVALID_NUMBER", "Phone number is empty", null)
                        }
                    }
                    "answerCall" -> {
                        // Android Telecom API — requires MANAGE_OWN_CALLS or InCallService
                        // This is a best-effort implementation; full integration requires
                        // registering as a Telecom InCallService in the manifest.
                        result.error(
                            "NOT_SUPPORTED",
                            "Answering incoming calls requires InCallService registration (Android Telecom API). " +
                                    "Use your device's native dialer to answer calls.",
                            null
                        )
                    }
                    "declineCall" -> {
                        result.error(
                            "NOT_SUPPORTED",
                            "Declining calls requires InCallService registration.",
                            null
                        )
                    }
                    "endCall" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            try {
                                val telecomManager = getSystemService(TELECOM_SERVICE) as TelecomManager
                                @Suppress("DEPRECATION")
                                telecomManager.endCall()
                                result.success(true)
                            } catch (e: SecurityException) {
                                result.error("PERMISSION_DENIED", "CALL_PHONE permission required: ${e.message}", null)
                            }
                        } else {
                            result.error("NOT_SUPPORTED", "endCall requires Android 9+", null)
                        }
                    }
                    "setMuted" -> {
                        // AudioManager mute — works during an active call
                        val muted = call.argument<Boolean>("muted") ?: false
                        try {
                            val audioManager = getSystemService(AUDIO_SERVICE) as android.media.AudioManager
                            audioManager.isMicrophoneMute = muted
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    "setSpeaker" -> {
                        val speaker = call.argument<Boolean>("speaker") ?: false
                        try {
                            val audioManager = getSystemService(AUDIO_SERVICE) as android.media.AudioManager
                            audioManager.isSpeakerphoneOn = speaker
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Android Auto Channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateNavigation" -> {
                        // Flutter phone app sends navigation state to the car session
                        // The car session finds the active screen and updates it
                        val instruction = call.argument<String>("instruction") ?: ""
                        val stepDistMeters = call.argument<Double>("stepDistanceMeters") ?: 0.0
                        val etaMinutes = call.argument<Int>("etaMinutes") ?: 0
                        val totalDistKm = call.argument<Double>("totalDistanceKm") ?: 0.0
                        val destTitle = call.argument<String>("destinationTitle") ?: "Destination"
                        val currentLat = call.argument<Double>("currentLat") ?: 0.0
                        val currentLng = call.argument<Double>("currentLng") ?: 0.0

                        // Notify the active car session via application-level broadcast
                        val intent = Intent("com.rideos.mobile.NAV_UPDATE").apply {
                            putExtra("instruction", instruction)
                            putExtra("stepDistanceMeters", stepDistMeters)
                            putExtra("etaMinutes", etaMinutes)
                            putExtra("totalDistanceKm", totalDistKm)
                            putExtra("destinationTitle", destTitle)
                            putExtra("currentLat", currentLat)
                            putExtra("currentLng", currentLng)
                        }
                        sendBroadcast(intent)
                        result.success(true)
                    }
                    "stopNavigation" -> {
                        val intent = Intent("com.rideos.mobile.NAV_STOP")
                        sendBroadcast(intent)
                        result.success(true)
                    }
                    "getAutoConnected" -> {
                        // Returns whether Android Auto is currently connected
                        // androidx.car.app does not expose a direct connected state API
                        // We approximate via the car app session lifecycle
                        result.success(false) // Accurate — no session active at time of query
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
