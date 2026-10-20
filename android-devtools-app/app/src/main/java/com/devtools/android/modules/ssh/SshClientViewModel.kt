package com.devtools.android.modules.ssh

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.schmizz.sshj.SSHClient
import net.schmizz.sshj.transport.verification.PromiscuousVerifier

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "ssh_prefs")

sealed class SshState {
    object Disconnected : SshState()
    object Connecting : SshState()
    data class Connected(val session: SSHClient) : SshState()
    data class Error(val msg: String) : SshState()
}

class SshClientViewModel(private val context: Context) : ViewModel() {

    private val _state = MutableStateFlow<SshState>(SshState.Disconnected)
    val state: StateFlow<SshState> = _state.asStateFlow()

    private val _commandOutput = MutableStateFlow<List<String>>(emptyList())
    val commandOutput: StateFlow<List<String>> = _commandOutput.asStateFlow()

    private val _lastProfile = MutableStateFlow<SshProfile?>(null)
    val lastProfile: StateFlow<SshProfile?> = _lastProfile.asStateFlow()

    companion object {
        private val KEY_HOST = stringPreferencesKey("ssh_host")
        private val KEY_PORT = intPreferencesKey("ssh_port")
        private val KEY_USERNAME = stringPreferencesKey("ssh_username")
    }

    init {
        viewModelScope.launch {
            val prefs = context.dataStore.data.first()
            val host = prefs[KEY_HOST] ?: ""
            val port = prefs[KEY_PORT] ?: 22
            val username = prefs[KEY_USERNAME] ?: ""
            if (host.isNotBlank()) {
                _lastProfile.value = SshProfile(
                    host = host,
                    port = port,
                    username = username,
                    authMethod = SshAuthMethod.Password("")
                )
            }
        }
    }

    fun connect(profile: SshProfile) {
        val current = _state.value
        if (current is SshState.Connected) {
            viewModelScope.launch {
                withContext(Dispatchers.IO) {
                    try { current.session.disconnect() } catch (_: Exception) {}
                }
            }
        }
        _state.value = SshState.Connecting
        _commandOutput.value = emptyList()

        viewModelScope.launch {
            try {
                val sshClient = withContext(Dispatchers.IO) {
                    val client = SSHClient()
                    client.addHostKeyVerifier(PromiscuousVerifier())
                    client.connect(profile.host, profile.port)
                    when (val auth = profile.authMethod) {
                        is SshAuthMethod.Password -> client.authPassword(profile.username, auth.value)
                        is SshAuthMethod.KeyPath -> client.authPublickey(profile.username, auth.path)
                    }
                    client
                }
                _state.value = SshState.Connected(sshClient)
                saveProfile(profile)
            } catch (e: Exception) {
                _state.value = SshState.Error(e.message ?: "Connection failed")
            }
        }
    }

    fun disconnect() {
        val current = _state.value
        viewModelScope.launch {
            if (current is SshState.Connected) {
                withContext(Dispatchers.IO) {
                    try { current.session.disconnect() } catch (_: Exception) {}
                }
            }
            _state.value = SshState.Disconnected
        }
    }

    /** Streams stdout of [cmd] line by line. All I/O runs on [Dispatchers.IO]. */
    fun executeCommand(cmd: String): Flow<String> = flow {
        val current = _state.value
        if (current !is SshState.Connected) {
            emit("Error: Not connected")
            return@flow
        }
        val session = current.session.startSession()
        try {
            val exec = session.exec(cmd)
            exec.inputStream.bufferedReader().useLines { lines ->
                for (line in lines) {
                    emit(line)
                }
            }
            exec.join()
        } finally {
            try { session.close() } catch (_: Exception) {}
        }
    }.flowOn(Dispatchers.IO)

    /** Appends "$ cmd" to output, runs the command, and streams results into [commandOutput]. */
    fun runCommand(cmd: String) {
        viewModelScope.launch {
            appendOutputLine("$ $cmd")
            executeCommand(cmd).collect { line ->
                appendOutputLine(line)
            }
        }
    }

    private fun appendOutputLine(line: String) {
        val current = _commandOutput.value
        _commandOutput.value = if (current.size >= 1000) {
            (current.drop(1) + line)
        } else {
            current + line
        }
    }

    private suspend fun saveProfile(profile: SshProfile) {
        context.dataStore.edit { prefs ->
            prefs[KEY_HOST] = profile.host
            prefs[KEY_PORT] = profile.port
            prefs[KEY_USERNAME] = profile.username
        }
    }

    override fun onCleared() {
        super.onCleared()
        val current = _state.value
        if (current is SshState.Connected) {
            try { current.session.disconnect() } catch (_: Exception) {}
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            SshClientViewModel(context.applicationContext) as T
    }
}
