package com.example.untitled17

import android.content.ContentValues
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.io.File
import java.io.FileInputStream
import java.io.IOException
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
                "saveImageToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    if (sourcePath != null) {
                        try {
                            saveImage(sourcePath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Source path is null", null)
                    }
                }

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

                "detectDocument" -> {
                    try {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        if (imageBytes == null) {
                            result.error("INVALID_DATA", "Image bytes are null", null)
                            return@setMethodCallHandler
                        }

                        val directory = File(applicationContext.filesDir, "images")
                        if (!directory.exists()) {
                            directory.mkdirs()
                        }

                        val inputFile = File(directory, "temp_input.jpg")
                        inputFile.writeBytes(imageBytes)

                        val py = Python.getInstance()
                        val module = py.getModule("detect")

                        val detectResult = module.callAttr(
                            "detect_document",
                            inputFile.absolutePath
                        ).toString()

                        result.success(detectResult)

                    } catch (e: Exception) {
                        result.error("DETECT_ERROR", e.message, e.stackTraceToString())
                    }
                }

                "cropDocument" -> {
                    try {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        val cornersArg = call.argument<List<List<Double>>>("corners")

                        if (imageBytes == null || cornersArg == null) {
                            result.error("INVALID_DATA", "Missing required parameters", null)
                            return@setMethodCallHandler
                        }

                        val directory = File(applicationContext.filesDir, "images")
                        if (!directory.exists()) {
                            directory.mkdirs()
                        }

                        val inputFile = File(directory, "temp_input.jpg")
                        inputFile.writeBytes(imageBytes)

                        val py = Python.getInstance()
                        val module = py.getModule("detect")

                        val pyCorners = py.builtins.callAttr("list")
                        cornersArg.forEach { point ->
                            val pyPoint = py.builtins.callAttr("list")
                            point.forEach { coord ->
                                pyPoint.callAttr("append", coord.toDouble())
                            }
                            pyCorners.callAttr("append", pyPoint)
                        }

                        val cropResult = module.callAttr(
                            "crop_document",
                            inputFile.absolutePath,
                            pyCorners
                        ).toString()

                        if (cropResult.startsWith("Error:")) {
                            result.error("CROP_ERROR", cropResult, null)
                        } else {
                            result.success(cropResult)
                        }

                    } catch (e: Exception) {
                        result.error("CROP_ERROR", e.message, e.stackTraceToString())
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveImage(sourcePath: String) {
        val sourceFile = File(sourcePath)
        val filename = "scanned_doc_${System.currentTimeMillis()}.jpg"

        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, filename)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }

        val resolver = context.contentResolver
        val collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val imageUri = resolver.insert(collection, values)

        imageUri?.let { uri ->
            resolver.openOutputStream(uri)?.use { os ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(os)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
        } ?: throw IOException("Failed to create new MediaStore record.")
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