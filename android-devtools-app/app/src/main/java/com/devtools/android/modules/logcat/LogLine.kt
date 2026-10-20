package com.devtools.android.modules.logcat

/**
 * Log level matching Android's logcat priority letters.
 */
enum class LogLevel { ERROR, WARN, INFO, DEBUG, VERBOSE }

/**
 * A single parsed logcat line.
 *
 * @param timestamp   Date/time string from the log header (e.g. "08-15 12:34:56.789").
 * @param pid         Process ID string.
 * @param level       Parsed [LogLevel]; defaults to [LogLevel.VERBOSE] for unknown letters.
 * @param tag         Log tag (the component that emitted the line).
 * @param message     The actual log message text.
 */
data class LogLine(
    val timestamp: String,
    val pid: String,
    val level: LogLevel,
    val tag: String,
    val message: String
) {
    companion object {
        /**
         * Regex matching the `threadtime` logcat format:
         *   DATE TIME  PID  TID LEVEL TAG: MESSAGE
         *
         * Group 1 = timestamp, Group 2 = pid, Group 3 = level letter,
         * Group 4 = tag (no spaces), Group 5 = message.
         */
        private val PATTERN = Regex("""(\S+\s\S+)\s+(\d+)\s+\d+\s([EWIDV])\s+(\S+):\s(.*)""")

        /**
         * Parses a raw logcat line into a [LogLine].
         * Returns a [LogLine] with [LogLevel.VERBOSE] and the full [raw] string as
         * [message] when the line does not match the expected format.
         */
        fun parse(raw: String): LogLine {
            val match = PATTERN.find(raw)
            return if (match != null) {
                val (timestamp, pid, levelChar, tag, message) = match.destructured
                val level = when (levelChar) {
                    "E" -> LogLevel.ERROR
                    "W" -> LogLevel.WARN
                    "I" -> LogLevel.INFO
                    "D" -> LogLevel.DEBUG
                    else -> LogLevel.VERBOSE
                }
                LogLine(
                    timestamp = timestamp,
                    pid = pid,
                    level = level,
                    tag = tag,
                    message = message
                )
            } else {
                LogLine(
                    timestamp = "",
                    pid = "",
                    level = LogLevel.VERBOSE,
                    tag = "",
                    message = raw
                )
            }
        }
    }
}
