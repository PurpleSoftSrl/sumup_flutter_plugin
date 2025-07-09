package io.purplesoft.sumup

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import com.sumup.merchant.reader.api.SumUpAPI
import com.sumup.merchant.reader.api.SumUpLogin
import com.sumup.merchant.reader.api.SumUpPayment
import com.sumup.merchant.reader.api.SumUpPayment.builder
import com.sumup.merchant.reader.api.SumUpState
import com.sumup.merchant.reader.models.TransactionInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry


/** SumupPlugin */
class SumupPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private val tag = "SumupPlugin"

    private var operations: MutableMap<String, SumUpPluginResponseWrapper> = mutableMapOf()
    private var currentOperation: SumUpPluginResponseWrapper? = null

    private lateinit var affiliateKey: String
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "onAttachedToEngine")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sumup")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "onDetachedFromEngine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(tag, "onAttachedToActivity")
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(tag, "onDetachedFromActivityForConfigChanges")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(tag, "onReattachedToActivityForConfigChanges")
    }

    override fun onDetachedFromActivity() {
        Log.d(tag, "onDetachedFromActivity")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(tag, "onMethodCall: ${call.method}")
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
            "checkout" -> checkout(call.argument<Map<String, String>>("payment")!!, call.argument<Map<String, String>>("info"))
            "isCheckoutInProgress" -> isCheckoutInProgress().flutterResult()
            "isTipOnCardReaderAvailable" -> isTipOnCardReaderAvailable().flutterResult()
            "isCardTypeRequired" -> isCardTypeRequired().flutterResult()
            "logout" -> logout().flutterResult()
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
        Log.d(tag, "prepareForCheckout")
        SumUpAPI.prepareForCheckout()

        val currentOp = operations["prepareForCheckout"]!!
        currentOp.response.message = mutableMapOf("prepareForCheckout" to true)
        currentOp.response.status = true

        return currentOp
    }

    private fun checkout(@NonNull args: Map<String, Any?>, @Nullable info: Map<String, String>?) {
        Log.d(tag, "checkout")
        val payment = builder() // mandatory parameters
                .total((args["total"] as Double).toBigDecimal()) // minimum 1.00
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

    private fun isCheckoutInProgress(): SumUpPluginResponseWrapper {
        Log.d(tag, "isCheckoutInProgress")
        val currentOp = operations["isCheckoutInProgress"]!!
        currentOp.response.message = mutableMapOf("exception" to "isCheckoutInProgress method is not implemented in android")
        currentOp.response.status = false
        return currentOp
    }

    private fun isTipOnCardReaderAvailable(): SumUpPluginResponseWrapper {
        Log.d(tag, "isTipOnCardReaderAvailable")

        val isAvailable = SumUpAPI.isTipOnCardReaderAvailable()
        
        val currentOp = operations["isTipOnCardReaderAvailable"] ?: currentOperation!!
        currentOp.response.message = mutableMapOf("isAvailable" to isAvailable)
        currentOp.response.status = isAvailable
        return currentOp
    }

    private fun isCardTypeRequired(): SumUpPluginResponseWrapper {
        Log.d(tag, "isCardTypeRequired")
        val currentOp = operations["isCardTypeRequired"]!!
        currentOp.response.message =
            mutableMapOf("exception" to "isCardTypeRequired method is not implemented in android")
        currentOp.response.status = false
        return currentOp
    }

    private fun logout(): SumUpPluginResponseWrapper {
        Log.d(tag, "logout")
        SumUpAPI.logout()
        val loggedIn = SumUpAPI.isLoggedIn()

        val currentOp = operations["logout"]!!
        currentOp.response.message = mutableMapOf("isLoggedOut" to !loggedIn)
        currentOp.response.status = !loggedIn

        return currentOp
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(tag, "onActivityResult - RequestCode: $requestCode - Result Code: $resultCode")
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
        fun valueOf(value: Int) = values().find { it.code == value }
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
            "foreignTransactionId" to foreignTransactionId
            //inaccessible properties
            //"products" to products.map { product -> mapOf<String, Any?>("name" to product.name, "quantity" to product.quantity, "price" to product.price) },
    )

    m["success"] = status.equals("SUCCESSFUL", true)

    return m
}

fun TransactionInfo.Card.toMap(): Map<String, Any?> {
    return mapOf("last4Digits" to last4Digits, "type" to type)
}
