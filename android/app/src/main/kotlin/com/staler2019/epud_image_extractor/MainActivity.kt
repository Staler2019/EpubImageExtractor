package com.staler2019.epud_image_extractor

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val MEDIA_SCANNER_CHANNEL = "com.staler2019.epud_image_extractor/media_scanner"
    private val FILE_OPENER_CHANNEL = "com.staler2019.epud_image_extractor/file_opener"

    private var pendingFilePath: String? = null
    private var fileOpenerMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL)
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

        fileOpenerMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, FILE_OPENER_CHANNEL
        )
        fileOpenerMethodChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "getInitialFilePath") {
                result.success(pendingFilePath)
                pendingFilePath = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Store the path for delivery via getInitialFilePath once the channel is ready
        pendingFilePath = resolveEpubPath(intent)
    }

    // singleTop reuse: app already running when another EPUB is opened
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = resolveEpubPath(intent) ?: return
        val channel = fileOpenerMethodChannel
        if (channel != null) {
            channel.invokeMethod("fileOpened", path)
        } else {
            pendingFilePath = path
        }
    }

    private fun resolveEpubPath(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null
        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> copyContentUriToTempFile(uri)
            else -> null
        }
    }

    // Copies a content:// EPUB URI to a fixed-name temp file so epub_parser can
    // read it via a regular file path. Using a fixed name ensures at most one
    // such file exists at a time — each open overwrites the previous one.
    private fun copyContentUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "epub_from_intent.epub")
            FileOutputStream(tempFile).use { output -> inputStream.copyTo(output) }
            inputStream.close()
            tempFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }
}
