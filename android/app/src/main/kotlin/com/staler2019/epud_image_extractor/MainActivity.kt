package com.staler2019.epud_image_extractor

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.staler2019.epud_image_extractor/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFiles") {
                    val paths = call.argument<List<String>>("paths")
                    if (paths != null) {
                        MediaScannerConnection.scanFile(this, paths.toTypedArray(), null, null)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "paths is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
