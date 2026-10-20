package com.devtools.android.modules.security

import com.devtools.android.modules.terminal.ShellTerminalViewModel

/**
 * A terminal view model that always executes commands with root = true.
 *
 * Extends [ShellTerminalViewModel] and overrides [sendCommand] to force root
 * mode on every command without requiring the user to toggle a switch.
 */
class RootTerminalViewModel : ShellTerminalViewModel() {

    init {
        // Pre-enable root mode so the parent's isRootMode reflects reality.
        setRootMode(true)
    }

    /**
     * Sends [input] via the parent implementation, having ensured root mode
     * is active.  The override re-applies setRootMode before each call so
     * that the flag cannot inadvertently be cleared.
     */
    override fun sendCommand(input: String) {
        setRootMode(true)
        super.sendCommand(input)
    }
}
