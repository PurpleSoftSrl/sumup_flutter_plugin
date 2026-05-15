package io.purplesoft.sumup

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import com.sumup.merchant.reader.api.SumUpAPI
import com.sumup.merchant.reader.api.SumUpLogin
import com.sumup.merchant.reader.api.SumUpPayment
import com.sumup.merchant.reader.api.SumUpPayment.builder
import com.sumup.reader.sdk.api.SumUpState
import com.sumup.checkout.core.models.TransactionInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.math.BigDecimal
import java.util.UUID

class SumupPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private val tag = "SumupPlugin"

    private var operations: MutableMap<String, SumUpPluginResponseWrapper> = mutableMapOf()
    private var currentOperation: SumUpPluginResponseWrapper? = null

    private lateinit var affiliateKey: String
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity

    private var ttpAccessToken: String? = null

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // ── DRY helpers ──────────────────────────────────────────

    private fun respond(key: String, status: Boolean, message: Map<String, Any?>): SumUpPluginResponseWrapper {
        val o = operations[key]
        return if (o != null) {
            with(o.response) {
                this.status = status
                this.message = message.toMutableMap()
            }
            o
        } else {
            currentOperation?.also {
                with(it.response) {
                    this.status = status
                    this.message = message.toMutableMap()
                }
            } ?: throw IllegalStateException("No active operation for key: $key")
        }
    }

    // ── Engine lifecycle ─────────────────────────────────────

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "Sumup plugin: engine attached.")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sumup")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "Sumup plugin: engine detached.")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(tag, "Sumup plugin: activity attached.")
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    // ── Method dispatch ──────────────────────────────────────

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(tag, "Sumup plugin: method call: ${call.method}")

        val wrapper = operations.getOrPut(call.method) { SumUpPluginResponseWrapper(result) }.also {
            it.methodResult = result
            it.response = SumupPluginResponse(call.method)
            it.cleanup = { operations.remove(call.method) }
        }
        currentOperation = wrapper

        when (call.method) {
            "initSDK" -> {
                val key = call.arguments as? String
                (if (key != null) initSDK(key) else respond("initSDK", false, mapOf("errors" to "Missing affiliate key"))).flutterResult()
            }
            "login" -> login()
            "loginWithToken" -> {
                val token = call.arguments as? String
                if (token != null) loginWithToken(token) else respond("loginWithToken", false, mapOf("errors" to "Missing token"))
            }
            "isLoggedIn" -> isLoggedIn().flutterResult()
            "getMerchant" -> getMerchant().flutterResult()
            "openSettings" -> openSettings()
            "prepareForCheckout" -> prepareForCheckout().flutterResult()
            "checkout" -> {
                val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                val payment = args["payment"] as? Map<String, Any?>
                val paymentMethod = (args["paymentMethod"] as? String) ?: "cardReader"
                val info = args["info"] as? Map<String, String>
                if (payment == null) {
                    result.success(SumupPluginResponse("checkout").apply {
                        status = false
                        message = mutableMapOf("errors" to "payment is required")
                    }.toMap())
                } else {
                    checkout(payment, paymentMethod, info, result)
                }
            }
            "isCheckoutInProgress" -> isCheckoutInProgress().flutterResult()
            "isTipOnCardReaderAvailable" -> isTipOnCardReaderAvailable().flutterResult()
            "isCardTypeRequired" -> isCardTypeRequired().flutterResult()
            "checkTapToPayAvailability" -> checkTapToPayAvailability(result)
            "presentTapToPayActivation" -> presentTapToPayActivation(result)
            "logout" -> logout(result)
            "isCardReaderConnected" ->
                respond("isCardReaderConnected", true, mapOf("connected" to SumUpAPI.isCardReaderConnected())).flutterResult()
            "getSavedCardReaderDetails" -> getSavedCardReaderDetails(result)
            else -> result.notImplemented()
        }
    }

    // ── SDK operations ───────────────────────────────────────

    private fun initSDK(@NonNull key: String): SumUpPluginResponseWrapper {
        return try {
            SumUpState.init(activity.applicationContext)
            affiliateKey = key
            respond("initSDK", true, mapOf("initialized" to true))
        } catch (e: Exception) {
            respond("initSDK", false, mapOf("initialized" to false, "errors" to e.message))
        }
    }

    private fun login() {
        val sumupLogin = SumUpLogin.builder(affiliateKey).build()
        SumUpAPI.openLoginActivity(activity, sumupLogin, SumUpTask.LOGIN.code)
    }

    private fun loginWithToken(@NonNull token: String) {
        ttpAccessToken = token
        val sumupLogin = SumUpLogin.builder(affiliateKey).accessToken(token).build()
        SumUpAPI.openLoginActivity(activity, sumupLogin, SumUpTask.TOKEN_LOGIN.code)
    }

    private fun isLoggedIn(): SumUpPluginResponseWrapper {
        val loggedIn = SumUpAPI.isLoggedIn()
        return respond("isLoggedIn", loggedIn, mapOf("isLoggedIn" to loggedIn))
    }

    private fun getMerchant(): SumUpPluginResponseWrapper {
        val merchant = SumUpAPI.getCurrentMerchant()
        val code = merchant?.merchantCode ?: ""
        val currency = merchant?.currency?.isoCode ?: ""
        return respond("getMerchant", code.isNotEmpty(), mapOf("merchantCode" to code, "currencyCode" to currency))
    }

    private fun openSettings() {
        SumUpAPI.openCardReaderPage(activity, 3)
    }

    private fun prepareForCheckout(): SumUpPluginResponseWrapper {
        Log.d(tag, "Sumup plugin: prepare for checkout.")
        SumUpAPI.prepareForCheckout()
        return respond("prepareForCheckout", true, mapOf("prepareForCheckout" to true))
    }

    private fun checkout(
        payment: Map<String, Any?>,
        paymentMethod: String,
        info: Map<String, String>?,
        result: Result
    ) {
        if (paymentMethod == "tapToPay") {
            runTapToPayCheckout(payment, result)
            return
        }
        checkoutCardReader(payment, info)
    }

    private fun checkoutCardReader(@NonNull args: Map<String, Any?>, @Nullable info: Map<String, String>?) {
        Log.d(tag, "Sumup plugin: checkout (card reader).")
        val totalStr = args["total"]?.toString()
        if (totalStr == null) {
            respond("checkout", false, mapOf("errors" to "Missing total")).flutterResult()
            return
        }
        val currencyStr = args["currency"] as? String
        if (currencyStr == null) {
            respond("checkout", false, mapOf("errors" to "Missing currency")).flutterResult()
            return
        }
        val currency = try {
            SumUpPayment.Currency.valueOf(currencyStr)
        } catch (e: IllegalArgumentException) {
            respond("checkout", false, mapOf("errors" to "Invalid currency: $currencyStr")).flutterResult()
            return
        }

        val payment = builder()
            .total(BigDecimal(totalStr))
            .title(args["title"] as? String)
            .currency(currency)

        val tip = args["tip"]
        if (tip is Number) payment.tip(BigDecimal(tip.toString()))
        if (args["tipOnCardReader"] == true) {
            if (isTipOnCardReaderAvailable().response.status) {
                payment.tipOnCardReader()
            }
        }
        (args["customerEmail"] as? String)?.let { payment.receiptEmail(it) }
        (args["customerPhone"] as? String)?.let { payment.receiptSMS(it) }
        (args["foreignTransactionId"] as? String)?.let { payment.foreignTransactionId(it) }
        if (args["skipSuccessScreen"] == true) payment.skipSuccessScreen()
        if (args["skipFailureScreen"] == true) payment.skipFailedScreen()

        if (!info.isNullOrEmpty()) {
            for (item in info) {
                payment.addAdditionalInfo(item.key, item.value)
            }
        }

        (args["successScreenTimeout"] as? Int)?.let { payment.successScreenTimeout(it) }

        SumUpAPI.checkout(activity, payment.build(), 2)
    }

    private fun runTapToPayCheckout(payment: Map<String, Any?>, result: Result) {
        pluginScope.launch {
            TapToPayRunner.runCheckout(
                applicationContext = activity.applicationContext,
                payment = payment,
                accessToken = ttpAccessToken,
                affiliateKey = if (this@SumupPlugin::affiliateKey.isInitialized) this@SumupPlugin.affiliateKey else null,
                onResult = { responseMap ->
                    result.success(
                        mapOf(
                            "methodName" to "checkout",
                            "status" to (responseMap["success"] == true),
                            "message" to responseMap
                        )
                    )
                }
            )
        }
    }

    private fun checkTapToPayAvailability(result: Result) {
        pluginScope.launch {
            val response = SumupPluginResponse("checkTapToPayAvailability")
            try {
                val (isAvailable, isActivated, errorMsg) = withContext(Dispatchers.Default) {
                    TapToPayRunner.checkAvailability(
                        applicationContext = activity.applicationContext,
                        accessToken = ttpAccessToken
                    )
                }
                response.message = mutableMapOf(
                    "isAvailable" to isAvailable,
                    "isActivated" to isActivated
                )
                if (errorMsg != null) response.message["error"] = errorMsg
                response.status = isAvailable
            } catch (e: Exception) {
                Log.e(tag, "Tap-to-Pay availability check failed.", e)
                response.message = mutableMapOf(
                    "isAvailable" to false,
                    "isActivated" to false,
                    "error" to (e.message ?: "Unknown error")
                )
                response.status = false
            }
            result.success(response.toMap())
        }
    }

    private fun presentTapToPayActivation(result: Result) {
        val response = SumupPluginResponse("presentTapToPayActivation")
        response.message = mutableMapOf("result" to "Not required on Android")
        response.status = true
        result.success(response.toMap())
    }

    private fun isCheckoutInProgress(): SumUpPluginResponseWrapper =
        respond("isCheckoutInProgress", false, mapOf("exception" to "isCheckoutInProgress method is not implemented in android"))

    private fun isTipOnCardReaderAvailable(): SumUpPluginResponseWrapper {
        val isAvailable = SumUpAPI.isTipOnCardReaderAvailable()
        return respond("isTipOnCardReaderAvailable", isAvailable, mapOf("isAvailable" to isAvailable))
    }

    private fun isCardTypeRequired(): SumUpPluginResponseWrapper =
        respond("isCardTypeRequired", false, mapOf("exception" to "isCardTypeRequired method is not implemented in android"))

    private fun logout(result: Result) {
        Log.d(tag, "Sumup plugin: logout.")
        pluginScope.launch {
            try {
                TapToPayRunner.tearDown(activity.applicationContext)
            } catch (e: Exception) {
                Log.w(tag, "Tap-to-Pay session teardown failed.", e)
            }
            ttpAccessToken = null
            SumUpAPI.logout()
            val loggedIn = SumUpAPI.isLoggedIn()
            val response = SumupPluginResponse("logout").apply {
                message = mutableMapOf("isLoggedOut" to !loggedIn)
                status = !loggedIn
            }
            result.success(response.toMap())
        }
    }

    private fun getSavedCardReaderDetails(result: Result) {
        result.success(SumupPluginResponse("getSavedCardReaderDetails").apply {
            status = false
            message = mutableMapOf("error" to "getSavedCardReaderDetails not yet implemented — API shape TBD")
        }.toMap())
    }

    // ── Activity result ──────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(tag, "Sumup plugin: activity result. RequestCode: $requestCode, ResultCode: $resultCode")
        val resultCodes = intArrayOf(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
        if (resultCode !in resultCodes) return false

        val task = SumUpTask.valueOf(requestCode) ?: return false
        val currentOp = when (task) {
            SumUpTask.LOGIN -> operations["login"]
            SumUpTask.TOKEN_LOGIN -> operations["loginWithToken"]
            SumUpTask.CHECKOUT -> operations["checkout"]
            SumUpTask.SETTINGS -> operations["openSettings"]
        } ?: currentOperation ?: return false

        if (data != null && data.extras != null) {
            val extra: Bundle = data.extras!!
            val resultCodeInt = extra.getInt(SumUpAPI.Response.RESULT_CODE)
            val resultMessage = extra.getString(SumUpAPI.Response.MESSAGE)
            val resultCodeBoolean = resultCodeInt == 1
            currentOp.response.status = resultCodeBoolean

            when (task) {
                SumUpTask.LOGIN, SumUpTask.TOKEN_LOGIN -> {
                    currentOp.response.message = mutableMapOf(
                        "loginResult" to resultCodeBoolean,
                        "responseCode" to resultCodeInt,
                        "responseMessage" to resultMessage,
                        "requestCode" to requestCode
                    )
                    currentOp.flutterResult()
                }
                SumUpTask.CHECKOUT -> {
                    val txCode = extra.getString(SumUpAPI.Response.TX_CODE)
                    val receiptSent = extra.getBoolean(SumUpAPI.Response.RECEIPT_SENT)
                    @Suppress("DEPRECATION")
                    val txInfo: TransactionInfo? = extra.getParcelable(SumUpAPI.Response.TX_INFO)

                    currentOp.response.message = mutableMapOf(
                        "responseCode" to resultCodeInt,
                        "responseMessage" to resultMessage,
                        "txCode" to txCode,
                        "receiptSent" to receiptSent,
                        "requestCode" to requestCode,
                        "success" to resultCodeBoolean
                    )
                    txInfo?.toMap()?.let { currentOp.response.message.putAll(it) }
                    currentOp.flutterResult()
                }
                SumUpTask.SETTINGS -> {
                    currentOp.response.message = mutableMapOf("responseCode" to resultCodeInt, "responseMessage" to resultMessage, "requestCode" to requestCode)
                    currentOp.response.status = true
                    currentOp.flutterResult()
                }
            }
        } else when (task) {
            SumUpTask.SETTINGS -> {
                currentOp.response.message = mutableMapOf("responseCode" to resultCode, "requestCode" to requestCode)
                currentOp.response.status = true
                currentOp.flutterResult()
            }
            SumUpTask.LOGIN, SumUpTask.TOKEN_LOGIN, SumUpTask.CHECKOUT -> {
                currentOp.response.message = mutableMapOf("responseCode" to resultCode, "requestCode" to requestCode)
                currentOp.response.status = false
                currentOp.flutterResult()
            }
        }

        return currentOp.response.status
    }
}

// ── Support types ────────────────────────────────────────────

class SumUpPluginResponseWrapper(@NonNull var methodResult: Result) {
    lateinit var response: SumupPluginResponse
    internal var cleanup: (() -> Unit)? = null
    fun flutterResult() {
        methodResult.success(response.toMap())
        cleanup?.invoke()
    }
}

class SumupPluginResponse(@NonNull var methodName: String) {
    var status: Boolean = false
    lateinit var message: MutableMap<String, Any?>
    fun toMap(): Map<String, Any?> =
        mapOf("status" to status, "message" to message, "methodName" to methodName)
}

enum class SumUpTask(val code: Int) {
    LOGIN(1), CHECKOUT(2), SETTINGS(3), TOKEN_LOGIN(4);

    companion object {
        fun valueOf(value: Int) = entries.find { it.code == value }
    }
}

fun TransactionInfo.toMap(): Map<String, Any?> {
    val card = card.toMap()
    val m = mutableMapOf(
        "transactionCode" to transactionCode,
        "amount" to amount,
        "currency" to currency,
        "vatAmount" to vatAmount,
        "tipAmount" to tipAmount,
        "paymentType" to paymentType,
        "entryMode" to entryMode,
        "installments" to installments,
        "cardType" to card["type"],
        "cardLastDigits" to card["last4Digits"],
        "merchantCode" to merchantCode,
        "foreignTransactionId" to foreignTransactionId,
        "products" to products?.map { product ->
            mapOf<String, Any?>(
                "name" to product.name,
                "price" to product.price,
                "quantity" to product.quantity
            )
        }
    )
    m["success"] = status.equals("SUCCESSFUL", true)
    return m
}

fun TransactionInfo.Card.toMap(): Map<String, Any?> {
    return mapOf("last4Digits" to last4Digits, "type" to type)
}
