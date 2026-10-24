package com.devtools.android.core

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RootDetectorTest {

    @Test
    fun `returns false when no su path exists`() {
        // Inject a fake path checker that always returns false
        val detector = RootDetector(suPathExists = { false }, buildTagsContainTestKeys = { false })
        assertFalse(detector.check())
    }

    @Test
    fun `returns true when su binary found at xbin`() {
        val detector = RootDetector(suPathExists = { it == "/system/xbin/su" }, buildTagsContainTestKeys = { false })
        assertTrue(detector.check())
    }

    @Test
    fun `returns true when build tags contain test-keys`() {
        val detector = RootDetector(suPathExists = { false }, buildTagsContainTestKeys = { true })
        assertTrue(detector.check())
    }
}
