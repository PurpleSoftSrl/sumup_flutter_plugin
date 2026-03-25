package io.purplesoft.sumup

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import com.sumup.taptopay.TapToPay
import com.sumup.taptopay.TapToPayApiProvider
import com.sumup.taptopay.auth.AuthTokenProvider
import com.sumup.taptopay.payment.domain.model.api.AffiliateModel
import com.sumup.taptopay.payment.domain.model.api.CheckoutData
import com.sumup.taptopay.payment.domain.model.api.PaymentEvent
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.runBlocking
import java.util.UUID

/**
 * Runs Tap-to-Pay SDK flows (utopia-sdk dependency required).
 * See ANDROID_TTP.md.
 */
internal object TapToPayRunner {

    private const val TAG = "TapToPayRunner"

    @Volatile
    private var tapToPayInstance: TapToPay? = null

    /** True after a successful init. Init must be called only once per session. */
    @Volatile
    private var ttpInitDone = false

    private fun getTapToPay(context: Context): TapToPay? {
        tapToPayInstance?.let { return it }
        return try {
            TapToPayApiProvider.provide(context.applicationContext).also { tapToPayInstance = it }
        } catch (e: Exception) {
            Log.w(TAG, "Tap-to-Pay SDK provider initialization failed.", e)
            null
        }
    }

    private fun isAppDebuggable(context: Context): Boolean =
        (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    /** Maps SDK init/attestation errors to a user-friendly message. */
    private fun messageForInitError(e: Throwable, applicationContext: Context? = null): String {
        val root = e.cause ?: e
        val msg = (root.message ?: e.message)?.toString() ?: ""
        val cls = root.javaClass.name
        val isAttestationOrUt = cls.contains("com.sumup.taptopay.ut") ||
            msg.contains("com.sumup.taptopay.ut") ||
            msg.contains("attestation") ||
            cls.contains("Attestation")
        if (isAttestationOrUt && applicationContext != null && isAppDebuggable(applicationContext)) {
            return "Tap-to-Pay requires a release build (debug builds fail attestation). Use: flutter run --release or install a release APK."
        }
        if (isAttestationOrUt) {
            return "Tap-to-Pay init failed: use a release build (flutter run --release), disable USB debugging and Developer mode, then retry."
        }
        if (msg.isNotBlank()) return msg
        return cls.substringAfterLast('.').ifBlank { root.javaClass.simpleName ?: "Init failed" }
    }

    private fun formatTapToPayError(err: String?): String {
        if (err.isNullOrBlank()) return "Transaction failed"
        return when {
            err.contains("UsbDebuggingEnabled") -> "Disable USB debugging in Developer Options to use Tap to Pay."
            err.contains("AppDebuggable") -> "Tap to Pay requires a release build (not debug)."
            err.contains("Attestation") -> "Device attestation failed. Disable USB debugging and Developer Options, then retry."
            err.contains("CheckoutFailed") -> "Checkout failed. Please try again."
            else -> err
        }
    }

    /** Returns Triple(isAvailable, isActivated, errorMessage). errorMessage is set when false, false. */
    fun checkAvailability(
        applicationContext: Context,
        accessToken: String?
    ): Triple<Boolean, Boolean, String?> = runCatching {
        if (accessToken.isNullOrBlank()) return Triple(false, false, "No token: call loginWithToken first")
        if (android.os.Build.VERSION.SDK_INT < 30) return Triple(false, false, "Tap-to-Pay requires Android 11+ (API 30)")
        if (isAppDebuggable(applicationContext)) return Triple(false, false, "Tap-to-Pay requires a release build (debug fails attestation). Use: flutter run --release or install a release APK.")
        val tapToPay = getTapToPay(applicationContext)
            ?: return Triple(false, false, "Tap-to-Pay SDK not loaded (utopia-sdk + Maven credentials)")
        val authProvider = object : AuthTokenProvider {
            override fun getAccessToken(): String = accessToken
        }
        val initResult = runBlocking { tapToPay.init(authProvider) }
        when {
            initResult.isSuccess -> {
                ttpInitDone = true
                Triple(true, true, null)
            }
            else -> {
                val ex = initResult.exceptionOrNull()!!
                val exMsg = ex.message?.toString() ?: ""
                val exCls = ex.javaClass.name
                if (exCls.contains("AlreadyInitialized") || exMsg.contains("AlreadyInitialized")) {
                    ttpInitDone = true
                    Triple(true, true, null)
                } else {
                    Triple(false, false, messageForInitError(ex, applicationContext))
                }
            }
        }
    }.getOrElse { e ->
        Log.e(TAG, "Tap-to-Pay availability check failed.", e)
        Triple(false, false, messageForInitError(e, applicationContext))
    }

    suspend fun runCheckout(
        applicationContext: Context,
        payment: Map<String, Any?>,
        accessToken: String?,
        affiliateKey: String?,
        onResult: (Map<String, Any?>) -> Unit
    ) {
        if (accessToken.isNullOrBlank()) {
            onResult(mapOf(
                "success" to false,
                "errors" to "Tap-to-Pay requires login with token (loginWithToken)."
            ))
            return
        }
        val tapToPay = getTapToPay(applicationContext)
        if (tapToPay == null) {
            onResult(mapOf("success" to false, "errors" to "Tap-to-Pay SDK not available."))
            return
        }
        if (isAppDebuggable(applicationContext)) {
            onResult(mapOf("success" to false, "errors" to "Tap-to-Pay requires a release build (debug fails attestation). Use: flutter run --release or install a release APK."))
            return
        }
        try {
            if (!ttpInitDone) {
                val authProvider = object : AuthTokenProvider {
                    override fun getAccessToken(): String = accessToken
                }
                val initResult = tapToPay.init(authProvider)
                if (initResult.isFailure) {
                    val ex = initResult.exceptionOrNull()!!
                    val exMsg = ex.message?.toString() ?: ""
                    val exCls = ex.javaClass.name
                    if (!exCls.contains("AlreadyInitialized") && !exMsg.contains("AlreadyInitialized")) {
                        onResult(mapOf("success" to false, "errors" to messageForInitError(ex, applicationContext)))
                        return
                    }
                }
                ttpInitDone = true
            }
            val total = (payment["total"] as? Number)?.toDouble() ?: 0.0
            val tip = (payment["tip"] as? Number)?.toDouble() ?: 0.0
            val totalMinor = (total * 100).toLong()
            val tipsMinor = if (tip > 0) (tip * 100).toLong() else null
            val requestedForeignTransactionId = (payment["foreignTransactionId"] as? String)
                ?.takeIf { it.isNotBlank() }
            val clientTxId = requestedForeignTransactionId
                ?: UUID.randomUUID().toString()
            val skipSuccessScreen = payment["skipSuccessScreen"] == true
            val affiliateData = affiliateKey
                ?.takeIf { it.isNotBlank() }
                ?.let { key ->
                    AffiliateModel(
                        key,
                        requestedForeignTransactionId,
                        null
                    )
                }
            val checkoutData = CheckoutData(
                totalAmount = totalMinor,
                tipsAmount = tipsMinor,
                vatAmount = null,
                clientUniqueTransactionId = clientTxId,
                customItems = null,
                priceItems = null,
                products = null,
                processCardAs = null,
                affiliateData = affiliateData
            )
            // resultSent guards against duplicate onResult calls:
            // TransactionDone fires first; PaymentFlowClosedSuccessfully fires after the
            // success screen is dismissed (when skipSuccessScreen=false). Only the first
            // terminal event should deliver the result to Flutter.
            var resultSent = false
            tapToPay.startPayment(checkoutData, skipSuccessScreen)
                .catch { e ->
                    if (!resultSent) {
                        resultSent = true
                        Log.e(TAG, "Tap-to-Pay payment flow error.", e)
                        onResult(mapOf("success" to false, "errors" to messageForInitError(e, applicationContext)))
                    }
                }
                .collect { event ->
                    if (resultSent) return@collect
                    val result = paymentEventToResult(event)
                    if (result != null) {
                        resultSent = true
                        onResult(result)
                    } else {
                        Log.d(TAG, "Tap-to-Pay intermediate event: ${event.javaClass.simpleName}")
                    }
                }
        } catch (e: Exception) {
            Log.e(TAG, "Tap-to-Pay checkout failed.", e)
            onResult(mapOf("success" to false, "errors" to messageForInitError(e, applicationContext)))
        }
    }

    /**
     * Maps a terminal PaymentEvent to a result map. Returns null for intermediate events
     * (CardRequested, CardPresented, CVMRequested, CVMPresented, PaymentFlowClosedSuccessfully)
     * which should not terminate the payment result.
     */
    private fun paymentEventToResult(event: PaymentEvent): Map<String, Any?>? = when (event) {
        is PaymentEvent.TransactionDone -> {
            val o = event.paymentOutput
            mapOf(
                "transactionCode" to o.txCode,
                "cardType" to o.cardType,
                "cardLastDigits" to o.lastFour,
                "foreignTransactionId" to o.serverTransactionId,
                "merchantCode" to o.merchantCode,
                "cardScheme" to o.cardScheme,
                "success" to true
            ).filterValues { it != null }
        }
        is PaymentEvent.TransactionFailed -> {
            val errStr = event.tapToPayException?.message
                ?: event.tapToPayException?.javaClass?.simpleName
                ?: "Transaction failed"
            Log.e(TAG, "Tap-to-Pay transaction failed: $errStr")
            val base = event.paymentOutput?.let { o ->
                mapOf(
                    "transactionCode" to o.txCode,
                    "foreignTransactionId" to o.serverTransactionId
                ).filterValues { it != null }
            } ?: emptyMap()
            base + mapOf("success" to false, "errors" to formatTapToPayError(errStr), "rawError" to errStr)
        }
        is PaymentEvent.TransactionCanceled ->
            mapOf("success" to false, "errors" to "Transaction canceled")
        is PaymentEvent.TransactionResultUnknown ->
            mapOf("success" to false, "errors" to "Transaction result unknown")
        // PaymentFlowClosedSuccessfully fires after the success screen is dismissed.
        // TransactionDone already delivered the result, so return null to avoid a double call.
        // All other events (CardRequested, CardPresented, CVMRequested, CVMPresented) are
        // intermediate and should also return null.
        else -> null
    }

    suspend fun tearDown(applicationContext: Context) {
        try {
            getTapToPay(applicationContext)?.tearDown()
        } catch (e: Exception) {
            Log.w(TAG, "Tap-to-Pay session teardown failed.", e)
        } finally {
            tapToPayInstance = null
            ttpInitDone = false
        }
    }
}
