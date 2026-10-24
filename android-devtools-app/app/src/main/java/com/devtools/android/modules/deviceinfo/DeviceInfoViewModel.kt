package com.devtools.android.modules.deviceinfo

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.RootDetector
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File

data class DeviceInfo(
    val androidVersion: String = "",
    val buildFingerprint: String = "",
    val kernel: String = "",
    val cpuHardware: String = "",
    val cpuCores: Int = 0,
    val totalRamMb: Long = 0,
    val availRamMb: Long = 0,
    val batteryLevel: Int = 0,
    val batteryTemp: Float = 0f,
    val storageTotalGb: Float = 0f,
    val storageAvailGb: Float = 0f,
    val gpuClockFreq: String? = null
)

class DeviceInfoViewModel(private val context: Context) : ViewModel() {

    private val _deviceInfo = MutableStateFlow(DeviceInfo())
    val deviceInfo: StateFlow<DeviceInfo> = _deviceInfo.asStateFlow()

    private val _hasError = MutableStateFlow(false)
    val hasError: StateFlow<Boolean> = _hasError.asStateFlow()

    init {
        loadDeviceInfo()
    }

    private fun loadDeviceInfo() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val androidVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
                val buildFingerprint = Build.FINGERPRINT
                val kernel = readKernel()
                val (cpuHardware, cpuCores) = parseCpuInfo()
                val (totalRamMb, availRamMb) = readRam()
                val (batteryLevel, batteryTemp) = readBatteryInfo()
                val (storageTotalGb, storageAvailGb) = readStorageInfo()
                val gpuClockFreq = readGpuInfo()

                _deviceInfo.value = DeviceInfo(
                    androidVersion = androidVersion,
                    buildFingerprint = buildFingerprint,
                    kernel = kernel,
                    cpuHardware = cpuHardware,
                    cpuCores = cpuCores,
                    totalRamMb = totalRamMb,
                    availRamMb = availRamMb,
                    batteryLevel = batteryLevel,
                    batteryTemp = batteryTemp,
                    storageTotalGb = storageTotalGb,
                    storageAvailGb = storageAvailGb,
                    gpuClockFreq = gpuClockFreq
                )
            } catch (e: Exception) {
                _hasError.value = true
            }
        }
    }

    private fun readKernel(): String {
        return try {
            File("/proc/version").readText().trim().take(100)
        } catch (e: Exception) {
            "Unknown"
        }
    }

    private fun parseCpuInfo(): Pair<String, Int> {
        return try {
            val cpuinfo = File("/proc/cpuinfo").readText()
            val hardware = Regex("(?i)hardware\\s*:\\s*(.+)").find(cpuinfo)
                ?.groupValues?.get(1)?.trim() ?: "Unknown"
            val cores = Regex("(?i)^processor\\s*:", RegexOption.MULTILINE)
                .findAll(cpuinfo).count().coerceAtLeast(1)
            Pair(hardware, cores)
        } catch (e: Exception) {
            Pair("Unknown", Runtime.getRuntime().availableProcessors())
        }
    }

    private fun readRam(): Pair<Long, Long> {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            val totalMb = memInfo.totalMem / (1024L * 1024L)
            val availMb = memInfo.availMem / (1024L * 1024L)
            Pair(totalMb, availMb)
        } catch (e: Exception) {
            Pair(0L, 0L)
        }
    }

    private fun readBatteryInfo(): Pair<Int, Float> {
        return try {
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val intent = context.registerReceiver(null, filter)
            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val temperature = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
            val batteryPct = if (scale > 0) level * 100 / scale else 0
            val tempC = temperature / 10f
            Pair(batteryPct, tempC)
        } catch (e: Exception) {
            Pair(0, 0f)
        }
    }

    private fun readStorageInfo(): Pair<Float, Float> {
        return try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val totalBytes = stat.blockCountLong * stat.blockSizeLong
            val availBytes = stat.availableBlocksLong * stat.blockSizeLong
            val totalGb = totalBytes / (1024f * 1024f * 1024f)
            val availGb = availBytes / (1024f * 1024f * 1024f)
            Pair(totalGb, availGb)
        } catch (e: Exception) {
            Pair(0f, 0f)
        }
    }

    private suspend fun readGpuInfo(): String? {
        if (!RootDetector.isRooted) return null
        return when (val result = ShellExecutor.execCollect(
            "cat /sys/class/kgsl/kgsl-3d0/gpu_clock_freq",
            root = true
        )) {
            is ShellResult.Success -> "${result.output.trim()} Hz"
            else -> null
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return DeviceInfoViewModel(context.applicationContext) as T
        }
    }
}
