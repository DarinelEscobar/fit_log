package com.yourcompany.fit_log

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fit_log/timezone")
            .setMethodCallHandler { call, result ->
                if (call.method == "getTimeZone") result.success(TimeZone.getDefault().id)
                else result.notImplemented()
            }
    }
}
