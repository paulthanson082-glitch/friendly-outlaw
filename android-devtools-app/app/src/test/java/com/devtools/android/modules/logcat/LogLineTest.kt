package com.devtools.android.modules.logcat

import org.junit.Assert.assertEquals
import org.junit.Test

class LogLineTest {

    @Test
    fun `parses error line correctly`() {
        val line = "08-15 12:34:56.789  1234  5678 E MyTag: something went wrong"
        val result = LogLine.parse(line)
        assertEquals(LogLevel.ERROR, result.level)
        assertEquals("MyTag", result.tag)
        assertEquals("something went wrong", result.message)
    }

    @Test
    fun `parses warn line correctly`() {
        val line = "08-15 12:34:56.789  1234  5678 W NetTag: reconnecting"
        assertEquals(LogLevel.WARN, LogLine.parse(line).level)
    }

    @Test
    fun `returns VERBOSE for unknown level`() {
        val line = "08-15 12:34:56.789  1234  5678 X Unknown: msg"
        assertEquals(LogLevel.VERBOSE, LogLine.parse(line).level)
    }

    @Test
    fun `handles malformed line without crash`() {
        val line = "not a logcat line at all"
        val result = LogLine.parse(line)
        assertEquals(LogLevel.VERBOSE, result.level)
        assertEquals(line, result.message)
    }
}
