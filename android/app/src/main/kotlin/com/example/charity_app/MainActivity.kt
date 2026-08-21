package com.example.charity_app

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ataa/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("bad_args", "Missing file path", null)
                    return@setMethodCallHandler
                }
                try {
                    shareFile(
                        path = path,
                        filename = call.argument<String>("filename"),
                        mimeType = call.argument<String>("mimeType") ?: "application/pdf",
                    )
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", error.message, null)
                }
            }
    }

    private fun shareFile(path: String, filename: String?, mimeType: String) {
        val file = File(path)
        if (!file.exists() || file.length() == 0L) {
            throw IllegalStateException("Certificate file is missing")
        }
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, filename ?: file.name)
            clipData = ClipData.newRawUri(filename ?: file.name, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, filename ?: file.name))
    }
}
