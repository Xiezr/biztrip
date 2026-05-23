package com.biztrip.biztrip

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val LOCATION_CHANNEL = "com.biztrip.biztrip/location"
        private const val CAMERA_CHANNEL = "com.biztrip.biztrip/camera"
        private const val CAMERA_REQUEST = 201
    }

    private var pendingCameraResult: MethodChannel.Result? = null
    private var pendingCameraUri: Uri? = null
    private var pendingPhotoFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 位置权限
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "requestLocationPermission") {
                    if (ContextCompat.checkSelfPermission(
                            this, Manifest.permission.ACCESS_COARSE_LOCATION
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION),
                            100
                        )
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // 相机拍照
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAMERA_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "capturePhoto") {
                    pendingCameraResult = result
                    val locationName = call.argument<String>("locationName") ?: "未知"
                    val sequence = call.argument<Int>("sequence") ?: 1
                    dispatchTakePicture(locationName, sequence)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun dispatchTakePicture(locationName: String, sequence: Int) {
        try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            if (intent.resolveActivity(packageManager) == null) {
                pendingCameraResult?.error("NO_CAMERA", "No camera app found", null)
                pendingCameraResult = null
                return
            }

            // Android 10+: 使用 MediaStore 创建空白图片，相机直接写入
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val timestamp = SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date())
                val displayName = "${timestamp}_${locationName}_${"%02d".format(sequence)}.jpg"

                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/biztrip")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val uri = contentResolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values
                )

                if (uri != null) {
                    pendingCameraUri = uri
                    intent.putExtra(MediaStore.EXTRA_OUTPUT, uri)
                    intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    startActivityForResult(intent, CAMERA_REQUEST)
                } else {
                    pendingCameraResult?.error("MEDIASTORE_ERROR", "Failed to create MediaStore entry", null)
                    pendingCameraResult = null
                }
            } else {
                // Android 9 及以下：FileProvider 方案
                val timestamp = SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date())
                val fileName = "${timestamp}_${locationName}_${"%02d".format(sequence)}.jpg"
                val dir = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "invoices")
                if (!dir.exists()) dir.mkdirs()
                val photoFile = File(dir, fileName)
                pendingPhotoFile = photoFile
                val photoUri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    photoFile
                )
                intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
                intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                startActivityForResult(intent, CAMERA_REQUEST)
            }
        } catch (e: Exception) {
            pendingCameraResult?.error("CAMERA_ERROR", e.message, null)
            pendingCameraResult = null
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == CAMERA_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // MediaStore: 清除 IS_PENDING 标记
                    val uri = pendingCameraUri
                    if (uri != null) {
                        val values = ContentValues().apply {
                            put(MediaStore.Images.Media.IS_PENDING, 0)
                        }
                        contentResolver.update(uri, values, null, null)
                        pendingCameraResult?.success(uri.toString())
                    } else {
                        pendingCameraResult?.error("MISSING_URI", "Uri is null", null)
                    }
                } else {
                    // FileProvider: 返回文件路径
                    val photoFile = pendingPhotoFile
                    if (photoFile != null && photoFile.exists()) {
                        pendingCameraResult?.success(photoFile.absolutePath)
                    } else {
                        pendingCameraResult?.error("FILE_MISSING", "Photo file does not exist", null)
                    }
                }
            } else {
                pendingCameraResult?.success(null)
            }
            pendingCameraResult = null
            pendingCameraUri = null
            pendingPhotoFile = null
        }
    }
}
