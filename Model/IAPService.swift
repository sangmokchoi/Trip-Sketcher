//
//  IAPService.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/09/03.
//

import Foundation
import StoreKit
import CryptoKit
import FirebaseFunctions

typealias ProductsRequestCompletion = (_ success: Bool, _ products: [SKProduct]?) -> Void

protocol IAPServiceType {
    var canMakePayments: Bool { get }
    
    func getProducts(completion: @escaping ProductsRequestCompletion)
    func buyProduct(_ product: SKProduct)
    func isProductPurchased(_ productID: String) -> Bool
    func restorePurchases(completion: @escaping() -> Void)
    func getReceiptData() -> String?
}

//외부에서 필요한 메소드를 명시하기 위해서 protocol 정의
//products 항목 가져오기 (getProducts)
//product 구입하기 (buyProduct)
//구입했는지 확인하기 (isProductPurchased)
//구입한 목록 조회 (restorePurchased)

final class IAPService: NSObject, IAPServiceType {
    
    private let productIDs: Set<String>
    private var purchasedProductIDs: Set<String> = []
    private var productsRequest: SKProductsRequest?
    private var productsCompletion: ProductsRequestCompletion?
    var purchased = [SKPaymentTransaction]();
    //StoreKit을 사용하려면 NSObject를 상속받고 IAPServiceType을 준수
    //추가로 필요한 프로퍼티 선언
    //productIDs: 앱스토어에서 입력한 productID들 "com.jake.sample.ExInAppPurchase.shopping"
    //purchasedProductIDs: 구매한 productID
    //productsRequest: 앱스토어에 입력한 productID로 부가 정보 조회할때 사용하는 인스턴스
    //proeductsCompletion: 사용하는쪽에서 해당 클로저를 통해 실패 or 성공했을때 값을 넘겨줄 수 있는 프로퍼티 (델리게이트)
    
    var canMakePayments: Bool {
        print("canMakePayments 진입")
        return SKPaymentQueue.canMakePayments()
    }
    
    init(productIDs: Set<String>) {
        self.productIDs = productIDs
        self.purchasedProductIDs = productIDs
            .filter { UserDefaults.standard.bool(forKey: $0) == true } // 구매 여부를 UserDefaults에 저장해두고 IAPService에서 ProductIDs를 받아올 때 초기화하여 사용
        
        super.init()
        SKPaymentQueue.default().add(self) // IAPService에 SKPaymentQueue를 연결
        print("IAPService에 SKPaymentQueue를 연결")
    }
    //상품 정보를 받아서 초기화
    //앱스토어에서 입력한 productID들 "com.jake.sample.ExInAppPurchase.shopping"
    func getProducts(completion: @escaping ProductsRequestCompletion) {
        print("getProducts 진입")
        self.productsRequest?.cancel()
        self.productsCompletion = completion
        print("self.productIDs : \(self.productIDs)")
        self.productsRequest = SKProductsRequest(productIdentifiers: self.productIDs)
        self.productsRequest!.delegate = self
        self.productsRequest!.start()
    }
    
    func buyProduct(_ product: SKProduct) {
        print("buyProduct 진입")
        NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsStart"), object: nil)
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func isProductPurchased(_ productID: String) -> Bool {
        print("isProductPurchased 진입")
        return self.purchasedProductIDs.contains(productID)
    }
    
    func restorePurchases(completion: @escaping() -> Void) {
        print("restorePurchases 진입")
        for productID in productIDs {
            UserDefaults.standard.set(false, forKey: productID)
            print("productID: \(productID)")

        }
        
        let paymentQueue = SKPaymentQueue.default()
        // 사용자의 구매 내역을 가져옵니다.
        paymentQueue.restoreCompletedTransactions()
        
        completion()
    }

    
}

extension IAPService: SKProductsRequestDelegate { // SKPaymentQueue에서 처리되는 일들
    // didReceive
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("productsRequest 진입")
        NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsStart"), object: nil)
        //restorePurchases()
        let products = response.products
        self.productsCompletion?(true, products)
        self.clearRequestAndHandler()
        
        products.forEach { print("Found product: \($0.productIdentifier), \($0.localizedTitle), \($0.price.floatValue)\n") }
    }
    
    // failed
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request 진입")
        print("Erorr: \(error.localizedDescription)")
        self.productsCompletion?(false, nil)
        self.clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        print("clearRequestAndHandler 진입")
        self.productsRequest = nil
        self.productsCompletion = nil
    }
}

extension IAPService: SKPaymentTransactionObserver {
    

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue 진입")
        
        transactions.forEach {
            switch $0.transactionState {
            case .purchased:
                // 사용자에게 구매가 완료되었음을 알리고, 상품을 제공하거나 기타 후속 작업을 수행할 수 있습니다.
                print("completed transaction")
                self.deliverPurchaseNotificationFor(id: $0.payment.productIdentifier)
      
                let transactionIdentifier = $0.transactionIdentifier!
  
                callFirebaseCloudFunction(transactionId: transactionIdentifier)
                
                SKPaymentQueue.default().finishTransaction($0)
                
                //NotificationCenter.default.post(name: Notification.Name("purchased"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
              
            case .failed:
                print("failed")

                NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)

                if let transactionError = $0.error as NSError?,
                   let description = $0.error?.localizedDescription,
                   transactionError.code != SKError.paymentCancelled.rawValue {
                    print("Transaction erorr: \(description)")


                }
                SKPaymentQueue.default().finishTransaction($0)
                
                NotificationCenter.default.post(name: Notification.Name("failed"), object: nil)
                break

            case .restored:
                // restore된 경우(구매 완료된 것 다시 조회) 구매했던 목록으로 추가 (UserDefaults)
                // 결제 검증을 했습니다.
                print("restored transaction")
                if let originalTransactionIdentifier = $0.transactionIdentifier {
                    callFirebaseCloudFunction(transactionId: originalTransactionIdentifier)
                }
                NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("titleConfigure"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("RestoreProcessIsDone"), object: nil)
                
                SKPaymentQueue.default().finishTransaction($0)
                break
            case .deferred:
                // 결제 창을 띄우는데 실패했습니다
                print("deferred")
                
                NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("failed"), object: nil)

                SKPaymentQueue.default().finishTransaction($0)
                break
            case .purchasing:
                print("purchasing")
                
                NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsStart"), object: nil)
    
            default:
                print("unknown")
            }
        }
    }
    
    private func deliverPurchaseNotificationFor(id: String?) {
        
        print("deliverPurchaseNotificationFor 진입")

        if let id = id {
            
            self.purchasedProductIDs.insert(id)
            print("purchasedProductIDs: \(self.purchasedProductIDs)")
            
            UserDefaults.standard.set(true, forKey: id)
            // 성공 노티 전송
            NotificationCenter.default.post(
                name: .iapServicePurchaseNotification,
                object: id
            )
            
        } else { // 실패 노티 전송
            NotificationCenter.default.post( // <- 추가
                name: .iapServicePurchaseNotification,
                object: ""
            )
        }
    }
    
    func getReceiptData() -> String? {
        print("getReceiptData 진입")
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                print("appStoreReceiptURL: \(appStoreReceiptURL)")
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print("receiptData: \(receiptData)")
                let receiptString = receiptData.base64EncodedString(options: [])
                //print("receiptString: \(receiptString)")

                return receiptString
                
            }
            catch {
                print("Couldn`t read receipt data with error: " + error.localizedDescription)
                return nil
            }
        }
        print("return nil")
        return nil
    }

    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("restoreCompletedTransactionsFailedWithError : \(error)")
        NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
        clearRequestAndHandler()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("paymentQueueRestoreCompletedTransactionsFinished 진입")
        NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
        clearRequestAndHandler()
        SKPaymentQueue.default().remove(self)
    }

    
}

extension IAPService {
    
    func presentAlert(on viewController: UIViewController, withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "확인", style: .default)
        alertController.addAction(action1)
        viewController.present(alertController, animated: true)
    }
    
}

extension Notification.Name {
    static let iapServicePurchaseNotification = Notification.Name("IAPServicePurchaseNotification")
}

enum MyProducts {
    static let productID1 = "com.simonwork.TWP4BG.SubScription"
    static let productID2 = "com.simonwork.TWP4BG.NonConsumable"
    
    static let iapService: IAPServiceType = IAPService(productIDs: Set<String>([productID1, productID2]))
    
    static func getResourceProductName(_ id: String) -> String? {
        id.components(separatedBy: ".").last
    }
}
