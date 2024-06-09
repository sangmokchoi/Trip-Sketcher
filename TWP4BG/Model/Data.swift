//
//  Data.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/28.
//

import RealmSwift
import Foundation
import EventKit
import UIKit

var tripList: [TripList] = []
var tripForExpense: [TripForExpense] = []
var iapDatas: [IAPData] = []

var currencyTitle: String = "Recent Currency".localized()

class TripList: Object {
    @Persisted(primaryKey: true) var title: String? // pk
    @Persisted var subTitle: String?
    @Persisted var place: String?
    @Persisted var startDate: Date?
    @Persisted var endDate: Date?
    @Persisted var tagColor: String?
    //@Persisted var placeList: EKEvent?
    convenience init(title: String? = nil, subTitle: String? = nil, place: String? = nil, startDate: Date? = nil, endDate: Date? = nil, tagColor: String? = nil) {
        self.init()
        self.title = title
        self.subTitle = subTitle
        self.place = place
        self.startDate = startDate
        self.endDate = endDate
        self.tagColor = tagColor
    }
}

class TripForExpense: Object {
    @Persisted(primaryKey: true) var scheduleUID: String? // pk, event.eventIdentifier
    @Persisted var tripsStartDate: Date?
    @Persisted var tripEndDate: Date?
    @Persisted var money: Double?
    @Persisted var currecncy: String?
    
    convenience init(scheduleUID: String? = nil, tripsStartDate: Date? = nil, tripEndDate: Date? = nil, money: Double? = nil, currecncy: String? = nil) {
        self.init()
        self.scheduleUID = scheduleUID
        self.tripsStartDate = tripsStartDate
        self.tripEndDate = tripEndDate
        self.money = money
        self.currecncy = currecncy
    }

}

class IAPData: Object { // 구매시의 datatype들과 restored 시의 datatype이 모두 합쳐진 상태
    @Persisted(primaryKey: true) var transactionId: String?
    @Persisted var originalTransactionId: String?
    @Persisted var type: String? // Auto-Renewable Subscription
    @Persisted var webOrderLineItemId: String? // 구독 전용 datatype
    @Persisted var storefront: String? // KOR
    @Persisted var originalPurchaseDate: Date?
    @Persisted var productId: String?
    @Persisted var expiresDate: Date?  // 구독 전용 datatype
    @Persisted var purchaseDate: Date?
    @Persisted var environment: String? // Sandbox
    @Persisted var quantity: Int = 0
    @Persisted var signedDate: Date?
    @Persisted var storefrontId: String?
    @Persisted var subscriptionGroupIdentifier: String?
    @Persisted var bundleId: String?
    @Persisted var inAppOwnershipType: String? // PURCHASED  // 구독 전용 datatype
    @Persisted var transactionReason: String? // RENEWAL
    
    convenience init(transactionId: String? = nil, originalTransactionId: String? = nil, type: String? = nil, webOrderLineItemId: String? = nil, storefront: String? = nil, originalPurchaseDate: Date? = nil, productId: String? = nil, expiresDate: Date? = nil, purchaseDate: Date? = nil, environment: String? = nil, quantity: Int, signedDate: Date? = nil, storefrontId: String? = nil, subscriptionGroupIdentifier: String? = nil, bundleId: String? = nil, inAppOwnershipType: String? = nil, transactionReason: String? = nil) {
        self.init()
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.type = type
        self.webOrderLineItemId = webOrderLineItemId
        self.storefront = storefront
        self.originalPurchaseDate = originalPurchaseDate
        self.productId = productId
        self.expiresDate = expiresDate
        self.purchaseDate = purchaseDate
        self.environment = environment
        self.quantity = quantity
        self.signedDate = signedDate
        self.storefrontId = storefrontId
        self.subscriptionGroupIdentifier = subscriptionGroupIdentifier
        self.bundleId = bundleId
        self.inAppOwnershipType = inAppOwnershipType
        self.transactionReason = transactionReason
    }
}

extension NSObject {
    
    // 2023-08-01 형식의 날짜 문자열을 Date로 변환하는 함수
    func dateFromFormattedString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }
    
    func loadTripList(completion: @escaping() -> Void) { // tripList에 realm 데이터를 불러와서 저장
        let realm = try! Realm()
        let realmTripList = realm.objects(TripList.self)
        tripList = Array(realmTripList)
        completion()
    }
    
    
    func loadTripForExpense(completion: @escaping() -> Void) { // tripList에 realm 데이터를 불러와서 저장
        let realm = try! Realm()
        let realmTripForExpense = realm.objects(TripForExpense.self)
        tripForExpense = Array(realmTripForExpense)
        completion()
    }
    
    func loadIAPData(completion: @escaping() -> Void) { // tripList에 realm 데이터를 불러와서 저장
        let realm = try! Realm()
        let realmIAPData = realm.objects(IAPData.self)
        iapDatas = Array(realmIAPData)
        completion()
    }
    
    func totalMoneyForSchedule(scheduleUID: String) -> [TripForExpense] {
        let realm = try! Realm()
        let expensesWithCurrency = realm.objects(TripForExpense.self).filter("scheduleUID = %@", scheduleUID)
        
        return Array(expensesWithCurrency)
    }

    
}
