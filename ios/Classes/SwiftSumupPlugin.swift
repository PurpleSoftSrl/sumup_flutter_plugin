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
        return UIApplication.shared.keyWindow!.rootViewController!
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let pluginResponse = SumupPluginResponse(methodName: call.method, status: true)
        
        switch call.method {
        case "initSDK":
            let initResult = initSDK(affiliateKey: call.arguments as! String)
            pluginResponse.message = ["result": initResult]
            result(pluginResponse.toDictionary())
            
        case "login":
            self.login { success in
                pluginResponse.message = ["result": success]
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
            
        case "checkout":
            let args = call.arguments as! [String: Any]
            let payment = args["payment"] as! [String: Any]
            
            let request = CheckoutRequest(total: NSDecimalNumber(floatLiteral: payment["total"] as! Double), title: payment["title"] as? String, currencyCode: payment["currency"] as! String, paymentOptions: [.cardReader, .mobilePayment])
            
            request.foreignTransactionID = payment["foreignTransactionId"] as? String
            request.tipAmount = NSDecimalNumber(floatLiteral: payment["tip"] as! Double)
            request.saleItemsCount = payment["saleItemsCount"] as! UInt
            
            if payment["skipSuccessScreen"] as! Bool == true {
                request.skipScreenOptions = SkipScreenOptions(rawValue: 1)
            } else {
                request.skipScreenOptions = SkipScreenOptions(rawValue: 0)
            }
            
            self.checkout(request: request)
            { (checkoutResult: CheckoutResult) in
                
                pluginResponse.message = ["success": checkoutResult.success,
                                          "transactionCode": checkoutResult.transactionCode ?? "",
                                          "amount": checkoutResult.additionalInfo?["amount"] ?? "",
                                          "currency": checkoutResult.additionalInfo?["currency"] ?? "",
                                          "vatAmount": checkoutResult.additionalInfo?["vat_amount"] ?? "",
                                          "tipAmount": checkoutResult.additionalInfo?["tip_amount"] ?? "",
                                          "paymentType": checkoutResult.additionalInfo?["payment_type"] ?? "",
                                          "entryMode": checkoutResult.additionalInfo?["entry_mode"] ?? "",
                                          "installments": checkoutResult.additionalInfo?["installments"] ?? "",
                                          "products": checkoutResult.additionalInfo?["products"] ?? ""]
                
                let resultCard = checkoutResult.additionalInfo?["card"] as? [String: Any?]
                
                if resultCard != nil {
                    let cardType = resultCard!["type"]
                    let cardLastDigits = resultCard!["last_4_digits"]
                    
                    if cardType != nil {
                        pluginResponse.message["cardType"] = cardType!
                    }
                    
                    if cardLastDigits != nil {
                        pluginResponse.message["cardLastDigits"] = cardType!
                    }
                }
             
                result(pluginResponse.toDictionary())
            }
               
        case "isCheckoutInProgress":
            let isInProgress = self.isCheckoutInProgress()
            pluginResponse.message = ["result": isInProgress]
            pluginResponse.status = isInProgress
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
    
    private func login(completion: @escaping ((Bool) -> Void)) {
        SumUpSDK.presentLogin(from: topController(), animated: true)
        { loggedIn, _ in
            completion(loggedIn)
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
