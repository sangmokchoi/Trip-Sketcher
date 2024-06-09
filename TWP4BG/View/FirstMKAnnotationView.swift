//
//  FirstMKAnnotationView.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/17.
//

import UIKit
import MapKit
import EventKit

class FirstMKAnnotationView: MKAnnotationView {
    
    static let identifier = "FirstMKAnnotationView"
    
    var numberlabel: UILabel!
    var titelLabel: UILabel!
    var locationLabel: UILabel!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.image = UIImage(systemName: "circle")
        self.tintColor = UIColor(hex: "E3582D")
        
        numberlabel = UILabel(frame: CGRect(
            x: self.frame.width/4,
            y: self.frame.height/4,
            width: self.frame.width,
            height: 20))
        numberlabel.textColor = .white
        numberlabel.textAlignment = .center
        numberlabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        
        numberlabel.layer.shadowColor = UIColor.black.cgColor // 그림자의 색상
        numberlabel.layer.shadowOpacity = 0.5 // 그림자의 불투명도
        numberlabel.layer.shadowOffset = CGSize(width: 0, height: 2) // 그림자의 오프셋
        numberlabel.layer.shadowRadius = 4 // 그림자의 블러 반경
        
        self.addSubview(numberlabel)
        
        titelLabel = UILabel(frame: CGRect(
            x: -(self.frame.width + 70)/2 + 15,
            y: self.bounds.midY + 20,
            width: self.frame.width + 70,
            height: 30))
        titelLabel.textColor = .black
        titelLabel.textAlignment = .center
        titelLabel.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        titelLabel.layer.borderWidth = 1
        titelLabel.layer.cornerRadius = 10
        titelLabel.layer.masksToBounds = true

        titelLabel.numberOfLines = 2
        titelLabel.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
       
        //self.addSubview(titelLabel)
        
        locationLabel = UILabel(frame: CGRect(
            x: -(self.frame.width + 70)/2 + 15,
            y: self.bounds.midY + 20,
            width: self.frame.width + 70,
            height: 30))
//        locationLabel = UILabel(frame: CGRect(
//            x: -(self.frame.width + 70)/2 + 15,
//            y: self.frame.height + titelLabel.frame.height + 10,
//            width: self.frame.width + 70,
//            height: 20))
        locationLabel.textColor = .black
        locationLabel.textAlignment = .center
        locationLabel.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        locationLabel.layer.cornerRadius = 10
        locationLabel.numberOfLines = 2
        locationLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        locationLabel.layer.masksToBounds = true
        
        locationLabel.layer.shadowColor = UIColor.black.cgColor // 그림자의 색상
        locationLabel.layer.shadowOpacity = 0.5 // 그림자의 불투명도
        locationLabel.layer.shadowOffset = CGSize(width: 0, height: 0) // 그림자의 오프셋 (위치 조정을 위해 height를 0으로 설정)
        locationLabel.layer.shadowRadius = 100 // 그림자의 블러 반경

        // 그림자의 경로를 설정하여 가장자리에 그림자를 만듦
        let shadowPath = UIBezierPath(rect: CGRect(x: -8, y: -8, width: locationLabel.bounds.width + 16, height: locationLabel.bounds.height + 16))
        locationLabel.layer.shadowPath = shadowPath.cgPath

        
        self.addSubview(locationLabel)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    override func draw(_ rect: CGRect) {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        //backgroundColor = .clear
    }
    
}

class CustomAnnotation: NSObject, MKAnnotation {
    let color: Int?
    let coordinate: CLLocationCoordinate2D
    let labelNumber: Int?
    let title: String?
    let location: String?
    let ekEvent: EKEvent?
    
//    init(image: Int?, coordinate: CLLocationCoordinate2D, labelNumber: Int?, title: String?, location: String?) {
//        self.image = image
//        self.coordinate = coordinate
//        self.labelNumber = labelNumber
//        self.title = title
//        self.location = location
//    }
    init(color: Int?, coordinate: CLLocationCoordinate2D, labelNumber: Int?, title: String?, location: String?, ekEvent: EKEvent?) {
        self.color = color
        self.coordinate = coordinate
        self.labelNumber = labelNumber
        self.title = title
        self.location = location
        self.ekEvent = ekEvent
    }
    
}
