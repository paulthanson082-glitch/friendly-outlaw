package com.devtools.android.modules.onboarding

import android.app.Application
import androidx.datastore.preferences.core.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.AppPrefsKeys
import com.devtools.android.core.BinaryManager
import com.devtools.android.core.RootDetector
import com.devtools.android.core.appPrefs
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Each screen in the onboarding pager. */
sealed class OnboardingStep {
    object Welcome : OnboardingStep()
    data class RootStatus(val isRooted: Boolean) : OnboardingStep()
    object GrantReadLogs : OnboardingStep()
    object GrantUsageStats : OnboardingStep()
    data class ExtractBinaries(
        val inProgress: Boolean = false,
        val success: Boolean? = null
    ) : OnboardingStep()
    object Done : OnboardingStep()
}

class OnboardingViewModel(application: Application) : AndroidViewModel(application) {

    private val context get() = getApplication<Application>()

    private val _step = MutableStateFlow<OnboardingStep>(OnboardingStep.Welcome)
    val step: StateFlow<OnboardingStep> = _step.asStateFlow()

    /**
     * Advances to the next step.
     *
     * When the final step ([OnboardingStep.Done]) is reached, the DataStore flag
     * [AppPrefsKeys.ONBOARDING_DONE] is written so the host Activity's reactive
     * read switches to [com.devtools.android.ui.MainScreen] automatically.
     */
    fun advance() {
        val next: OnboardingStep = when (val current = _step.value) {
            is OnboardingStep.Welcome ->
                OnboardingStep.RootStatus(isRooted = RootDetector.isRooted)
            is OnboardingStep.RootStatus ->
                OnboardingStep.GrantReadLogs
            is OnboardingStep.GrantReadLogs ->
                OnboardingStep.GrantUsageStats
            is OnboardingStep.GrantUsageStats ->
                if (RootDetector.isRooted) OnboardingStep.ExtractBinaries() else OnboardingStep.Done
            is OnboardingStep.ExtractBinaries ->
                if (current.inProgress) current else OnboardingStep.Done
            is OnboardingStep.Done ->
                OnboardingStep.Done
        }
        _step.value = next
        if (next is OnboardingStep.Done) {
            markOnboardingDone()
        }
    }

    /**
     * Calls [BinaryManager.ensureBinaries] and updates the [OnboardingStep.ExtractBinaries]
     * state with progress and result.
     */
    fun extractBinaries() {
        _step.value = OnboardingStep.ExtractBinaries(inProgress = true, success = null)
        viewModelScope.launch {
            val success = BinaryManager.ensureBinaries(context)
            _step.value = OnboardingStep.ExtractBinaries(inProgress = false, success = success)
        }
    }

    private fun markOnboardingDone() {
        viewModelScope.launch {
            context.appPrefs.edit { prefs ->
                prefs[AppPrefsKeys.ONBOARDING_DONE] = true
            }
        }
    }
}
