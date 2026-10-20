package com.devtools.android.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = DevToolsGreen,
    onPrimary = DevToolsDark,
    secondary = DevToolsSurface,
    onSecondary = OnDevToolsDark,
    tertiary = DevToolsGreen,
    background = DevToolsDark,
    onBackground = OnDevToolsDark,
    surface = DevToolsSurface,
    onSurface = DevToolsOnSurface,
    error = DevToolsError
)

private val LightColorScheme = lightColorScheme(
    primary = DevToolsGreen,
    onPrimary = DevToolsDark,
    secondary = DevToolsLightSurface,
    onSecondary = DevToolsLightOnSurface,
    tertiary = DevToolsGreen,
    background = DevToolsLightBackground,
    onBackground = DevToolsLightOnSurface,
    surface = DevToolsLightSurface,
    onSurface = DevToolsLightOnSurface,
    error = DevToolsError
)

@Composable
fun DevToolsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
