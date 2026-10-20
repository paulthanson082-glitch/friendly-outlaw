package com.devtools.android.modules.performance

import android.app.ActivityManager
import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileNotFoundException

data class ThermalZone(val name: String, val tempC: Float)

data class ProcessInfo(val name: String, val rssKb: Long)

data class PerformanceData(
    val cpuUsagePercent: Float = 0f,
    val ramUsedMb: Long = 0,
    val ramTotalMb: Long = 0,
    val thermalZones: List<ThermalZone> = emptyList(),
    val topProcesses: List<ProcessInfo> = emptyList(),
    val batteryCurrentMa: Int = 0
)

class PerformanceViewModel(private val context: Context) : ViewModel() {

    private val _performanceData = MutableStateFlow(PerformanceData())
    val performanceData: StateFlow<PerformanceData> = _performanceData.asStateFlow()

    private var monitoringJob: Job? = null

    init {
        startMonitoring()
    }

    fun startMonitoring() {
        if (monitoringJob?.isActive == true) return
        monitoringJob = viewModelScope.launch(Dispatchers.IO) {
            while (isActive) {
                val cpuUsage = readCpuUsage()
                val (ramUsed, ramTotal) = readRam()
                val thermalZones = readThermalZones()
                val topProcesses = readTopProcesses()
                val batteryCurrentMa = readBatteryCurrent()

                _performanceData.value = PerformanceData(
                    cpuUsagePercent = cpuUsage,
                    ramUsedMb = ramUsed,
                    ramTotalMb = ramTotal,
                    thermalZones = thermalZones,
                    topProcesses = topProcesses,
                    batteryCurrentMa = batteryCurrentMa
                )
                delay(2000)
            }
        }
    }

    fun stopMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = null
    }

    // Reads two /proc/stat snapshots 1 s apart and computes CPU usage %
    private suspend fun readCpuUsage(): Float {
        return try {
            val snapshot1 = readCpuSnapshot()
            delay(1000)
            val snapshot2 = readCpuSnapshot()
            if (snapshot1.isEmpty() || snapshot2.isEmpty()) return 0f

            // Fields: user nice system idle iowait irq softirq steal ...
            val idle1 = snapshot1.getOrElse(3) { 0L }
            val idle2 = snapshot2.getOrElse(3) { 0L }
            val total1 = snapshot1.sum()
            val total2 = snapshot2.sum()
            val totalDelta = (total2 - total1).toFloat()
            val idleDelta = (idle2 - idle1).toFloat()

            if (totalDelta <= 0f) 0f
            else ((totalDelta - idleDelta) / totalDelta * 100f).coerceIn(0f, 100f)
        } catch (e: Exception) {
            0f
        }
    }

    private fun readCpuSnapshot(): List<Long> {
        return try {
            val line = File("/proc/stat").bufferedReader().use { it.readLine() } ?: return emptyList()
            // "cpu  <user> <nice> <system> <idle> <iowait> <irq> <softirq> ..."
            line.trim().split("\\s+".toRegex()).drop(1).mapNotNull { it.toLongOrNull() }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun readRam(): Pair<Long, Long> {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            val totalMb = memInfo.totalMem / (1024L * 1024L)
            val availMb = memInfo.availMem / (1024L * 1024L)
            Pair(totalMb - availMb, totalMb)
        } catch (e: Exception) {
            Pair(0L, 0L)
        }
    }

    private fun readThermalZones(): List<ThermalZone> {
        return try {
            val thermalDir = File("/sys/class/thermal")
            if (!thermalDir.exists()) return emptyList()

            thermalDir.listFiles { file ->
                file.isDirectory && file.name.startsWith("thermal_zone")
            }?.mapNotNull { zone ->
                try {
                    val milliDeg = File(zone, "temp").readText().trim().toLongOrNull()
                        ?: return@mapNotNull null
                    val type = try {
                        File(zone, "type").readText().trim()
                    } catch (e: Exception) {
                        zone.name
                    }
                    ThermalZone(name = type, tempC = milliDeg / 1000f)
                } catch (e: Exception) {
                    null
                }
            }?.sortedBy { it.name } ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun readTopProcesses(): List<ProcessInfo> {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val running = activityManager.getRunningAppProcesses() ?: emptyList()

            running.mapNotNull { proc ->
                try {
                    val memInfo = activityManager.getProcessMemoryInfo(intArrayOf(proc.pid))
                    val rssKb = memInfo.firstOrNull()?.totalPss?.toLong() ?: 0L
                    ProcessInfo(
                        name = proc.processName.substringAfterLast('.').take(30),
                        rssKb = rssKb
                    )
                } catch (e: Exception) {
                    null
                }
            }.sortedByDescending { it.rssKb }.take(10)
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun readBatteryCurrent(): Int {
        return try {
            val value = File("/sys/class/power_supply/battery/current_now")
                .readText().trim().toIntOrNull() ?: return 0
            value / 1000 // µA → mA
        } catch (_: FileNotFoundException) {
            0
        } catch (_: Exception) {
            0
        }
    }

    override fun onCleared() {
        super.onCleared()
        stopMonitoring()
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PerformanceViewModel(context.applicationContext) as T
        }
    }
}
