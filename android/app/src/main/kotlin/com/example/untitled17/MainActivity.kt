package com.example.untitled17

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.io.File
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "docscanner_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Python
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanDocument" -> {
                    try {
                        // Get image bytes from Flutter
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        if (imageBytes == null) {
                            result.error("INVALID_DATA", "Image bytes are null", null)
                            return@setMethodCallHandler
                        }

                        // Create directory if it doesn't exist
                        val directory = File(applicationContext.filesDir, "images")
                        if (!directory.exists()) {
                            directory.mkdirs()
                        }

                        // Create temporary file for the input image
                        val inputFile = File(directory, "temp_input.jpg")
                        inputFile.writeBytes(imageBytes)

                        // Get Python instance and module
                        val py = Python.getInstance()
                        val module = py.getModule("scan")

                        // Call scan_document function
                        val scanResult = module.callAttr(
                            "scan_document",
                            inputFile.absolutePath
                        ).toString()

                        // Return the result
                        result.success(scanResult)

                    } catch (e: Exception) {
                        println("Error in scanDocument: ${e.message}")
                        e.printStackTrace()
                        result.error("SCAN_ERROR", e.message, e.stackTraceToString())
                    }
                }

                "processWithCorners" -> {
                    try {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        val cornersArg = call.argument<List<List<Double>>>("corners")

                        if (imageBytes == null || cornersArg == null) {
                            result.error("INVALID_DATA", "Missing required parameters", null)
                            return@setMethodCallHandler
                        }

                        // Create directory if it doesn't exist
                        val directory = File(applicationContext.filesDir, "images")
                        if (!directory.exists()) {
                            directory.mkdirs()
                        }

                        // Create temporary file for the input image
                        val inputFile = File(directory, "temp_input.jpg")
                        inputFile.writeBytes(imageBytes)

                        // Get Python instance and module
                        val py = Python.getInstance()
                        val module = py.getModule("scan")

                        // Convert corners to Python list
                        val pyCorners = py.builtins.callAttr("list")
                        cornersArg.forEach { point ->
                            val pyPoint = py.builtins.callAttr("list")
                            point.forEach { coord ->
                                pyPoint.callAttr("append", coord.toDouble())
                            }
                            pyCorners.callAttr("append", pyPoint)
                        }

                        // Call process_with_corners function
                        val processResult = module.callAttr(
                            "process_with_corners",
                            inputFile.absolutePath,
                            pyCorners
                        ).toString()

                        if (processResult.startsWith("Error:")) {
                            result.error("PROCESSING_ERROR", processResult, null)
                        } else {
                            result.success(processResult)
                        }

                    } catch (e: Exception) {
                        println("Error in processWithCorners: ${e.message}")
                        e.printStackTrace()
                        result.error("PROCESSING_ERROR", e.message, e.stackTraceToString())
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun cleanupTempFiles() {
        try {
            val directory = File(applicationContext.filesDir, "images")
            if (directory.exists()) {
                directory.listFiles()?.forEach { file ->
                    if (file.name.startsWith("temp_")) {
                        file.delete()
                    }
                }
            }
        } catch (e: Exception) {
            println("Error cleaning up temp files: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupTempFiles()
    }
}