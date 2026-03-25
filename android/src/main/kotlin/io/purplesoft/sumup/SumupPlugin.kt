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
import java.util.UUID


/** SumupPlugin */
class SumupPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private val tag = "SumupPlugin"

    private var operations: MutableMap<String, SumUpPluginResponseWrapper> = mutableMapOf()
    private var currentOperation: SumUpPluginResponseWrapper? = null

    private lateinit var affiliateKey: String
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity

    /** Stored token for Tap-to-Pay SDK (set when loginWithToken is called). */
    private var ttpAccessToken: String? = null

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(tag, "Sumup plugin: activity detached for config change.")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(tag, "Sumup plugin: activity reattached.")
    }

    override fun onDetachedFromActivity() {
        Log.d(tag, "Sumup plugin: activity detached.")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(tag, "Sumup plugin: method call: ${call.method}")
        if (!operations.containsKey(call.method)) {
            operations[call.method] = SumUpPluginResponseWrapper(result)
        }

        val sumUpPluginResponseWrapper = operations[call.method]!!
        sumUpPluginResponseWrapper.methodResult = result
        sumUpPluginResponseWrapper.response = SumupPluginResponse(call.method)

        currentOperation = sumUpPluginResponseWrapper

        when (call.method) {
            "initSDK" -> initSDK(call.arguments as String).flutterResult()
            "login" -> login()
            "loginWithToken" -> loginWithToken(call.arguments as String)
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
                    result.success(SumupPluginResponse("checkout").apply { status = false; message = mutableMapOf("errors" to "payment is required") }.toMap())
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
            else -> result.notImplemented()
        }
    }

    private fun initSDK(@NonNull key: String): SumUpPluginResponseWrapper {
        val currentOp = operations["initSDK"]!!
        try {
            SumUpState.init(activity.applicationContext)
            affiliateKey = key
            currentOp.response.message = mutableMapOf("initialized" to true)
            currentOp.response.status = true
        } catch (e: Exception) {
            currentOp.response.message = mutableMapOf("initialized" to false, "errors" to e.message)
            currentOp.response.status = false
        }
        return currentOp
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

        val currentOp = operations["isLoggedIn"]!!
        currentOp.response.message = mutableMapOf("isLoggedIn" to loggedIn)
        currentOp.response.status = loggedIn

        return currentOp
    }

    private fun getMerchant(): SumUpPluginResponseWrapper {
        val currentMerchant = SumUpAPI.getCurrentMerchant()
        val mCode = currentMerchant?.merchantCode ?: ""
        val mCurrency = currentMerchant?.currency?.isoCode ?: ""
        val mCodeValid = mCode != ""

        val currentOp = operations["getMerchant"]!!
        currentOp.response.message = mutableMapOf("merchantCode" to mCode, "currencyCode" to mCurrency)
        currentOp.response.status = mCodeValid

        return currentOp
    }

    private fun openSettings() {
        SumUpAPI.openCardReaderPage(activity, 3)
    }

    private fun prepareForCheckout(): SumUpPluginResponseWrapper {
        Log.d(tag, "Sumup plugin: prepare for checkout.")
        SumUpAPI.prepareForCheckout()

        val currentOp = operations["prepareForCheckout"]!!
        currentOp.response.message = mutableMapOf("prepareForCheckout" to true)
        currentOp.response.status = true

        return currentOp
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
        // Card reader checkout (existing flow; result delivered via onActivityResult)
        checkoutCardReader(payment, info)
    }

    private fun checkoutCardReader(@NonNull args: Map<String, Any?>, @Nullable info: Map<String, String>?) {
        Log.d(tag, "Sumup plugin: checkout (card reader).")
        val payment = builder()
                .total((args["total"] as Double).toBigDecimal())
                .title(args["title"] as String?)
                .currency(SumUpPayment.Currency.valueOf(args["currency"] as String))

        if (args["tip"] != null) payment.tip((args["tip"] as Double).toBigDecimal())
        if (args["tipOnCardReader"] != null && args["tipOnCardReader"] as Boolean) {
            val isTcrAvailable = isTipOnCardReaderAvailable().response.status
            if (isTcrAvailable) {
                payment.tipOnCardReader()
            }
        }

        if (args["customerEmail"] != null) payment.receiptEmail(args["customerEmail"] as String)
        if (args["customerPhone"] != null) payment.receiptSMS(args["customerPhone"] as String)

        if (args["foreignTransactionId"] != null) payment.foreignTransactionId(args["foreignTransactionId"] as String?)

        if (args["skipSuccessScreen"] != null && args["skipSuccessScreen"] as Boolean) payment.skipSuccessScreen()

        if (args["skipFailureScreen"] != null && args["skipFailureScreen"] as Boolean) payment.skipFailedScreen()

        if (!info.isNullOrEmpty()) {
            for (item in info) {
                payment.addAdditionalInfo(item.key, item.value)
            }
        }

        SumUpAPI.checkout(activity, payment.build(), 2)
    }

    private fun runTapToPayCheckout(payment: Map<String, Any?>, result: Result) {
        pluginScope.launch {
            TapToPayRunner.runCheckout(
                applicationContext = activity.applicationContext,
                payment = payment,
                accessToken = ttpAccessToken,
                affiliateKey = affiliateKey,
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
        // No activation UI on Android; TTP is ready after init with token.
        val response = SumupPluginResponse("presentTapToPayActivation")
        response.message = mutableMapOf("result" to "Not required on Android")
        response.status = true
        result.success(response.toMap())
    }

    private fun isCheckoutInProgress(): SumUpPluginResponseWrapper {
        Log.d(tag, "Sumup plugin: is checkout in progress.")
        val currentOp = operations["isCheckoutInProgress"]!!
        currentOp.response.message = mutableMapOf("exception" to "isCheckoutInProgress method is not implemented in android")
        currentOp.response.status = false
        return currentOp
    }

    private fun isTipOnCardReaderAvailable(): SumUpPluginResponseWrapper {
        Log.d(tag, "Sumup plugin: is tip on card reader available.")

        val isAvailable = SumUpAPI.isTipOnCardReaderAvailable()
        
        val currentOp = operations["isTipOnCardReaderAvailable"] ?: currentOperation!!
        currentOp.response.message = mutableMapOf("isAvailable" to isAvailable)
        currentOp.response.status = isAvailable
        return currentOp
    }

    private fun isCardTypeRequired(): SumUpPluginResponseWrapper {
        Log.d(tag, "Sumup plugin: is card type required.")
        val currentOp = operations["isCardTypeRequired"]!!
        currentOp.response.message =
            mutableMapOf("exception" to "isCardTypeRequired method is not implemented in android")
        currentOp.response.status = false
        return currentOp
    }

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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(tag, "Sumup plugin: activity result. RequestCode: $requestCode, ResultCode: $resultCode")
        val resultCodes = intArrayOf(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)

        if (resultCode !in resultCodes) return false

        val currentOp: SumUpPluginResponseWrapper = when (SumUpTask.valueOf(requestCode)) {
            SumUpTask.LOGIN -> operations["login"]
            SumUpTask.TOKEN_LOGIN -> operations["loginWithToken"]
            SumUpTask.CHECKOUT -> operations["checkout"]
            SumUpTask.SETTINGS -> operations["openSettings"]
            else -> currentOperation
        } ?: return false

        if (data != null && data.extras != null) {
            val extra: Bundle = data.extras!!
            val resultCodeInt = extra.getInt(SumUpAPI.Response.RESULT_CODE)
            val resultMessage = extra.getString(SumUpAPI.Response.MESSAGE)
            val resultCodeBoolean = resultCodeInt == 1
            currentOp.response.status = resultCodeBoolean

            when (SumUpTask.valueOf(requestCode)) {
                SumUpTask.LOGIN -> {
                    currentOp.response.message = mutableMapOf("loginResult" to resultCodeBoolean, "responseCode" to resultCodeInt, "responseMessage" to resultMessage, "requestCode" to requestCode)
                    currentOp.flutterResult()
                }
                SumUpTask.TOKEN_LOGIN -> {
                    currentOp.response.message = mutableMapOf("loginResult" to resultCodeBoolean, "responseCode" to resultCodeInt, "responseMessage" to resultMessage, "requestCode" to requestCode)
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
                else -> {
                    //UNKNOWN SUMUP TASK
                    //USE CURRENT OPERATION TO EMIT A RESULT
                    //IN THEORY THIS CASE NEVER HAPPEN
                    currentOp.response.message = mutableMapOf("responseCode" to resultCodeInt, "responseMessage" to resultMessage, "errors" to "Unknown SumUp Task", "requestCode" to requestCode)
                    currentOp.flutterResult()
                }
            }
          } else if (SumUpTask.valueOf(requestCode) == SumUpTask.SETTINGS) {
            currentOp.response.message = mutableMapOf("responseCode" to resultCode, "requestCode" to requestCode)
            currentOp.response.status = true
            currentOp.flutterResult()
        } else if (SumUpTask.valueOf(requestCode) == SumUpTask.LOGIN) {
            currentOp.response.message = mutableMapOf("responseCode" to resultCode, "requestCode" to requestCode)
            currentOp.response.status = false
            currentOp.flutterResult()
        } else if (SumUpTask.valueOf(requestCode) == SumUpTask.TOKEN_LOGIN) {
            currentOp.response.message = mutableMapOf("responseCode" to resultCode, "requestCode" to requestCode)
            currentOp.response.status = false
            currentOp.flutterResult()
        } else {
            currentOp.response.message = mutableMapOf("errors" to "Intent Data and/or Extras are null or empty")
            currentOp.response.status = false
        }

        return currentOp.response.status
    }
}

class SumUpPluginResponseWrapper(@NonNull var methodResult: Result) {
    lateinit var response: SumupPluginResponse
    fun flutterResult() {
        methodResult.success(response.toMap())
    }
}

class SumupPluginResponse(@NonNull var methodName: String) {
    var status: Boolean = false
    lateinit var message: MutableMap<String, Any?>
    fun toMap(): Map<String, Any?> {
        return mapOf("status" to status, "message" to message, "methodName" to methodName)
    }
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
