package com.biztrip.biztrip

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.graphics.Bitmap
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.util.Log

class MainActivity : FlutterActivity() {
    companion object {
        private const val LOCATION_CHANNEL = "com.biztrip.biztrip/location"
        private const val CAMERA_CHANNEL = "com.biztrip.biztrip/camera"
        private const val NOTIFICATION_CHANNEL = "com.biztrip.biztrip/notification"
        private const val CAMERA_REQUEST = 201
        private const val NOTIFICATION_PERMISSION_REQUEST = 202
        private const val TRIP_NOTIFICATION_CHANNEL_ID = "trip_notifications"
    }

    private var pendingCameraResult: MethodChannel.Result? = null
    private var pendingCameraUri: Uri? = null
    private var pendingPhotoFile: File? = null
    private var pendingCameraArgs: Pair<String, Int>? = null  // locationName, sequence

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 边到边显示：让内容延伸到导航栏下方（最佳实践，配合 styles.xml 透明导航栏 + Flutter edgeToEdge）
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 创建通知渠道（Android 8.0+）
        createNotificationChannel()

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
                    // Android 6.0+ 需要运行时权限
                    if (ContextCompat.checkSelfPermission(
                            this, Manifest.permission.CAMERA
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingCameraArgs = Pair(locationName, sequence)
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CAMERA),
                            CAMERA_REQUEST
                        )
                        return@setMethodCallHandler
                    }
                    dispatchTakePicture(locationName, sequence)
                } else {
                    result.notImplemented()
                }
            }

        // 通知推送
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "showNotification") {
                    val title = call.argument<String>("title") ?: return@setMethodCallHandler
                    val body = call.argument<String>("body") ?: ""
                    val notificationId = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    val summary = call.argument<String>("summary") ?: ""
                    showTripNotification(notificationId, title, body, summary)
                    result.success(null)
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

            // 统一使用应用私有目录，兼容所有 Android 版本
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = "${timestamp}_${locationName}_${"%02d".format(sequence)}.jpg"
            val dir = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "biztrip")
            if (!dir.exists()) dir.mkdirs()
            val photoFile = File(dir, fileName)
            pendingPhotoFile = photoFile

            val authorities = "${applicationContext.packageName}.fileprovider"
            val photoUri = FileProvider.getUriForFile(this, authorities, photoFile)
            intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
            intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            Log.d("BiztripCamera", "Photo will be saved to: ${photoFile.absolutePath}")
            Log.d("BiztripCamera", "FileProvider authorities: $authorities")

            startActivityForResult(intent, CAMERA_REQUEST)
        } catch (e: Exception) {
            Log.e("BiztripCamera", "dispatchTakePicture error", e)
            pendingCameraResult?.error("CAMERA_ERROR", e.message, Log.getStackTraceString(e))
            pendingCameraResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_REQUEST) {
            val args = pendingCameraArgs
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED && args != null) {
                Log.d("BiztripCamera", "Camera permission granted, dispatching")
                dispatchTakePicture(args.first, args.second)
            } else {
                Log.d("BiztripCamera", "Camera permission denied")
                pendingCameraResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
                pendingCameraResult = null
            }
            pendingCameraArgs = null
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == CAMERA_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                val photoFile = pendingPhotoFile
                Log.d("BiztripCamera", "onActivityResult OK, photoFile=$photoFile, exists=${photoFile?.exists()}")

                if (photoFile != null && photoFile.exists()) {
                    // 路径 1：EXTRA_OUTPUT 生效，文件已在预期位置
                    Log.d("BiztripCamera", "Path 1: file at expected location")
                    pendingCameraResult?.success(photoFile.absolutePath)
                } else {
                    // 路径 2：尝试从 data 获取 Bitmap 缩略图（兼容忽略 EXTRA_OUTPUT 的相机）
                    val bitmap = data?.extras?.get("data") as? Bitmap
                    if (bitmap != null) {
                        val targetFile = if (photoFile != null) {
                            photoFile.parentFile?.mkdirs()
                            photoFile
                        } else {
                            // Activity 被销毁后 pendingPhotoFile 丢失，重建文件路径
                            val dir = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "biztrip")
                            if (!dir.exists()) dir.mkdirs()
                            val ts = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                            File(dir, "${ts}_recovered.jpg")
                        }
                        try {
                            FileOutputStream(targetFile).use { out ->
                                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                            }
                            Log.d("BiztripCamera", "Path 2: saved bitmap to ${targetFile.absolutePath}")
                            pendingCameraResult?.success(targetFile.absolutePath)
                        } catch (e: Exception) {
                            Log.e("BiztripCamera", "Bitmap save failed", e)
                            pendingCameraResult?.error("FILE_SAVE_ERROR", e.message, Log.getStackTraceString(e))
                        }
                    } else {
                        // 路径 3：无 Bitmap，扫描目录找最近写入的文件（Activity 销毁后相机可能已写入）
                        val dir = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "biztrip")
                        val latest = dir.listFiles()?.filter { it.extension == "jpg" }?.maxByOrNull { it.lastModified() }
                        if (latest != null) {
                            Log.d("BiztripCamera", "Path 3: recovered ${latest.absolutePath} (lastModified=${latest.lastModified()})")
                            pendingCameraResult?.success(latest.absolutePath)
                        } else {
                            Log.e("BiztripCamera", "All paths exhausted, no file found")
                            pendingCameraResult?.error("FILE_MISSING",
                                "Photo file not found at ${photoFile?.absolutePath} and no bitmap or directory fallback available", null)
                        }
                    }
                }
            } else {
                Log.d("BiztripCamera", "onActivityResult cancelled or error, resultCode=$resultCode")
                pendingCameraResult?.success(null)
            }
            pendingCameraResult = null
            pendingCameraUri = null
            pendingPhotoFile = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "差旅提醒"
            val description = "差旅日历通知（准备、确认、跟进、报销、报告、月末汇总）"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(TRIP_NOTIFICATION_CHANNEL_ID, name, importance).apply {
                this.description = description
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun showTripNotification(id: Int, title: String, body: String, summary: String) {
        val builder = NotificationCompat.Builder(this, TRIP_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)  // 使用系统图标兜底
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body).setSummaryText(summary))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        try {
            NotificationManagerCompat.from(this).notify(id, builder.build())
            Log.d("BiztripNotify", "Notification sent: id=$id, title=$title")
        } catch (e: SecurityException) {
            Log.e("BiztripNotify", "No notification permission", e)
        }
    }
}
