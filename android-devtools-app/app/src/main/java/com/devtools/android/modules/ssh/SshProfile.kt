package com.devtools.android.modules.ssh

data class SshProfile(
    val host: String,
    val port: Int = 22,
    val username: String,
    val authMethod: SshAuthMethod
)

sealed class SshAuthMethod {
    data class Password(val value: String) : SshAuthMethod()
    data class KeyPath(val path: String) : SshAuthMethod()
}
