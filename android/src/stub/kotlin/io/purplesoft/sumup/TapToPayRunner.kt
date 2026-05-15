package io.purplesoft.sumup

import android.content.Context

/**
 * Tap-to-Pay stub — returns graceful errors when the TTP SDK (utopia-sdk)
 * is not available. To enable Tap-to-Pay, set TTP Maven credentials in
 * gradle.properties (SUMUP_TTP_MAVEN_USERNAME / SUMUP_TTP_MAVEN_PASSWORD)
 * and rebuild.
 */
internal object TapToPayRunner {

    fun checkAvailability(
        applicationContext: Context,
        accessToken: String?
    ): Triple<Boolean, Boolean, String?> = Triple(
        false, false, "Tap-to-Pay SDK not included. Set SUMUP_TTP_MAVEN_USERNAME and SUMUP_TTP_MAVEN_PASSWORD in gradle.properties and rebuild."
    )

    suspend fun runCheckout(
        applicationContext: Context,
        payment: Map<String, Any?>,
        accessToken: String?,
        affiliateKey: String?,
        onResult: (Map<String, Any?>) -> Unit
    ) {
        onResult(mapOf("success" to false, "errors" to "Tap-to-Pay SDK not available. Add TTP Maven credentials to enable."))
    }

    suspend fun tearDown(applicationContext: Context) {}
}
