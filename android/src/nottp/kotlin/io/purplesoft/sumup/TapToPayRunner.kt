package io.purplesoft.sumup

import android.content.Context

/**
 * No-op Tap-to-Pay implementation, compiled when the build is configured WITHOUT the
 * SumUp Tap-to-Pay SDK (utopia-sdk). Selected by android/build.gradle when the
 * SUMUP_TTP_MAVEN_USERNAME Gradle property is not provided.
 *
 * It mirrors the public API surface of the real `ttp` source-set TapToPayRunner so that
 * SumupPlugin.kt compiles unchanged. Every entry point reports that Tap-to-Pay is not
 * available in this build. The card-reader (merchant-sdk) checkout path is unaffected.
 *
 * To enable Tap-to-Pay, supply the SumUp Tap-to-Pay Maven credentials
 * (SUMUP_TTP_MAVEN_USERNAME / SUMUP_TTP_MAVEN_PASSWORD) and rebuild — the real
 * implementation in src/ttp is then compiled instead. See ANDROID_TTP.md.
 */
internal object TapToPayRunner {

    private const val UNAVAILABLE =
        "Tap-to-Pay is not included in this build (compiled without utopia-sdk). " +
        "Rebuild with the SumUp Tap-to-Pay Maven credentials to enable it."

    /** Returns Triple(isAvailable, isActivated, errorMessage). */
    @Suppress("UNUSED_PARAMETER")
    fun checkAvailability(
        applicationContext: Context,
        accessToken: String?
    ): Triple<Boolean, Boolean, String?> = Triple(false, false, UNAVAILABLE)

    @Suppress("UNUSED_PARAMETER")
    suspend fun runCheckout(
        applicationContext: Context,
        payment: Map<String, Any?>,
        accessToken: String?,
        affiliateKey: String?,
        onResult: (Map<String, Any?>) -> Unit
    ) {
        onResult(mapOf("success" to false, "errors" to UNAVAILABLE))
    }

    @Suppress("UNUSED_PARAMETER")
    suspend fun tearDown(applicationContext: Context) {
        // no-op: nothing to tear down when Tap-to-Pay is not compiled in
    }
}
