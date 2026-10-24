package com.devtools.android.core

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore

/**
 * Application-level DataStore for user preferences.
 *
 * Keys:
 * - [AppPrefsKeys.ONBOARDING_DONE]: whether the user has completed the onboarding flow
 * - [AppPrefsKeys.THEME_PREF]: user-selected theme — "light", "dark", or "system"
 *
 * NOTE: This must remain a top-level property delegate. The DataStore library enforces
 * that exactly one delegate per name exists across the whole app.
 */
val Context.appPrefs by preferencesDataStore(name = "app_prefs")

object AppPrefsKeys {
    val ONBOARDING_DONE = booleanPreferencesKey("onboarding_done")
    val THEME_PREF = stringPreferencesKey("theme_pref")
}
