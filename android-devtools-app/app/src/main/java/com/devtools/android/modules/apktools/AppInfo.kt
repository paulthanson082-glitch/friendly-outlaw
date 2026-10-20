package com.devtools.android.modules.apktools

/**
 * Metadata about an installed application extracted from the Android [PackageManager].
 */
data class AppInfo(
    val packageName: String,
    val appName: String,
    val versionName: String,
    val versionCode: Long,
    val minSdk: Int,
    val targetSdk: Int,
    val apkPath: String,
    val apkSizeKb: Long,
    val permissions: List<String>,
    val activities: List<String>,
    val services: List<String>
)
