package com.devtools.android.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

private data class ThemeOption(
    val value: String,
    val label: String,
    val description: String
)

private val themeOptions = listOf(
    ThemeOption(
        value = "system",
        label = "System Default",
        description = "Follow the device's light/dark mode setting"
    ),
    ThemeOption(
        value = "light",
        label = "Light",
        description = "Always use light theme"
    ),
    ThemeOption(
        value = "dark",
        label = "Dark",
        description = "Always use dark theme"
    )
)

/**
 * Settings screen content.
 *
 * Renders a theme-selector using [RadioButton] rows inside a [selectableGroup] — Compose
 * does not have a RadioGroup widget; accessible selection semantics come from the row's
 * [selectable] modifier with [Role.RadioButton].
 *
 * @param currentTheme  Active theme key: "system", "light", or "dark".
 * @param onThemeChange Called when the user selects a new theme.
 * @param modifier      Optional layout modifier applied to the root [Column].
 */
@Composable
fun SettingsScreen(
    currentTheme: String,
    onThemeChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = "Appearance",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(vertical = 8.dp)
        )
        Text(
            text = "Theme",
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium
        )
        Spacer(Modifier.height(4.dp))
        Column(Modifier.selectableGroup()) {
            themeOptions.forEach { option ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = currentTheme == option.value,
                            onClick = { onThemeChange(option.value) },
                            role = Role.RadioButton
                        )
                        .padding(vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = currentTheme == option.value,
                        onClick = null  // handled by the row's selectable modifier
                    )
                    Column(Modifier.padding(start = 16.dp)) {
                        Text(
                            text = option.label,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = option.description,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        }
    }
}
