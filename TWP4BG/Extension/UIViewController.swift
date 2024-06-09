//
//  UIViewController.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/09/01.
//

import Foundation
import UIKit
import RealmSwift

extension UIViewController {
    
    func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 3.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func alert(title: String, message: String, actionTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
    
    func alertPlusAction(title: String, message: String, actionTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default) { UIAlertAction in
            self.dismiss(animated: true)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
    
    func actionSheet(title: String, message: String, actionTitle1: String, actionTitle2: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let redColor = UIColor.red
        let action1 = UIAlertAction(title: actionTitle1, style: .default) { UIAlertAction in
            self.dismiss(animated: true)
        }
        action1.setValue(redColor, forKey: "titleTextColor")
        
        let action2 = UIAlertAction(title: actionTitle2, style: .cancel) { UIAlertAction in
            
        }
        alertController.addAction(action2)
        alertController.addAction(action1)
        self.present(alertController, animated: true)
    }
    
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


extension NSObject {
    
    func colorSelection(_ color: Int) -> String {
        switch color {
        case 0:
            //UIColor(hex: "F44747")!
            return "CAFFFF" //민트
        case 1:
            //UIColor(hex: "FA9F34")!
            return "4E2D3C" // 카카오
        case 2:
            //UIColor(hex: "CBCE2E")!
            return "005454" // 청록
        case 3:
            //UIColor(hex: "61DC42")!
            return "FE7601" // 오렌지
        case 4:
            //UIColor(hex: "339DEA")!
            return "FFD7FE" //연분홍
        case 5:
            //UIColor(hex: "4858E4")!
            return "0B0B69" // 데님
        case 6:
            //UIColor(hex: "CE37D1")!
            return "B099CD" //연보라
        case 7:
            //UIColor(hex: "CE37D1")!
            return "F9BF95" //살구
        case 8:
            //UIColor(hex: "CE37D1")!
            return "BF3E3D" // 벽돌
        case 9:
            //UIColor(hex: "CE37D1")!
            return "CBDCFC" // 아이스
            
        default:
            //UIColor(hex: "E3582D")!
            return "E3582D"
        }
    }
    
    func returnColor(_ text: String) -> Int {
        let components = text.components(separatedBy: " ")
        if components.count == 2 {
            let string0 = components[0]
            //print("string0: \(string0)") // 8/1
            let string1 = components[1]
            //print("string1: \(string1)") // (화)
            
            let components = string0.components(separatedBy: "/")
            if components.count == 2 {
                let string2 = components[0] // 날짜 중 '월'
                //print("string2: \(string2)") // 8
                let string3 = components[1] // 날짜 중 '일'
                //print("string3: \(string3)") // 1
                
                if let month = Int(string2), let day = Int(string3) {
                    let color = day % 9
                    //print("color: \(color)")
                    return color
                }
            }
        }
        return -1
    }
    
    func callFirebaseCloudFunction(transactionId: String) {
        // Firebase Cloud Function 엔드포인트 URL
        //let functionUrl = URL(string: "https://us-central1-trip-sketcher.cloudfunctions.net/requstAppleapi")!
        
        let functionUrl = URL(string: "https://us-central1-trip-sketcher.cloudfunctions.net/requstAppleapi?transactionId=\(transactionId)")!
        
        var request = URLRequest(url: functionUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }
            //print("error:", error)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            let statusCode = httpResponse.statusCode
            //print("Status Code:", statusCode)
            
            switch statusCode {
            case 200:
                // 성공한 경우의 처리
                if let data = data {
                    // 데이터를 사용하여 작업 수행
                    self.realmDataStore(data: data)
                    self.loadIAPData() {
                        print("iapDatas: ", iapDatas)
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("RestoreProcessIsDone"), object: nil)
                            NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
                            NotificationCenter.default.post(name: Notification.Name("titleConfigure"), object: nil)
                            NotificationCenter.default.post(name: Notification.Name("loadIAPDataForCheck"), object: nil)
                        }
                        print("self.loadIAPDat 종료")
                    }
                }
            case 400:
                // 400 Bad Request의 처리
                print("Bad Request")
            case 401:
                // 401 Unauthorized의 처리
                print("Unauthorized")
            case 404:
                // 404 Not Found의 처리
                print("Not Found")
            case 429:
                // 429 Too Many Requests의 처리
                print("Too Many Requests")
            case 500:
                // 500 Internal Server Error의 처리
                print("Internal Server Error")
            default:
                print("Unknown Status Code")
            }
            
        }
        
        task.resume()
    }
    
    func jwsDecode(jwtToken jwt: String) -> [String: Any] {
        
        func base64UrlDecode(_ value: String) -> Data? {
            var base64 = value
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
            let requiredLength = 4 * ceil(length / 4.0)
            let paddingLength = requiredLength - length
            if paddingLength > 0 {
                let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
                base64 = base64 + padding
            }
            return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
        }
        
        func decodeJWTPart(_ value: String) -> [String: Any]? {
            guard let bodyData = base64UrlDecode(value),
                  let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
                return nil
            }
            
            return payload
        }
        
        let segments = jwt.components(separatedBy: ".")
        //print("decodeJWTPart(segments[1]) ?? [:]: \(decodeJWTPart(segments[1]) ?? [:])")
        return decodeJWTPart(segments[1]) ?? [:]
    }
    
    func realmDataStore(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let jwtData: [String: Any] = self.jwsDecode(jwtToken: jsonString)
                //print("jwtData: \(jwtData)")
                
                let transactionId = jwtData["transactionId"] as? String
                let type = jwtData["type"] as? String
                let webOrderLineItemId = jwtData["webOrderLineItemId"] as? String
                let storefront = jwtData["storefront"] as? String
                
                let rawOriginalPurchaseDate = (jwtData["originalPurchaseDate"] as? Double ?? 0) / 1000
                let originalPurchaseDate = Date(timeIntervalSince1970: rawOriginalPurchaseDate)
                let originalTransactionId = jwtData["originalTransactionId"] as? String //pk
                let productId = jwtData["productId"] as? String
                
                let rawExpiresDate = (jwtData["expiresDate"] as? Double ?? 0) / 1000
                let expiresDate = Date(timeIntervalSince1970: rawExpiresDate)
                
                let rawPurchaseDate = (jwtData["purchaseDate"] as? Double ?? 0) / 1000
                let purchaseDate = Date(timeIntervalSince1970: rawPurchaseDate)
                
                let environment = jwtData["environment"] as? String
                let quantity = jwtData["quantity"] as? Int ?? 0
                
                let rawSignedDate = (jwtData["signedDate"] as? Double ?? 0) / 1000
                let signedDate = Date(timeIntervalSince1970: rawSignedDate)
                let storefrontId = jwtData["storefrontId"] as? String
                let subscriptionGroupIdentifier = jwtData["subscriptionGroupIdentifier"] as? String
                let bundleId = jwtData["bundleId"] as? String
                let inAppOwnershipType = jwtData["inAppOwnershipType"] as? String
                let transactionReason = jwtData["transactionReason"] as? String
                
                // IAPData 객체 생성
                let iapData = IAPData(
                    transactionId: transactionId,
                    originalTransactionId: originalTransactionId,
                    type: type,
                    webOrderLineItemId: webOrderLineItemId,
                    storefront: storefront,
                    originalPurchaseDate: originalPurchaseDate,
                    productId: productId,
                    expiresDate: expiresDate,
                    purchaseDate: purchaseDate,
                    environment: environment,
                    quantity: quantity,
                    signedDate: signedDate,
                    storefrontId: storefrontId,
                    subscriptionGroupIdentifier: subscriptionGroupIdentifier,
                    bundleId: bundleId,
                    inAppOwnershipType: inAppOwnershipType,
                    transactionReason: transactionReason
                )
                
                
                
                let realm = try! Realm()
//                do {
//                    try realm.write {
//                        //                        if realm.object(ofType: IAPData.self, forPrimaryKey: jwtData["transactionId"] as? String) != nil {
//                        //                            // 이미 존재하는 경우, 업데이트 시도
//                        //                            print("이미 존재하는 경우, 업데이트 시도")
//                        //                            //realm.add(iapData, update: .modified)
//                        //                            realm.add(iapData)
//                        if realm.object(ofType: IAPData.self, forPrimaryKey: iapData.originalTransactionId) == nil {
//                            print("primary key인 originalTransactionId로 검색해서 없을 때만 저장")
//                            realm.add(iapData)
//                            
//                        } else {
//                            // 존재하지 않는 경우, 새로 추가
//                            print("존재하지 않는 경우, 새로 추가")
//                            realm.add(iapData, update: .modified)
//                        }
//                        //realm.add(iapData)
//                        //print("IAPData.self: ", IAPData.self)
//                    }
//                    
//                } catch {
//                    // 오류 처리
//                }
                do {
                    let existingData = realm.objects(IAPData.self).filter("expiresDate = %@ OR type = 'Non-Consumable'", iapData.expiresDate)

                    if existingData.isEmpty {
                        try realm.write {
                            // 조건에 맞는 기존 데이터가 없을 때만 저장
                            realm.add(iapData)
                        }
                        print("iapData: ", iapData)
                    } else {
                        print("Data with matching expiresDate or type already exists, skipping save.")
                    }
                } catch {
                    // 오류 처리
                    print("Error saving data:", error)
                }

            }
            
        } catch {
            print("Error decoding JSON:", error)
        }
    }
}

// UIImage 확장(extension)을 사용하여 이미지 크기 조정하는 함수
extension UIImage {
    
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func imageWithLayer(layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContext(layer.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
}

extension TripViewController {
    func transfromToImage() -> UIImage? {
        //UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        UIGraphicsBeginImageContextWithOptions(tripCollectionView.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            tripCollectionView.layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
}

extension String {
    
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    //    func localized(with argument: CVarArg = [], comment: String = "") -> String {
    //        return String(format: self.localized(comment: comment), argument)
    //    }
    func localized(with arguments: [CVarArg] = [], comment: String = "") -> String {
        return String(format: self.localized(comment: comment), arguments)
    }
}

extension UIColor {
    
    func hexColorExtract(tintColor: UIImageView) -> String {
        
        let backgroundColor = tintColor.tintColor
        // Convert the UIColor object to its RGB components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        backgroundColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Format the RGB components as a hexadecimal string
        let hexColor = String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        return hexColor // UIColor(hex: ) // String으로 출력됨
    }
    
    convenience init?(hex: String) {
        //let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let red, green, blue: CGFloat
        switch hex.count {
        case 6:
            red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        case 8:
            red = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        default:
            return nil
        }
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format:"%06X", rgb)
    }
}
