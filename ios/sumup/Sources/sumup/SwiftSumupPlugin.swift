import Flutter
import SumUpSDK
import UIKit

public class SumupPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sumup", binaryMessenger: registrar.messenger())
        let instance = SumupPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private func topController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            fatalError("Unable to get root view controller")
        }
        return rootViewController
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initSDK":
            guard let args = call.arguments as? String else {
                respond(result, method: "initSDK", status: false, message: ["errors": "Expected String"])
                return
            }
            let initResult = initSDK(affiliateKey: args)
            respond(result, method: "initSDK", message: ["result": initResult])
            
        case "login":
            self.login { success, reason in
                pluginResponse.status = success
                pluginResponse.message = ["result": reason]
                result(pluginResponse.toDictionary())
            }

        case "loginWithToken":
            guard let args = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected String", details: nil))
                return
            }
            self.loginWithToken(token: args) { success, reason in
                pluginResponse.status = success
                pluginResponse.message = ["result": reason]
                result(pluginResponse.toDictionary())
            }
            
        case "isLoggedIn":
            let isLoggedIn = self.isLoggedIn()
            respond(result, method: "isLoggedIn", status: isLoggedIn, message: ["result": isLoggedIn])
            
        case "getMerchant":
            let merchant = self.getMerchant()
            respond(result, method: "getMerchant", message: ["merchantCode": merchant?.merchantCode ?? "", "currencyCode": merchant?.currencyCode ?? ""])
            
        case "openSettings":
            self.openSettings
            { (error: String) in
                self.respond(result, method: "openSettings", message: ["result": error])
            }

        case "prepareForCheckout":
            self.prepareForCheckout()
            respond(result, method: "prepareForCheckout", message: ["result": "ok"])
            
        case "checkTapToPayAvailability":
            SumUpSDK.checkTapToPayAvailability { [weak self] isAvailable, isActivated, error in
                guard let self = self else { return }
                let pluginResponse = SumupPluginResponse(methodName: call.method, status: error == nil && isAvailable)
                if let error = error {
                    pluginResponse.message = ["isAvailable": false, "isActivated": false, "error": error.localizedDescription]
                    pluginResponse.status = false
                } else {
                    pluginResponse.message = ["isAvailable": isAvailable, "isActivated": isActivated]
                    pluginResponse.status = isAvailable
                }
                result(pluginResponse.toDictionary())
            }

        case "presentTapToPayActivation":
            SumUpSDK.presentTapToPayActivation(from: topController(), animated: true) { [weak self] success, error in
                guard let self = self else { return }
                let pluginResponse = SumupPluginResponse(methodName: call.method, status: success)
                pluginResponse.message = ["result": success ? "ok" : (error?.localizedDescription ?? "Activation failed")]
                result(pluginResponse.toDictionary())
            }

        case "checkout":
            guard let args = call.arguments as? [String: Any],
                  let payment = args["payment"] as? [String: Any],
                  let totalValue = payment["total"],
                  let currency = payment["currency"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected payment map with total and currency", details: nil))
                return
            }
            let totalDecimal: Decimal
            if let d = totalValue as? Double {
                totalDecimal = Decimal(d)
            } else if let s = totalValue as? String, let d = Decimal(string: s) {
                totalDecimal = d
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid total format", details: nil))
                return
            }
            let paymentMethodStr = args["paymentMethod"] as? String ?? "cardReader"

            let request = CheckoutRequest(total: NSDecimalNumber(decimal: totalDecimal), title: payment["title"] as? String, currencyCode: currency)

            if paymentMethodStr == "tapToPay" {
                request.paymentMethod = .tapToPay
            }

            request.foreignTransactionID = payment["foreignTransactionId"] as? String
            
            let tipValue = payment["tip"]
            if let tipD = tipValue as? Double, tipD > 0 {
                request.tipAmount = NSDecimalNumber(decimal: Decimal(tipD))
            } else if let tipS = tipValue as? String, let tipDec = Decimal(string: tipS), tipDec > 0 {
                request.tipAmount = NSDecimalNumber(decimal: tipDec)
            }

            let cardType = payment["cardType"] as? String
            if cardType != nil {
                request.processAs = cardType == "credit" ? ProcessAs.credit : ProcessAs.debit
                if cardType == "credit", let installments = payment["installments"] as? Int {
                    request.numberOfInstallments = installments
                }
            }

            let tipOnCardReader = payment["tipOnCardReader"] as? Bool ?? false
            if (tipOnCardReader && isTipOnCardReaderAvailable())
            {
                request.tipOnCardReaderIfAvailable = tipOnCardReader
            }

            request.saleItemsCount = payment["saleItemsCount"] as? UInt ?? 0
            
            if let tipRates = payment["customTipRates"] as? [Int], !tipRates.isEmpty {
                request.customTipRates = tipRates.map { NSNumber(value: $0) }
            }
            
            if let timeout = payment["successScreenTimeout"] as? Int {
                request.successScreenTimeout = TimeInterval(timeout)
            }

            if payment["skipSuccessScreen"] as? Bool ?? false {
                request.skipScreenOptions.update(with: SkipScreenOptions.success)
            }
            if payment["skipFailureScreen"] as? Bool ?? false {
                request.skipScreenOptions.update(with: SkipScreenOptions.failed)
            }

            SumUpSDK.checkout(with: request, from: topController())
            { (checkoutResult: CheckoutResult?, error: Error?) in
                let resultCheckout = checkoutResult ?? CheckoutResult()
                if resultCheckout.transactionCode == nil {
                    pluginResponse.message = ["success": false, "errors": error?.localizedDescription ?? "Checkout did not complete"]
                    result(pluginResponse.toDictionary())
                    return
                }

                pluginResponse.message = ["success": resultCheckout.success,
                                          "transactionCode": resultCheckout.transactionCode ?? "",
                                          "amount": resultCheckout.additionalInfo?["amount"] ?? "",
                                          "currency": resultCheckout.additionalInfo?["currency"] ?? "",
                                          "vatAmount": resultCheckout.additionalInfo?["vat_amount"] ?? "",
                                          "tipAmount": resultCheckout.additionalInfo?["tip_amount"] ?? "",
                                          "paymentType": resultCheckout.additionalInfo?["payment_type"] ?? "",
                                          "entryMode": resultCheckout.additionalInfo?["entry_mode"] ?? "",
                                          "installments": resultCheckout.additionalInfo?["installments"] ?? "",
                                          "products": resultCheckout.additionalInfo?["products"] ?? ""]

                let resultCard = resultCheckout.additionalInfo?["card"] as? [String: Any?]
                if let ct = resultCard?["type"] {
                    pluginResponse.message["cardType"] = ct
                }
                if let last4 = resultCard?["last_4_digits"] {
                    pluginResponse.message["cardLastDigits"] = last4
                }

                result(pluginResponse.toDictionary())
            }
            
        case "isCheckoutInProgress":
            let isInProgress = self.isCheckoutInProgress()
            pluginResponse.message = ["result": isInProgress]
            pluginResponse.status = isInProgress
            result(pluginResponse.toDictionary())
        
        case "isTipOnCardReaderAvailable":
            let isAvailable = self.isTipOnCardReaderAvailable()
            pluginResponse.message = ["result": isAvailable]
            pluginResponse.status = isAvailable
            result(pluginResponse.toDictionary())
            
        case "isCardTypeRequired":
            let isRequired = self.isCardTypeRequired()
            pluginResponse.message = ["result": isRequired]
            pluginResponse.status = isRequired
            result(pluginResponse.toDictionary())
            
        case "logout":
            self.logout(completion: {
                hasLoggedOut in
                pluginResponse.message = ["result": hasLoggedOut]
                result(pluginResponse.toDictionary())
            })
            
        case "lastReaderStatus":
            let status = SumUpSDK.lastReaderStatus
            pluginResponse.message = [
                "serialNumber": status?.serialNumber ?? "",
                "batteryLevel": status?.batteryLevel ?? 0,
                "isActive": status?.isActive ?? false,
                "readerType": String(describing: status?.readerType)
            ]
            pluginResponse.status = status != nil
            result(pluginResponse.toDictionary())
            
        default:
            pluginResponse.status = false
            pluginResponse.message = ["result": "Method not implemented"]
            result(pluginResponse.toDictionary())
        }
    }
    
    private func initSDK(affiliateKey: String) -> Bool {
        let setupResult = SumUpSDK.setup(affiliateKey: affiliateKey)
        return setupResult
    }
    
    private func login(completion: @escaping ((Bool, String) -> Void)) {
        guard !isLoggedIn() else {
            completion(false, "Already logged in")
            return
        }
        SumUpSDK.presentLogin(from: topController(), animated: true) { loggedIn, err in
            completion(loggedIn, err != nil ? err.debugDescription : (loggedIn ? "Login successful" : "Login dialog closed"))
        }
    }

    private func loginWithToken(token: String, completion: @escaping ((Bool, String) -> Void)) {
        guard !isLoggedIn() else {
            completion(false, "Already logged in")
            return
        }
        SumUpSDK.login(withToken: token) { loggedIn, err in
            completion(loggedIn, err != nil ? err.debugDescription : (loggedIn ? "Login successful" : "Token login failed"))
        }
    }

    private func isLoggedIn() -> Bool {
        return SumUpSDK.isLoggedIn
    }
    
    private func getMerchant() -> Merchant? {
        return SumUpSDK.currentMerchant
    }
    
    // Returns "ok" if everything is ok, otherwise returns the error message
    private func openSettings(completion: @escaping ((String) -> Void)) {
        SumUpSDK.presentCardReaderSettings(from: topController(), animated: true)
        { (_: Bool, presentationError: Error?) in
            guard let safeError = presentationError as NSError? else {
                completion("ok")
                return
            }
            
            let errorMessage: String
            
            switch (safeError.domain, safeError.code) {
            case (SumUpSDKErrorDomain, SumUpSDKError.accountNotLoggedIn.rawValue):
                errorMessage = "not logged in"
                
            case (SumUpSDKErrorDomain, SumUpSDKError.checkoutInProgress.rawValue):
                errorMessage = "checkout is in progress"
                
            default:
                errorMessage = "general"
            }
            
            completion(errorMessage)
        }
    }

    // MARK: - Private helpers

    private func respond(_ result: @escaping FlutterResult,
                         method: String,
                         status: Bool = true,
                         message: [String: Any] = [:]) {
        let response = SumupPluginResponse(methodName: method, status: status, message: message)
        result(response.toDictionary())
    }

    private func prepareForCheckout() {
        SumUpSDK.prepareForCheckout()
    }
    
    private func isCheckoutInProgress() -> Bool {
        return SumUpSDK.checkoutInProgress
    }
    
    private func isTipOnCardReaderAvailable() -> Bool {
        return SumUpSDK.isTipOnCardReaderAvailable
    }
    
    private func isCardTypeRequired() -> Bool {
        return SumUpSDK.isProcessAsRequired
    }
    
    private func logout(completion: @escaping ((Bool) -> Void)) {
        SumUpSDK.logout { _, error in
            completion(error == nil)
        }
    }
}

class SumupPluginResponse {
    var methodName: String
    var status: Bool
    var message: [String: Any]
    
    init(methodName: String, status: Bool) {
        self.methodName = methodName
        self.status = status
        message = [:]
    }
    
    init(methodName: String, status: Bool, message: [String: Any]) {
        self.methodName = methodName
        self.status = status
        self.message = message
    }
    
    func toDictionary() -> [String: Any] {
        return ["methodName": methodName, "status": status, "message": message]
    }
}
