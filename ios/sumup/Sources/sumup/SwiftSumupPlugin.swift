import Flutter
import SumUpSDK
import UIKit

public class SwiftSumupPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sumup", binaryMessenger: registrar.messenger())
        let instance = SwiftSumupPlugin()
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
        let pluginResponse = SumupPluginResponse(methodName: call.method, status: true)
        
        switch call.method {
        case "initSDK":
            let initResult = initSDK(affiliateKey: call.arguments as! String)
            pluginResponse.message = ["result": initResult]
            result(pluginResponse.toDictionary())
            
        case "login":
            self.login { success, reason in
                pluginResponse.status = success
                pluginResponse.message = ["result": reason]
                result(pluginResponse.toDictionary())
            }

        case "loginWithToken":
            self.loginWithToken(token: call.arguments as! String) { success, reason in
                pluginResponse.status = success
                pluginResponse.message = ["result": reason]
                result(pluginResponse.toDictionary())
            }
            
        case "isLoggedIn":
            let isLoggedIn = self.isLoggedIn()
            pluginResponse.message = ["result": isLoggedIn]
            pluginResponse.status = isLoggedIn
            result(pluginResponse.toDictionary())
            
        case "getMerchant":
            let merchant = self.getMerchant()
            pluginResponse.message = ["merchantCode": merchant?.merchantCode ?? "", "currencyCode": merchant?.currencyCode ?? ""]
            result(pluginResponse.toDictionary())
            
        case "openSettings":
            self.openSettings
            { (error: String) in
                pluginResponse.message = ["result": error]
                result(pluginResponse.toDictionary())
            }

        case "prepareForCheckout":
            self.prepareForCheckout()
            pluginResponse.status = true
            pluginResponse.message = ["result": "ok"]
            result(pluginResponse.toDictionary())
            
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
            let args = call.arguments as! [String: Any]
            let payment = args["payment"] as! [String: Any]
            let paymentMethodStr = args["paymentMethod"] as? String ?? "cardReader"

            let request = CheckoutRequest(total: NSDecimalNumber(floatLiteral: payment["total"] as! Double), title: payment["title"] as? String, currencyCode: payment["currency"] as! String)

            if paymentMethodStr == "tapToPay" {
                request.paymentMethod = .tapToPay
            }

            request.foreignTransactionID = payment["foreignTransactionId"] as? String
            request.tipAmount = NSDecimalNumber(floatLiteral: payment["tip"] as! Double)

            let cardType = payment["cardType"] as? String
            if cardType != nil {
                request.processAs = cardType == "credit" ? ProcessAs.credit : ProcessAs.debit
            }

            let tipOnCardReader = payment["tipOnCardReader"] as! Bool
            if (tipOnCardReader && isTipOnCardReaderAvailable())
            {
                request.tipOnCardReaderIfAvailable = tipOnCardReader
            }

            request.saleItemsCount = payment["saleItemsCount"] as! UInt

            if payment["skipSuccessScreen"] as! Bool {
                request.skipScreenOptions.update(with: SkipScreenOptions.success)
            }
            if payment["skipFailureScreen"] as! Bool {
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
            
        default:
            pluginResponse.status = false
            pluginResponse.message = ["result": "Method not implemented"]
            result(pluginResponse.toDictionary())
        }
    }
    
    private func initSDK(affiliateKey: String) -> Bool {
        let setupResult = SumUpSDK.setup(withAPIKey: affiliateKey)
        return setupResult
    }
    
    private func login(completion: @escaping ((Bool, String) -> Void)) {
        guard !self.isLoggedIn() else {
            completion(false, "Already logged in")
            return
        }
        
        SumUpSDK.presentLogin(from: topController(), animated: true)
        { loggedIn, err in
            if !loggedIn {
                completion(loggedIn, err != nil ? err.debugDescription : "Login dialog closed")
            } else {
                completion(loggedIn, "Login successful")
            }
        }
    }

    private func loginWithToken(token: String, completion: @escaping ((Bool, String) -> Void)) {
        guard !self.isLoggedIn() else {
            completion(false, "Already logged in")
            return
        }
        
        SumUpSDK.login(withToken: token)
        { loggedIn, err in
            if !loggedIn {
                completion(loggedIn, err != nil ? err.debugDescription : "Token login failed")
            } else {
                completion(loggedIn, "Login successful")
            }
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
        SumUpSDK.presentCheckoutPreferences(from: topController(), animated: true)
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

    private func prepareForCheckout() {
        SumUpSDK.prepareForCheckout()
    }
    
    private func checkout(request: CheckoutRequest, completion: @escaping ((CheckoutResult) -> Void)) {
        SumUpSDK.checkout(with: request, from: topController())
        { (result: CheckoutResult?, _: Error?) in
            if result != nil {
                completion(result!)
            } else {
                completion(CheckoutResult())
            }
        }
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
        SumUpSDK.logout
        { (_: Bool, error: Error?) in
            guard (error as NSError?) != nil else {
                return completion(true)
            }
            
            return completion(false)
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
