package com.devtools.android.modules.apktools

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File

sealed class ApkAnalyzerState {
    object Loading : ApkAnalyzerState()
    object Ready : ApkAnalyzerState()
    data class Error(val message: String) : ApkAnalyzerState()
}

class ApkAnalyzerViewModel(private val context: Context) : ViewModel() {

    private val _allApps = MutableStateFlow<List<AppInfo>>(emptyList())

    private val _filteredApps = MutableStateFlow<List<AppInfo>>(emptyList())
    val filteredApps: StateFlow<List<AppInfo>> = _filteredApps.asStateFlow()

    private val _analyzerState = MutableStateFlow<ApkAnalyzerState>(ApkAnalyzerState.Loading)
    val analyzerState: StateFlow<ApkAnalyzerState> = _analyzerState.asStateFlow()

    init {
        loadPackages()
    }

    private fun loadPackages() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val pm = context.packageManager
                @Suppress("DEPRECATION")
                val flags = PackageManager.GET_PERMISSIONS or
                        PackageManager.GET_ACTIVITIES or
                        PackageManager.GET_SERVICES

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

                        val targetSdk = ai.targetSdkVersion

                        val permissions = pi.requestedPermissions?.toList() ?: emptyList()
                        val activities = pi.activities?.map { it.name } ?: emptyList()
                        val services = pi.services?.map { it.name } ?: emptyList()

                        AppInfo(
                            packageName = pi.packageName,
                            appName = appName,
                            versionName = versionName,
                            versionCode = versionCode,
                            minSdk = minSdk,
                            targetSdk = targetSdk,
                            apkPath = ai.sourceDir,
                            apkSizeKb = apkSizeKb,
                            permissions = permissions,
                            activities = activities,
                            services = services
                        )
                    } catch (_: Exception) {
                        null
                    }
                }.sortedBy { it.appName.lowercase() }

                _allApps.value = appList
                _filteredApps.value = appList
                _analyzerState.value = ApkAnalyzerState.Ready
            } catch (e: Exception) {
                _analyzerState.value = ApkAnalyzerState.Error(e.message ?: "Failed to load packages")
            }
        }
    }

    /**
     * Filters the app list by [query] matching package name or app name (case-insensitive).
     * An empty query restores the full list.
     */
    fun filterBy(query: String) {
        val all = _allApps.value
        _filteredApps.value = if (query.isBlank()) {
            all
        } else {
            val q = query.lowercase()
            all.filter {
                it.packageName.lowercase().contains(q) ||
                        it.appName.lowercase().contains(q)
            }
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            ApkAnalyzerViewModel(context.applicationContext) as T
    }
}
