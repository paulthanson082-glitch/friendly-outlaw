package com.devtools.android.modules.packages

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.RootDetector
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import com.devtools.android.modules.apktools.AppInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardCopyOption
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

sealed class PackageManagerState {
    object Loading : PackageManagerState()
    object Ready : PackageManagerState()
    data class Error(val message: String) : PackageManagerState()
}

/** One-shot feedback message for extract / uninstall operations. */
data class OperationResult(val success: Boolean, val message: String)

class PackageManagerViewModel(private val context: Context) : ViewModel() {

    val isRooted: Boolean = RootDetector.isRooted

    private val _allApps = MutableStateFlow<List<AppInfo>>(emptyList())

    private val _filteredApps = MutableStateFlow<List<AppInfo>>(emptyList())
    val filteredApps: StateFlow<List<AppInfo>> = _filteredApps.asStateFlow()

    private val _pmState = MutableStateFlow<PackageManagerState>(PackageManagerState.Loading)
    val pmState: StateFlow<PackageManagerState> = _pmState.asStateFlow()

    private val _operationResult = MutableStateFlow<OperationResult?>(null)
    val operationResult: StateFlow<OperationResult?> = _operationResult.asStateFlow()

    init {
        loadPackages()
    }

    private fun loadPackages() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val pm = context.packageManager
                @Suppress("DEPRECATION")
                val flags = PackageManager.GET_PERMISSIONS

                val packages: List<PackageInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getInstalledPackages(
                        PackageManager.PackageInfoFlags.of(flags.toLong())
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.getInstalledPackages(flags)
                }

                val appList = packages.mapNotNull { pi ->
                    try {
                        val ai = pi.applicationInfo ?: return@mapNotNull null
                        val apkFile = File(ai.sourceDir)
                        val apkSizeKb = apkFile.length() / 1024L
                        val appName = pm.getApplicationLabel(ai).toString()
                        val versionName = pi.versionName ?: "unknown"
                        val versionCode: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pi.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            pi.versionCode.toLong()
                        }
                        val minSdk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            ai.minSdkVersion
                        } else 0

                        AppInfo(
                            packageName = pi.packageName,
                            appName = appName,
                            versionName = versionName,
                            versionCode = versionCode,
                            minSdk = minSdk,
                            targetSdk = ai.targetSdkVersion,
                            apkPath = ai.sourceDir,
                            apkSizeKb = apkSizeKb,
                            permissions = pi.requestedPermissions?.toList() ?: emptyList(),
                            activities = emptyList(),
                            services = emptyList()
                        )
                    } catch (_: Exception) {
                        null
                    }
                }.sortedBy { it.appName.lowercase() }

                _allApps.value = appList
                _filteredApps.value = appList
                _pmState.value = PackageManagerState.Ready
            } catch (e: Exception) {
                _pmState.value = PackageManagerState.Error(e.message ?: "Failed to load packages")
            }
        }
    }

    /** Filters the list by [query] matching app name or package name. */
    fun filterBy(query: String) {
        val all = _allApps.value
        _filteredApps.value = if (query.isBlank()) all else {
            val q = query.lowercase()
            all.filter {
                it.appName.lowercase().contains(q) ||
                        it.packageName.lowercase().contains(q)
            }
        }
    }

    /** Opens the app's system settings screen. */
    fun openSettings(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    /** Launches the app, if it has a launcher activity. */
    fun launch(packageName: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } else {
            _operationResult.value = OperationResult(false, "No launcher activity for $packageName")
        }
    }

    /** Sends a force-stop broadcast via ADB (root-only) or opens settings as fallback. */
    fun forceStop(packageName: String) {
        if (isRooted) {
            viewModelScope.launch(Dispatchers.IO) {
                when (val r = ShellExecutor.execCollect("am force-stop $packageName", root = true)) {
                    is ShellResult.Success ->
                        _operationResult.value = OperationResult(true, "Force-stopped $packageName")
                    else ->
                        _operationResult.value = OperationResult(false, "Force-stop failed: $r")
                }
            }
        } else {
            // Without root, open settings as the closest user-accessible equivalent
            openSettings(packageName)
        }
    }

    /**
     * Copies the APK for [info] to the public Downloads directory using [Files.copy].
     */
    fun extractApk(info: AppInfo, context: Context) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                downloadsDir.mkdirs()
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                val destFile = File(downloadsDir, "${info.packageName}_$timestamp.apk")

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Files.copy(
                        Paths.get(info.apkPath),
                        destFile.toPath(),
                        StandardCopyOption.REPLACE_EXISTING
                    )
                } else {
                    File(info.apkPath).copyTo(destFile, overwrite = true)
                }
                _operationResult.value =
                    OperationResult(true, "APK saved to Downloads/${destFile.name}")
            } catch (e: Exception) {
                _operationResult.value =
                    OperationResult(false, "Extract failed: ${e.message}")
            }
        }
    }

    /**
     * Uninstalls a system app via `pm uninstall` with root.
     * No-ops if the device is not rooted.
     */
    fun uninstallSystem(packageName: String) {
        if (!isRooted) {
            _operationResult.value = OperationResult(false, "Root required to uninstall system apps")
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            when (val r = ShellExecutor.execCollect("pm uninstall $packageName", root = true)) {
                is ShellResult.Success -> {
                    // Refresh list after uninstall
                    loadPackages()
                    _operationResult.value = OperationResult(true, "Uninstalled $packageName")
                }
                else -> _operationResult.value =
                    OperationResult(false, "Uninstall failed: $r")
            }
        }
    }

    /** Clears the last operation result after it has been shown. */
    fun clearOperationResult() {
        _operationResult.value = null
    }

    private fun isSystemApp(info: AppInfo): Boolean {
        return try {
            val ai = context.packageManager.getApplicationInfo(info.packageName, 0)
            (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (_: Exception) {
            false
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            PackageManagerViewModel(context.applicationContext) as T
    }
}
