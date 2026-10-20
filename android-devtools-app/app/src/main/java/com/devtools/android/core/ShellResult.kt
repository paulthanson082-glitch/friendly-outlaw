package com.devtools.android.core

/**
 * Sealed class representing the result of a shell command execution.
 */
sealed class ShellResult {
    /** Command executed successfully; [output] contains stdout. */
    data class Success(val output: String) : ShellResult()

    /** Command requires root access which is not available. */
    object RootRequired : ShellResult()

    /** The requested binary was not found on the device. */
    data class BinaryMissing(val name: String) : ShellResult()

    /** Command failed; [stderr] contains the error output and [exitCode] the process exit code. */
    data class Failed(val stderr: String, val exitCode: Int) : ShellResult()
}
