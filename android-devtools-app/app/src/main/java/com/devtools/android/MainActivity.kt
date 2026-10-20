package com.devtools.android

import android.os.Bundle
import com.google.android.material.snackbar.Snackbar
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.lifecycleScope
import com.devtools.android.core.BinaryManager
import com.devtools.android.core.RootDetector
import com.devtools.android.ui.MainScreen
import com.devtools.android.ui.theme.DevToolsTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isRooted = RootDetector.isRooted

        if (isRooted) {
            lifecycleScope.launch {
                val ok = BinaryManager.ensureBinaries(this@MainActivity)
                if (!ok) {
                    Snackbar.make(
                        findViewById(android.R.id.content),
                        "Storage full — cannot extract tools",
                        Snackbar.LENGTH_LONG
                    ).show()
                }
            }
        }

        enableEdgeToEdge()
        setContent {
            DevToolsTheme {
                MainScreen(isRooted = isRooted)
            }
        }
    }
}
