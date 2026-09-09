package com.example.rideos_mobile.aaos

import android.content.Intent
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class RideOSAaosService : CarAppService() {
    
    companion object {
        var flutterEngine: FlutterEngine? = null
            private set
            
        var methodChannel: MethodChannel? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        
        // Spin up headless FlutterEngine to run the canonical Dart BLOCs
        if (flutterEngine == null) {
            val engine = FlutterEngine(this.applicationContext)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    io.flutter.FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    "aaosHeadlessEntrypoint"
                )
            )
            flutterEngine = engine
            methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.rideos.mobile/aaos_bridge")
        }
    }

    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(): Session {
        return RideOSAaosSession()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
        flutterEngine = null
        methodChannel = null
    }
}
