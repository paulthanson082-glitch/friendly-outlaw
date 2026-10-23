package com.devtools.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.datastore.preferences.core.edit
import androidx.lifecycle.lifecycleScope
import com.devtools.android.core.AppPrefsKeys
import com.devtools.android.core.BinaryManager
import com.devtools.android.core.RootDetector
import com.devtools.android.core.appPrefs
import com.devtools.android.modules.onboarding.OnboardingScreen
import com.devtools.android.ui.MainScreen
import com.devtools.android.ui.theme.DevToolsTheme
import android.widget.Toast
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val isRooted = RootDetector.isRooted

        // On rooted devices, ensure binaries are ready in the background.
        // This is idempotent (skipped when version hash matches) so subsequent
        // launches are fast. The onboarding flow also calls this for first-run setup.
        if (isRooted) {
            lifecycleScope.launch {
                val ok = BinaryManager.ensureBinaries(this@MainActivity)
                if (!ok) {
                    Toast.makeText(
                        this@MainActivity,
                        "Storage full — cannot extract tools",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }

        setContent {
            val context = LocalContext.current
            val scope = rememberCoroutineScope()

            // null = still loading; false = first launch (key absent); true = done
            val onboardingDone by context.appPrefs.data
                .map { it[AppPrefsKeys.ONBOARDING_DONE] ?: false }
                .collectAsState(initial = null)

            val themePref by context.appPrefs.data
                .map { it[AppPrefsKeys.THEME_PREF] ?: "system" }
                .collectAsState(initial = "system")

            val systemDark = isSystemInDarkTheme()
            val darkTheme = when (themePref) {
                "dark" -> true
                "light" -> false
                else -> systemDark
            }

            DevToolsTheme(darkTheme = darkTheme) {
                when (onboardingDone) {
                    null -> {
                        // DataStore not yet read — show spinner briefly
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                    false -> {
                        // First launch: show onboarding.
                        // OnboardingViewModel writes onboarding_done = true when Done,
                        // causing onboardingDone to recompose to true and switch below.
                        OnboardingScreen(onFinish = { /* reactive via DataStore */ })
                    }
                    else -> {
                        // Onboarding complete: show main app.
                        MainScreen(
                            isRooted = isRooted,
                            currentTheme = themePref,
                            onThemeChange = { theme ->
                                scope.launch {
                                    context.appPrefs.edit { prefs ->
                                        prefs[AppPrefsKeys.THEME_PREF] = theme
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}
