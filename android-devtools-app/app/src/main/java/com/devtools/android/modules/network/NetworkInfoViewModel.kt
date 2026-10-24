package com.devtools.android.modules.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.net.NetworkInterface as JNetworkInterface

data class WifiDetails(
    val ssid: String = "",
    val bssid: String = "",
    val signalDbm: Int = 0,
    val frequencyMhz: Int = 0,
    val linkSpeedMbps: Int = 0,
)

data class IpConfig(
    val ip: String = "",
    val prefixLength: String = "",
    val gateway: String = "",
    val dnsServers: List<String> = emptyList(),
)

data class NetworkInterfaceInfo(
    val name: String,
    val addresses: List<String>,
)

data class NetworkInfo(
    val wifiDetails: WifiDetails = WifiDetails(),
    val ipConfig: IpConfig = IpConfig(),
    val interfaces: List<NetworkInterfaceInfo> = emptyList(),
)

class NetworkInfoViewModel(private val context: Context) : ViewModel() {

    private val _networkInfo = MutableStateFlow(NetworkInfo())
    val networkInfo: StateFlow<NetworkInfo> = _networkInfo.asStateFlow()

    private val _hasError = MutableStateFlow(false)
    val hasError: StateFlow<Boolean> = _hasError.asStateFlow()

    init {
        load()
    }

    fun refresh() {
        _hasError.value = false
        load()
    }

    private fun load() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val wifi = readWifiDetails()
                val ip = readIpConfig()
                val ifaces = readNetworkInterfaces()
                _networkInfo.value = NetworkInfo(
                    wifiDetails = wifi,
                    ipConfig = ip,
                    interfaces = ifaces,
                )
            } catch (e: Exception) {
                _hasError.value = true
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun readWifiDetails(): WifiDetails {
        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val connInfo = wifiManager.connectionInfo

        val rawSsid = connInfo?.ssid ?: ""
        val ssid = when {
            rawSsid.isBlank() || rawSsid == "<unknown ssid>" ->
                "Unknown SSID (fine location permission required)"
            else -> rawSsid.removePrefix("\"").removeSuffix("\"")
        }

        return WifiDetails(
            ssid = ssid,
            bssid = connInfo?.bssid ?: "",
            signalDbm = connInfo?.rssi ?: 0,
            frequencyMhz = connInfo?.frequency ?: 0,
            linkSpeedMbps = connInfo?.linkSpeed ?: 0,
        )
    }

    private fun readIpConfig(): IpConfig {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return IpConfig()
        val linkProps = cm.getLinkProperties(network) ?: return IpConfig()

        val linkAddr = linkProps.linkAddresses
            .firstOrNull { !it.address.isLoopbackAddress && !it.address.isLinkLocalAddress }

        val ip = linkAddr?.address?.hostAddress ?: ""
        val prefix = linkAddr?.prefixLength?.let { "/$it" } ?: ""

        val gateway = linkProps.routes
            .firstOrNull { it.isDefaultRoute && it.gateway != null }
            ?.gateway?.hostAddress ?: ""

        val dns = linkProps.dnsServers
            .mapNotNull { it.hostAddress }
            .filter { it.isNotBlank() }

        return IpConfig(ip = ip, prefixLength = prefix, gateway = gateway, dnsServers = dns)
    }

    private fun readNetworkInterfaces(): List<NetworkInterfaceInfo> {
        return try {
            JNetworkInterface.getNetworkInterfaces()
                ?.asSequence()
                ?.map { iface ->
                    val addrs = iface.inetAddresses.asSequence()
                        .filter { !it.isLoopbackAddress }
                        .mapNotNull { it.hostAddress }
                        .filter { it.isNotBlank() }
                        .toList()
                    NetworkInterfaceInfo(name = iface.name, addresses = addrs)
                }
                ?.filter { it.addresses.isNotEmpty() }
                ?.toList()
                ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            NetworkInfoViewModel(context.applicationContext) as T
    }
}
