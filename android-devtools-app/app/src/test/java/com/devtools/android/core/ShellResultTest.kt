package com.devtools.android.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShellResultTest {

    @Test
    fun `Success carries output string`() {
        val r = ShellResult.Success("hello")
        assertEquals("hello", r.output)
    }

    @Test
    fun `Failed carries stderr and exitCode`() {
        val r = ShellResult.Failed(stderr = "permission denied", exitCode = 1)
        assertEquals(1, r.exitCode)
        assertTrue(r.stderr.contains("permission denied"))
    }

    @Test
    fun `BinaryMissing carries name`() {
        val r = ShellResult.BinaryMissing("nmap")
        assertEquals("nmap", r.name)
    }
}
