//
//  TripData.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import Foundation
import MapKit
import EventKit

struct Trip {
    var title: String?
    var subTitle: String?
    var place: String?
    var startDate: Date?
    var endDate: Date?
    var tagColor: String?
    var placeList = [EKEvent]()
    
    init(title: String? = nil, subTitle: String? = nil, place: String? = nil, startDate: Date? = nil, endDate: Date? = nil, tagColor: String? = nil, placeList: [EKEvent] = [EKEvent]()) {
        self.title = title
        self.subTitle = subTitle
        self.place = place
        self.startDate = startDate
        self.endDate = endDate
        self.tagColor = tagColor
        self.placeList = placeList
    }
    
//    init(title: String? = nil, subTitle: String? = nil, place: CLLocation? = nil, startDate: Date? = nil, endDate: Date? = nil) {
//        self.title = title
//        self.subTitle = subTitle
//        self.place = place
//        self.startDate = startDate
//        self.endDate = endDate
//    }
}

struct Place {
    var schedule = String()
    var placeTitle = String()
    var placeSubTitle = String()
    var tagColor = String()
    
    var startDate = Date()
    var endDate = Date()
    
    var url = String()
    var notes = String()
    
    var latitude = CLLocationDegrees()
    var longtitude = CLLocationDegrees()
    
    init(schedule: String = String(), placeTitle: String = String(), placeSubTitle: String = String(), tagColor: String = String(), startDate: Date = Date(), endDate: Date = Date(), url: String = String(), notes: String = String(), latitude: CLLocationDegrees = CLLocationDegrees(), longtitude: CLLocationDegrees = CLLocationDegrees()) {
        self.schedule = schedule
        self.placeTitle = placeTitle
        self.placeSubTitle = placeSubTitle
        self.tagColor = tagColor
        self.startDate = startDate
        self.endDate = endDate
        self.url = url
        self.notes = notes
        self.latitude = latitude
        self.longtitude = longtitude
    }

}
