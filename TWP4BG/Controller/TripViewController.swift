//
//  TripViewController.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import UIKit
import EventKit
import EventKitUI
import MapKit
import MessageUI
import Photos
import Contacts

struct Section {
    let startdate: Date
    var events: [EKEvent]
}

let eventStore = EKEventStore()

class TripViewController: UIViewController {
    
    private var isPermissionDenied = false
    private var imageSavedHandler: (() -> Void)?
    private var viewController: UIViewController?
        
    var index: Int?
    var tripTitle: String?
    var tripPlace: String?
    var tripStartDate: Date?
    var tripEndDate: Date?
    var tripTagColor: String?
    
    var isViewDidLoad: Bool?
    var isAnnotationClicked: Bool?
    var dateCollectionViewIndex: Int?
    var indexRow: Int = 0
    var startIndex = 0
    var filteredEventsIndex = 0
    var isfilteredEventUsable: Bool?
    
    private var timeInterval : [String] = []
    var events: [EKEvent] = [] // fetch한 모든 EKEvent가 저장된 어레이
    var filteredEvents: [EKEvent] = [] // fetch한 EKEvent 중에서 dateCollectionView의 클릭된 날짜와 startDate가 동일한 EKEvent만 담기는 어레이
    var eventCountsByDate: [String: Int] = [:] // 각 날짜별 이벤트 개수를 저장할 딕셔너리
    var clickedCellTitle = "All"
    var sectionedEvents: [String: [EKEvent]] = [:]
    
    var keysArray: [String] = []
    var valuesArray: [Int] = []
    
    var locationManager: CLLocationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    var multiSelection: [IndexPath] = []
    var isDollarSignEnable: Bool = false
    
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var tripCollectionView: UICollectionView!
    
    var isMapVisible = true
    var mapContainerView: UIView!
    let mapView = MKMapView()
    var transportType: Int = 0
    var expectedTravelTime: Double = 0.0
    var labelNumber = 1
    let transportationGuide = "Public transportation provides only ETT rather than detailed routes".localized()
    let appleMapGuide = "The ETT is calculated using Apple Maps' route search feature".localized()
    
    lazy var deSelectButton: UIBarButtonItem = {
        let deSelectButton = UIBarButtonItem(title: "Back".localized(), style: .plain, target: self, action: #selector(deSelectButtonPressed(_:)))
        deSelectButton.tintColor = UIColor(named: "reversed Color")
        
        return deSelectButton
    }()
    
    @objc internal func deSelectButtonPressed(_ sender: UIButton) {
        tripCollectionView.isEditing = false
        tripCollectionView.allowsMultipleSelection = false
        tripCollectionView.allowsSelectionDuringEditing = false
        tripCollectionView.allowsMultipleSelectionDuringEditing = false
        multiSelection.removeAll()
        navigationItem.rightBarButtonItems = nil
        
        dateCollectionView.isUserInteractionEnabled = true
        
        barItemConfigure()
        
        tripCollectionView.reloadData()
    }
    
    lazy var deleteButton: UIBarButtonItem = {
        let deleteButton = UIBarButtonItem(title: "Delete".localized(), style: .done, target: self, action: #selector(deleteButtonPressed(_:)))
        deleteButton.tintColor = .systemRed
        
        return deleteButton
    }()
    
    @objc internal func deleteButtonPressed(_ sender: UIButton) {
        if !multiSelection.isEmpty {
            deleteSelectedEvents()
            
            tripCollectionView.isEditing = false
            tripCollectionView.allowsMultipleSelection = false
            tripCollectionView.allowsSelectionDuringEditing = false
            tripCollectionView.allowsMultipleSelectionDuringEditing = false
            multiSelection.removeAll()
            
            dateCollectionView.isUserInteractionEnabled = true
            
            navigationItem.rightBarButtonItems = [deleteButton, deSelectButton]
            
            
            DispatchQueue.main.async {
                self.configure()
                self.tripCollectionView.isEditing = false
                self.tripCollectionView.allowsMultipleSelection = false
                self.tripCollectionView.allowsSelectionDuringEditing = false
                self.tripCollectionView.allowsMultipleSelectionDuringEditing = false
                self.multiSelection.removeAll()
                self.navigationItem.rightBarButtonItems = nil
                
                self.dateCollectionView.isUserInteractionEnabled = true
                
                self.barItemConfigure()
            }
        } else {
            alert(title: "There are no schedules to delete".localized(), message: "Select the schedule you want to delete".localized(), actionTitle: "OK".localized())
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tripToEntryWithIndex" {
            print("if segue.identifier == tripToEntryWithIndex")
            let nextVc = segue.destination as! EntryViewController
            
            nextVc.index = index
            nextVc.tripPlaceList = events
            
            
        }
    }
    
    lazy var settingButton: UIButton = {
        
        let share = UIAction(title: "Export Schedule".localized(), image: UIImage(systemName: "square.and.arrow.up"), handler: { _ in
            
            DispatchQueue.main.async {
                self.shareButtonPressed()
            }
        })
        
        let update = UIAction(title: "Select Schedule".localized(), image: UIImage(systemName: "check"), handler: { _ in
            
            self.tripCollectionView.isEditing = true
            self.tripCollectionView.allowsMultipleSelection = true
            self.tripCollectionView.allowsSelectionDuringEditing = true
            self.tripCollectionView.allowsMultipleSelectionDuringEditing = true
            self.navigationItem.rightBarButtonItems = [self.deleteButton, self.deSelectButton]
            
            self.dateCollectionView.isUserInteractionEnabled = false
            
            self.tripCollectionView.reloadData()
        })
        
        let delete = UIAction(title: "Delete All Schedules".localized(), image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in
            
            let alertController = UIAlertController(title: "Do you want to delete all schedules?".localized(), message: "Press Delete button to delete all schedules".localized(), preferredStyle: .alert)
            let action1 = UIAlertAction(title: "Delete".localized(), style: .destructive) { _ in
                
                self.deleteAllItems()
                
                DispatchQueue.main.async {
                    self.configure()
                }
            }
            let action2 = UIAlertAction(title: "Cancel".localized(), style: .default)
            alertController.addAction(action1)
            alertController.addAction(action2)
            self.present(alertController, animated: true)
            
        })
        
        let settingButton = UIButton(type: .system)
        settingButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        settingButton.tintColor = UIColor(named: "reversed Color")
        
        let menu = UIMenu(title: "Setting", children: [share, update, delete])
        settingButton.menu = menu
        settingButton.showsMenuAsPrimaryAction = true
        return settingButton
    }()
    
    func selectAllItems(completion: @escaping () -> Void) {
        for section in 0..<tripCollectionView.numberOfSections {
            for item in 0..<tripCollectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                tripCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                multiSelection.append(indexPath)
            }
        }
        completion()
    }
    
    @objc func deleteAllItems() {
        
        selectAllItems {
            self.deleteSelectedEvents()
            self.tripCollectionView.isEditing = false
            self.tripCollectionView.allowsMultipleSelection = false
            self.tripCollectionView.allowsSelectionDuringEditing = false
            self.tripCollectionView.allowsMultipleSelectionDuringEditing = false
            self.multiSelection.removeAll()
            
            self.dateCollectionView.isUserInteractionEnabled = true
            
        }
    }
    
    func deleteSelectedEvents() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d (E)"
        
        let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
            if let date1 = dateFormatter.date(from: dateString1),
               let date2 = dateFormatter.date(from: dateString2) {
                return date1 < date2
            }
            return false
        }
        
        let eventsToDelete = multiSelection.compactMap { indexPath in
            //print("indexPath: ", indexPath)
            //print("sectionedEvents[keysArray[indexPath.section]]?[indexPath.row]: ", sectionedEvents[sortedArray[indexPath.section]]?[indexPath.row])
            return sectionedEvents[sortedArray[indexPath.section]]?[indexPath.row]
        }
        
        //let eventStore = EKEventStore()
        for event in eventsToDelete {
            do {
                try eventStore.remove(event, span: .thisEvent)
                // 선택된 이벤트를 삭제한 후에 화면에서도 업데이트 등 필요한 작업 수행
                
            } catch {
                print("Error deleting event: \(error.localizedDescription)")
            }
        }
        
        // 선택된 셀 목록 초기화
        multiSelection.removeAll()
        // 삭제 완료 후 화면 업데이트
        tripCollectionView.reloadData()
    }
    
    
    lazy var addButton: UIButton = {
        let addButton = UIButton(type: .system)
        let originalImage = UIImage(systemName: "plus.circle")
        let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
        
        addButton.setImage(resizedImage, for: .normal)
        addButton.tintColor = UIColor(named: "reversed Color")
        addButton.addTarget(self, action: #selector(self.addTripList(_:)), for: .touchUpInside)
        
        return addButton
    }()
    
    @objc internal func addTripList(_ sender: UIButton) {

        requestAccessToEventStore("New Schedule".localized(), "Add a location".localized(), index: dateCollectionViewIndex)

    }
    
    lazy var mapButton: UIButton = {
        let mapButton = UIButton(type: .system)
        let originalImage = UIImage(systemName: "map.circle")
        let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
        
        //self.mapButton.image = resizedImage
        mapButton.setImage(resizedImage, for: .normal)
        mapButton.tintColor = UIColor(named: "reversed Color")
        mapButton.addTarget(self, action: #selector(self.showMap(_:)), for: .touchUpInside)
        
        return mapButton
    }()
    
    @objc internal func showMap(_ sender: UIButton) {
        
        self.isMapVisible.toggle()
        
        labelNumber = 0
        self.expectedTravelTime = 0
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor, constant: 0),
            mapView.heightAnchor.constraint(equalToConstant: mapContainerView.frame.height),
            mapView.widthAnchor.constraint(equalToConstant: mapContainerView.bounds.width)
        ])
        
        if !isMapVisible {
            self.mapContainerView.transform = CGAffineTransform(translationX: self.mapContainerView.bounds.maxX, y: self.mapContainerView.frame.height)
        }
        
        addRouteToMap(transportType: transportType)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.mapContainerView.isHidden = self.isMapVisible
            
            if self.isMapVisible {
                
                DispatchQueue.main.async {
                    
                    let originalImage = UIImage(systemName: "map.circle")
                    let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
                    
                    self.addButton.isUserInteractionEnabled = true
                    self.addButton.alpha = 1.0
                    self.calculateButton.isUserInteractionEnabled = true
                    self.calculateButton.alpha = 1.0
                    self.settingButton.isUserInteractionEnabled = true
                    self.settingButton.alpha = 1.0
                    //self.mapButton.image = resizedImage
                    self.mapButton.setImage(resizedImage, for: .normal)
                }
                
            } else {
                print("UIView.animate 화면 나타남")
                self.mapViewAnimation()
                self.mapContainerView.transform = CGAffineTransform(translationX: 0, y: 0) // 건들지 말기
                
                DispatchQueue.main.async {
                    
                    let originalImage = UIImage(systemName: "xmark.circle.fill")
                    let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
                    self.addButton.isUserInteractionEnabled = false
                    self.addButton.alpha = 0.5
                    self.calculateButton.isUserInteractionEnabled = false
                    self.calculateButton.alpha = 0.5
                    self.settingButton.isUserInteractionEnabled = false
                    self.settingButton.alpha = 0.5
                    //self.mapButton.image = resizedImage
                    self.mapButton.setImage(resizedImage, for: .normal)
                }
            }
            
            //            self.isMapVisible.toggle()
            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
    }
    
    lazy var calculateButton: UIButton = {
        let calculateButton = UIButton(type: .system)
        let originalImage = UIImage(systemName: "dollarsign.circle")
        let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
        
        //self.mapButton.image = resizedImage
        calculateButton.setImage(resizedImage, for: .normal)
        calculateButton.tintColor = UIColor(named: "reversed Color")
        calculateButton.addTarget(self, action: #selector(self.calculateButton(_:)), for: .touchUpInside)
        
        return calculateButton
    }()
    
    @objc internal func calculateButton(_ sender: UIButton) {
        
        tripCollectionView.isScrollEnabled = true
        self.isDollarSignEnable.toggle()
        
        updateVisibleCells()

        if !isDollarSignEnable {
            DispatchQueue.main.async {
                
                let originalImage = UIImage(systemName: "dollarsign.circle")
                let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
                self.calculateButton.setImage(resizedImage, for: .normal)
                
                if let navigationBar = self.navigationController?.navigationBar {
                    navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
                    navigationBar.tintColor = .blue
                }
                
                self.dateCollectionView.isUserInteractionEnabled = true
                self.dateCollectionView.alpha = 1.0
                self.addButton.isUserInteractionEnabled = true
                self.addButton.alpha = 1.0
                self.mapButton.isUserInteractionEnabled = true
                self.mapButton.alpha = 1.0
                self.settingButton.isUserInteractionEnabled = true
                self.settingButton.alpha = 1.0
                
                self.tripCollectionView.reloadData()
            }
        } else { // 유저가 비용계산기를 누른 상태 (달러 사인이 보여야 함)
            DispatchQueue.main.async {
                
                let originalImage = UIImage(systemName: "xmark.circle.fill")
                let resizedImage = originalImage?.withRenderingMode(.automatic).resized(to: CGSize(width: 30, height: 30))
                self.calculateButton.setImage(resizedImage, for: .normal)
                
                // 네비게이션 바 배경색을 그라데이션으로 설정
                if let navigationBar = self.navigationController?.navigationBar {
                    navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.clear]
                    navigationBar.tintColor = .blue
                }
                
                self.dateCollectionView.isUserInteractionEnabled = false
                self.dateCollectionView.alpha = 0.5
                self.addButton.isUserInteractionEnabled = false
                self.addButton.alpha = 0.5
                self.mapButton.isUserInteractionEnabled = false
                self.mapButton.alpha = 0.5
                self.settingButton.isUserInteractionEnabled = false
                self.settingButton.alpha = 0.5
                
                self.tripCollectionView.reloadData()
            }
        }
    }
    
    lazy var transitGuideLabel : UILabel = {
        let transitGuideLabel = UILabel(frame: CGRect(x: 10, y: 40, width: 180, height: 40))
        transitGuideLabel.text = transportationGuide.localized()
        transitGuideLabel.font = .systemFont(ofSize: 9, weight: .light)
        transitGuideLabel.textColor = .label
        transitGuideLabel.numberOfLines = 0
        transitGuideLabel.textAlignment = .left
        transitGuideLabel.contentMode = .topLeft
        transitGuideLabel.layer.cornerRadius = 5
        transitGuideLabel.layer.masksToBounds = true
        //transitGuideLabel.backgroundColor = .white.withAlphaComponent(0.1)

        return transitGuideLabel
    }()
    
    //.automobile .walking, .transit
    lazy var automobileButton: UIButton = {
        
        let width = 30
        let height = 30
        let automobileButton = UIButton(frame: CGRect(x: 15, y: 10, width: width, height: height))
        automobileButton.setImage(UIImage(systemName: "car"), for: .normal)
        automobileButton.layer.cornerRadius = CGFloat(width/2)
        automobileButton.tintColor = UIColor(named: "reversed Color")
        automobileButton.addTarget(self, action: #selector(self.automobileButton(_:)), for: .touchUpInside)
        return automobileButton
    }()
    
    @objc internal func automobileButton(_ sender: UIButton) {
        print("automobileButton")
        
        DispatchQueue.main.async { [self] in
            self.expectedTravelTime = 0
            transportType = 1
            if transportType == 1 {
                automobileButton.backgroundColor = .systemBackground
                transitButton.backgroundColor = .clear
                walkingButton.backgroundColor = .clear
                polyLineButton.backgroundColor = .clear
                transitGuideLabel.isHidden = true
            } else {
                automobileButton.backgroundColor = .clear
                
            }
            addRouteToMap(transportType: transportType)
        }
        
    }
    
    lazy var transitButton: UIButton = {
        
        let width = 30
        let height = 30
        let transitButton = UIButton(frame: CGRect(x: 15 + width*2, y: 10, width: width, height: height))
        transitButton.setImage(UIImage(systemName: "bus"), for: .normal)
        transitButton.layer.cornerRadius = CGFloat(width/2)
        transitButton.tintColor = UIColor(named: "reversed Color")
        transitButton.addTarget(self, action: #selector(self.transitButton(_:)), for: .touchUpInside)
        return transitButton
    }()
    
    @objc internal func transitButton(_ sender: UIButton) {
        print("transitButton")
        
        DispatchQueue.main.async { [self] in
            self.expectedTravelTime = 0
            transportType = 2
            if transportType == 2 {
               // mapView.addSubview(label)
                //label.isHidden = false
                automobileButton.backgroundColor = .clear
                transitButton.backgroundColor = .systemBackground
                walkingButton.backgroundColor = .clear
                polyLineButton.backgroundColor = .clear
                transitGuideLabel.isHidden = false
            } else {
                //label.isHidden = true
                //label.removeFromSuperview()
                transitButton.backgroundColor = .clear
                
            }
            
            addRouteToMap(transportType: transportType)
        }
    }
    
    lazy var walkingButton: UIButton = {
        
        let width = 30
        let height = 30
        let walkingButton = UIButton(frame: CGRect(x: 15 + width, y: 10, width: width, height: height))
        walkingButton.setImage(UIImage(systemName: "figure.walk"), for: .normal)
        walkingButton.layer.cornerRadius = CGFloat(width/2)
        walkingButton.tintColor = UIColor(named: "reversed Color")
        walkingButton.addTarget(self, action: #selector(self.walkingButton(_:)), for: .touchUpInside)
        return walkingButton
    }()
    
    @objc internal func walkingButton(_ sender: UIButton) {
        print("walkingButton")
        DispatchQueue.main.async { [self] in
            self.expectedTravelTime = 0
            transportType = 3
            if transportType == 3 {
                automobileButton.backgroundColor = .clear
                transitButton.backgroundColor = .clear
                walkingButton.backgroundColor = .systemBackground
                polyLineButton.backgroundColor = .clear
                transitGuideLabel.isHidden = true
            } else {
                walkingButton.backgroundColor = .clear
                
            }
            addRouteToMap(transportType: transportType)
        }
    }
    
    lazy var polyLineButton: UIButton = {
        
        let width = 30
        let height = 30
        let polyLineButton = UIButton(frame: CGRect(x: 15 + width*3, y: 10, width: width, height: height))
        polyLineButton.setImage(UIImage(systemName: "line.diagonal"), for: .normal)
        polyLineButton.tintColor = UIColor(named: "reversed Color")
        polyLineButton.layer.cornerRadius = CGFloat(width/2)
        polyLineButton.addTarget(self, action: #selector(self.polyLineButton(_:)), for: .touchUpInside)
        
        polyLineButton.backgroundColor = .systemBackground
        
        return polyLineButton
    }()
    
    @objc internal func polyLineButton(_ sender: UIButton) {
        print("polyLineButton")
        DispatchQueue.main.async { [self] in
            transportType = 0
            if transportType == 0 {
                automobileButton.backgroundColor = .clear
                transitButton.backgroundColor = .clear
                walkingButton.backgroundColor = .clear
                polyLineButton.backgroundColor = .systemBackground
                transitGuideLabel.isHidden = true
            } else {
                polyLineButton.backgroundColor = .clear
                
            }
            addRouteToMap(transportType: transportType)
        }
    }
    
    lazy var timeLabel: UILabel = {
        
        let width = 150
        let height = 40
        let timeLabel = UILabel(frame: CGRect(x: Int(view.frame.width) - width - 20, y: 5, width: width, height: height))
        
        timeLabel.textColor = UIColor(named: "reversed Color")
        timeLabel.textAlignment = .center
        timeLabel.layer.cornerRadius = CGFloat(height/2)
        timeLabel.backgroundColor = .systemGray4
        timeLabel.clipsToBounds = true
        return timeLabel
    }()
    
    func mapViewAnimation() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.dateCollectionView.isUserInteractionEnabled = true
        //self.mapContainerView.transform = .identity
        
        self.keysArray = self.eventCountsByDate.keys.sorted() //8.1, 8.2...
        self.valuesArray = Array(self.eventCountsByDate.values) // 2, 1, 6
        
        print("keysArray: ", keysArray)
        
        if !self.isfilteredEventUsable! {
            for dateKey in self.keysArray {
                guard let events = self.sectionedEvents[dateKey] else {
                    continue // Skip if there are no events for this date
                }
                //print("events: \(events)") // 섹션 별로 1번씩 반복됨
                for event in events {
                    if let eventLocation = event.structuredLocation,
                       let geoLocation = eventLocation.geoLocation {
                        let coordinate = geoLocation.coordinate
                        
                        
                        let annotation = MKPointAnnotation()
                        
                        annotation.title = event.title
                        annotation.subtitle = event.location
                        annotation.coordinate = coordinate
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "M/d (E)"
                        
                        let startDate = event.startDate
                        let color = dateFormatter.string(from: startDate!)
                        let returnColor = self.returnColor(color)
                        
                        self.addCustomPin(color: returnColor, coordinate: coordinate, labelNumber: self.labelNumber, title: event.title, location: event.structuredLocation?.title ?? "", ekEvent: event)
                        
                        self.labelNumber += 1
                    }
                }
            }
        } else {
            
            for event in self.filteredEvents {
                if let eventLocation = event.structuredLocation {
                    if let geoLocation = eventLocation.geoLocation {
                        let coordinate = geoLocation.coordinate
                        let annotation = MKPointAnnotation()
                        
                        annotation.title = event.title
                        annotation.subtitle = event.location
                        annotation.coordinate = coordinate
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "M/d (E)"
                        
                        let startDate = event.startDate
                        let color = dateFormatter.string(from: startDate!)
                        let returnColor = self.returnColor(color)
                        
                        self.addCustomPin(color: returnColor, coordinate: coordinate, labelNumber: self.labelNumber, title: event.title, location: event.structuredLocation?.title ?? "", ekEvent: event)
                        
                        self.labelNumber += 1
                        //self.mapView.addAnnotation(annotation)
                    }
                }
                
            }
        }
        
    }
    
    // Function to geocode an address and get the CLLocation
    private func geocodeAddress(_ address: String, completion: @escaping (CLLocation?) -> Void) {
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let location = placemarks?.first?.location {
                //print("geocodeAddress location: \(location)")
                completion(location)
            } else {
                completion(nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showMap(_:)), name: NSNotification.Name(rawValue: "showMap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteAllItems), name: NSNotification.Name(rawValue: "deleteAllItems"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noNumberAlert), name: NSNotification.Name(rawValue: "noNumberAlert"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateVisibleCells), name: NSNotification.Name(rawValue: "updateVisibleCells"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tripCollectionViewHeaderReload), name: NSNotification.Name(rawValue: "tripCollectionViewHeaderReload"), object: nil)
        
        collectionViewConfigure()
        //configure()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .automatic
        
        
    }
    
    @objc func tripCollectionViewHeaderReload(_ notification: Notification) {
        
        DispatchQueue.main.async {
            self.tripCollectionView.reloadData()
        }
        
    }
    
    
    @objc func noNumberAlert() {
        alert(title: "A value other than a number was entered".localized(), message: "Please enter numbers only".localized(), actionTitle: "OK".localized())
    }
    
    private func collectionViewConfigure() {
        
        isViewDidLoad = true
        multiSelection = []
        
        let truncatedTitle = tripTitle!.prefix(tripTitle!.count - 23)
        navigationItem.title = String(truncatedTitle)
        
        //view.addSubview(addButton)
        //view.addSubview(mapButton)
        
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        dateCollectionView.tag = 1
        
        tripCollectionView.dataSource = self
        tripCollectionView.delegate = self
        tripCollectionView.tag = 2
        tripCollectionView.dragInteractionEnabled = true
        
        dateCollectionView.showsHorizontalScrollIndicator = false
        tripCollectionView.showsVerticalScrollIndicator = false
        
        mapView.delegate = self
        
    }
    
    private func configure() {
        
        fetchEventsFromCalendar(startDate: tripStartDate!, endDate: tripEndDate!) {
            print("fetchEventsFromCalendar configure")
            self.configureReloadData()
        }
    }
    
    func configureReloadData() {
        timeInterval = []
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: self.tripStartDate!) // Remove time portion
        let endDate = calendar.startOfDay(for: self.tripEndDate!)
        
        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
        let monthsComponents = calendar.dateComponents([.month], from: startDate, to: endDate)
        
        let months = monthsComponents.month
        let days = dayComponents.day
        //print("months: \(months)")
        //print("days: \(days)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d (E)"
        
        var currentDate = startDate
        
        self.timeInterval.append(dateFormatter.string(from: currentDate))
        for _ in 0..<days! {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            self.timeInterval.append(dateFormatter.string(from: currentDate))
        }
        
        if self.filteredEvents == [] {
            
            DispatchQueue.main.async {
                self.dateCollectionView.reloadData()
                self.tripCollectionView.reloadData()
                print("configure reloadData")
            }
            
        } else { // self.filteredEvents != []
            
            for i in 0..<self.keysArray.count {
                let components = self.keysArray[i]//.components(separatedBy: " ")
                //if let dateSubstring = components.first { //dateSubstring: 8.1로 이름 입력
                    //print("dateSubstring: ", "\(dateSubstring)")
                //print("components: ", "\(components)")
                    // dateSubstring를 timeInterval 배열에 추가하기 전에 이미 존재하는지 확인
                if !self.timeInterval.contains(components) {
                    // 존재하지 않으면 추가
                    self.timeInterval.append(components)
                    
                    let sortedArray = timeInterval.sorted { (dateString1, dateString2) -> Bool in
                        if let date1 = dateFormatter.date(from: dateString1),
                           let date2 = dateFormatter.date(from: dateString2) {
                            return date1 < date2
                        }
                        return false
                    }
                    self.timeInterval = sortedArray
                }
                //}
            }
            //print("self.timeInterval: ", self.timeInterval)
            DispatchQueue.main.async {
                self.dateCollectionView.reloadData()
                self.tripCollectionView.reloadData()
                print("configure reloadData")
            }
        }
    }
//    private func configure() {
//        
//        let currentTimeZone = TimeZone.current.identifier
//        
//        let today = Date()
//        let timezone = TimeZone.autoupdatingCurrent
//        let secondsFromGMT = timezone.secondsFromGMT(for: today)
//        
//        let calendar = Calendar.current
//        let startDate = calendar.startOfDay(for: tripStartDate!) // Remove time portion
//        let endDate = calendar.startOfDay(for: tripEndDate!)
//        
//        //let startDate = tripStartDate!.addingTimeInterval(TimeInterval(secondsFromGMT))
//        //let endDate = tripEndDate!.addingTimeInterval(TimeInterval(secondsFromGMT))
//        print("startDate: \(startDate)")
//        print("endDate: \(endDate)")
//        
//        tripStartDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
//        print("tripStartDate: ", tripStartDate)
//        tripEndDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
//        print("tripEndDate: ", tripEndDate)
//        
////        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
////        let monthsComponents = calendar.dateComponents([.month], from: startDate, to: endDate)
//        let dayComponents = calendar.dateComponents([.day], from: startDate, to: tripEndDate!)
//        let monthsComponents = calendar.dateComponents([.month], from: tripStartDate!, to: tripEndDate!)
//
//        let months = monthsComponents.month
//        let days = dayComponents.day!-1
//        print("months: \(months)")
//        print("days: \(days)")
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "M/d (E)"
//        
//        var currentDate = startDate
//        
//        timeInterval.append(dateFormatter.string(from: currentDate))
//        for _ in 0..<days {
//            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
//            timeInterval.append(dateFormatter.string(from: currentDate))
//        }
//        print("timeInterval: ", timeInterval)
//        
//        fetchEventsFromCalendar(startDate: tripStartDate!, endDate: tripEndDate!)
//    }
    
    func barItemConfigure() {
        
        navigationItem.rightBarButtonItem = nil
        
        let buttonContainerView = UIView(frame: CGRect(x: 0, y: -10, width: 150, height: 60)) // Adjust width and height as needed
        
        if UIDevice.current.orientation.isLandscape {
            // 가로 모드
            addButton.frame = CGRect(x: 0, y: -10, width: 40, height: 50)
            mapButton.frame = CGRect(x: 40, y: -10, width: 40, height: 50)
            calculateButton.frame = CGRect(x: 80, y: -10, width: 40, height: 50)
            settingButton.frame = CGRect(x: 120, y: -10, width: 40, height: 50)
        } else {
            addButton.frame = CGRect(x: 0, y: 0, width: 40, height: 50)
            mapButton.frame = CGRect(x: 40, y: 0, width: 40, height: 50)
            calculateButton.frame = CGRect(x: 80, y: 0, width: 40, height: 50)
            settingButton.frame = CGRect(x: 120, y: 0, width: 40, height: 50)
        }

        buttonContainerView.addSubview(addButton)
        buttonContainerView.addSubview(mapButton)
        buttonContainerView.addSubview(calculateButton)
        buttonContainerView.addSubview(settingButton)
        
        let customBarButtonItem = UIBarButtonItem(customView: buttonContainerView)
        navigationItem.rightBarButtonItem = customBarButtonItem
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            // 화면 회전 이벤트 감지 시, 프레임을 조정
            if self?.traitCollection.verticalSizeClass == .regular {
                // 세로 모드
                self?.barItemConfigure()
            } else {
                // 가로 모드
                self?.barItemConfigure()
            }
        }, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideKeyboardWhenTappedAround()
        
        loadTripForExpense() { }
        
        barItemConfigure()
        configure()
        
        mapView.removeFromSuperview()
        
        // 맵 컨테이너 뷰 추가
        mapContainerView = UIView()
        mapContainerView.translatesAutoresizingMaskIntoConstraints = false
        mapContainerView.backgroundColor = .clear
        mapContainerView.layer.cornerRadius = 30
        
        mapContainerView.layer.shadowColor = UIColor(named: "gray Color")?.cgColor
        mapContainerView.layer.shadowRadius = 5
        mapContainerView.layer.shadowOpacity = 0.75
        
        mapView.layer.cornerRadius = 30
        mapView.layer.borderWidth = 0.5
        mapView.layer.borderColor = UIColor(named: "gray Color")?.cgColor
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        mapContainerView.addSubview(mapView)
        mapContainerView.addSubview(automobileButton)
        mapContainerView.addSubview(transitButton)
        mapContainerView.addSubview(walkingButton)
        mapContainerView.addSubview(polyLineButton)
        
        mapContainerView.addSubview(timeLabel)
        
        let backButtonView = UIView(frame: CGRect(x: 10, y: 5, width: 130, height: 40))
        backButtonView.backgroundColor = .systemGray4
        backButtonView.layer.cornerRadius = 20
        
        mapContainerView.addSubview(transitGuideLabel)
        mapContainerView.addSubview(backButtonView)
        transitGuideLabel.isHidden = true
        
        mapContainerView.bringSubviewToFront(automobileButton)
        mapContainerView.bringSubviewToFront(transitButton)
        mapContainerView.bringSubviewToFront(walkingButton)
        mapContainerView.bringSubviewToFront(polyLineButton)
        
        let width: CGFloat = 150
        let height: CGFloat = 40
    
        let label = UILabel(frame: CGRect(x: CGFloat(Int(view.frame.width)) - width - 15, y: timeLabel.bounds.maxY + 5, width: timeLabel.frame.width - 10, height: height))
        label.text = appleMapGuide.localized()
        label.font = .systemFont(ofSize: 9, weight: .light)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        label.contentMode = .topLeft
        //label.backgroundColor = .white.withAlphaComponent(0.1)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
//        label.layer.borderWidth = 2
//        label.layer.borderColor = .none
        mapContainerView.addSubview(label)
        
        view.addSubview(mapContainerView)
        
        mapContainerView.bringSubviewToFront(timeLabel)
        
        NSLayoutConstraint.activate([
            mapContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            mapContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            //mapContainerView.heightAnchor.constraint(equalToConstant: 650),
            //mapContainerView.heightAnchor.constraint(equalTo: tripCollectionView.heightAnchor),
            mapContainerView.topAnchor.constraint(equalTo: dateCollectionView.bottomAnchor, constant: 10),
            mapContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            //mapContainerView.bottomAnchor.constraint(equalTo: mapButton.topAnchor, constant: -10)
        ])
        
        mapContainerView.transform = CGAffineTransform(translationX: 0, y: 0)
        mapContainerView.isHidden = true
        
        DispatchQueue.main.async {
            self.dateCollectionView.reloadData()
            self.tripCollectionView.reloadData()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tripTitle = nil
        tripPlace = nil
        tripStartDate = nil
        tripEndDate = nil
        
        //let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        //self.navigationItem.backBarButtonItem = backBarButtonItem // Back 버튼 삭제
        
    }
    
}

extension TripViewController : EKEventViewDelegate, UINavigationControllerDelegate {
    // 새 트립을 가져오고, 새 일정을 추가하면, 다른 트립의 일정들을 가져옴
    func fetchEventsFromCalendar(startDate: Date, endDate: Date, completion: @escaping () -> Void) {
        
        events = []
        //events.removeAll()

        switch EKEventStore.authorizationStatus(for: .event) {
//        case .authorized:
//            print("fetchEventsFromCalendar authorized")
//            //            if #available(iOS 17.0, *) {
//            //                
//            //            } else {
//            let entityType = EKEntityType.event
//            let calendars = eventStore.calendars(for: entityType)
//            
//            let targetCalendarName = tripTitle!
//            let filteredCalendars = calendars.filter { calendar in
//                return calendar.title == targetCalendarName
//            }
//            
//            let calendar = Calendar.current
//            
//            let newStartDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
//            print("newStartDate: ", newStartDate)
//            let newEndDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
//            print("newEndDate: ", newEndDate)
//            
//            for _ in filteredCalendars {
//                let predicate = eventStore.predicateForEvents(withStart: newStartDate, end: newEndDate, calendars: calendars)
//                let fetchedEvents = eventStore.events(matching: predicate)
//                //events = fetchedEvents
//                
//                for event in fetchedEvents {
//                    if let calendar = event.calendar, calendar.title == targetCalendarName {
//                        if !events.contains(event) {
//                            events.append(event)
//                        }
//                    }
//                }
//            }
//            
//            filteredEvents = events
//            
//            calculateEventCountsByDate()
//            updateFilteredEvents(indexRow: indexRow)
        //}
            
        case .notDetermined:
            print("fetchEventsFromCalendar notDetermined")
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Please enable Full Access to your Calendar".localized(), message: "Required for adding and managing schedules".localized(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                    
                    if #available(iOS 17.0, *) {
                        print(" if #available(iOS 17.0, *) {")
                        //let eventStore = EKEventStore()
                        eventStore.requestFullAccessToEvents() { granted, error in
                        //eventStore.requestFullAccessToEvents() { granted, error in
                            
                            if granted {
                                print("granted")
//                                let store = CNContactStore()
//                                store.requestAccess(for: .contacts) { granted, error in
//                                    if granted {
//                                        
//                                    }
//                                }
                            } else {
                                print("not granted")
//                                DispatchQueue.main.async {
//                                    self.fetchEventsFromCalendar(startDate: startDate, endDate: endDate)
//                                }
                            }
                            
                        }
                    } else {
                        print("!!if #available(iOS 17.0, *) {")
                        eventStore.requestAccess(to: .event) { granted, error in
                            if granted {
//                                let store = CNContactStore()
//                                store.requestAccess(for: .contacts) { granted, error in
//                                    if granted {
//                                        
//                                    }
//                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.fetchEventsFromCalendar(startDate: startDate, endDate: endDate) {
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                alertController.addAction(action)
                self.present(alertController, animated: true)
            }
        
        case .denied, .restricted:
            print("fetchEventsFromCalendar .denied, .restricted:")
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Please enable Full Access to your Calendar in Settings".localized(), message: "Calendar access has been denied".localized(), preferredStyle: .alert)
                let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
                let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
                    
                    self.openAppSettings()
                }
                
                alertController.addAction(action1)
                alertController.addAction(action2)
                self.present(alertController, animated: true)
            }
        case .writeOnly:
            print("fetchEventsFromCalendar writeOnly")
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Please enable Full Access to your Calendar in Settings".localized(), message: "Calendar access has been denied".localized(), preferredStyle: .alert)
                let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
                let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
                    
                    self.openAppSettings()
                }
                
                alertController.addAction(action1)
                alertController.addAction(action2)
                self.present(alertController, animated: true)
            }
            
        case .fullAccess:
            print("fetchEventsFromCalendar fullAccess")
            
            //let eventStore = EKEventStore()
            let entityType = EKEntityType.event
            let calendars = eventStore.calendars(for: entityType)
            //print("calendars: ", calendars)
            let targetCalendarName = tripTitle!
            let filteredCalendars = calendars.filter { calendar in
                //print("calendar: ", calendar)
                return calendar.title == targetCalendarName
            }
            //print("filteredCalendars: ", filteredCalendars)
            
            let calendar = Calendar.current
            
            let newStartDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
            //print("newStartDate: ", newStartDate)
            let newEndDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
            //print("newEndDate: ", newEndDate)
            
            for _ in filteredCalendars {
                let predicate = eventStore.predicateForEvents(withStart: newStartDate, end: newEndDate, calendars: calendars)
                let fetchedEvents = eventStore.events(matching: predicate)
                //events = fetchedEvents
                //print("fetchedEvents: ", fetchedEvents)
                
                for event in fetchedEvents {
                    if let calendar = event.calendar, calendar.title == targetCalendarName {
                        if !events.contains(event) {
                            events.append(event)
                        }
                    }
                }
            }
            
            filteredEvents = events

            calculateEventCountsByDate()
            updateFilteredEvents(indexRow: indexRow)
            

        @unknown default:
            print("Unknown authorization status")
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Unknown calendar access".localized(), message: "Please check access authorization to your Calendar in Settings\nAllow Full Calendar Access".localized(), preferredStyle: .alert)
                let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
                let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
                    
                    self.openAppSettings()
                }
                
                alertController.addAction(action1)
                alertController.addAction(action2)
                self.present(alertController, animated: true)
            }
        }
        
        DispatchQueue.main.async {
            self.configureReloadData()
//            self.dateCollectionView.reloadData()
//            self.tripCollectionView.reloadData()
            print("fetchEventsFromCalendar dateCollectionView tripCollectionView reloadData")
            completion()
        }
        
    }
    
    func showEventDetails(_ event: EKEvent) {

        let eventViewController = EKEventEditViewController()
        eventViewController.editViewDelegate = self
        eventViewController.event = event
        present(eventViewController, animated: true, completion: nil)
        
        //let eventViewController = EKEventViewController()
        //eventViewController.delegate = self
        //eventViewController.allowsEditing = true
        
        //let navController = UINavigationController(rootViewController: eventViewController)
        //present(navController, animated: true, completion: nil)
        
    }

    func requestAccessToEventStore(_ eventTitle: String, _ locationTitle: String, index: Int?) {
        //let eventStore = EKEventStore()
        let calendar = Calendar.current
        
        if #available(iOS 17.0, *) {
            //eventStore.requestFullAccessToEvents() { [weak self] granted, error in
                //if granted {
                    // 권한이 허용되었을 때의 처리
                    DispatchQueue.main.async {
                        
//                        let store = CNContactStore()
//                        store.requestAccess(for: .contacts) { granted, error in
//                            if granted {
//                                
//                            }
//                        }
                        
                        //let store = self.eventStore
                        let store = eventStore
                        let newEvent = EKEvent(eventStore: store)

                        newEvent.title = eventTitle
                        
                        if let index = index { // dateCollectionView에서 날짜를 클릭한 경우
                            newEvent.startDate = calendar.date(byAdding: .day, value: index, to: self.tripStartDate!)
                            newEvent.endDate = calendar.date(byAdding: .day, value: index, to: self.tripStartDate!)
                        } else { // dateCollectionView에서 All을 클릭한 경우
                            newEvent.startDate = calendar.date(byAdding: .day, value: 0, to: self.tripStartDate!)
                            newEvent.endDate = calendar.date(byAdding: .day, value: 0, to: self.tripStartDate!)
                        }
                        
                        newEvent.isAllDay = true
                        newEvent.alarms = []
                        
                        // Set up the structured location
                        let structuredLocation = EKStructuredLocation(title: locationTitle)
                        newEvent.structuredLocation = structuredLocation
                        
                        // Find or create a custom calendar
                        var customCalendar: EKCalendar?
                        
                        for calendar in store.calendars(for: .event) {
                            if calendar.title == self.tripTitle {
                                customCalendar = calendar
                                break
                            }
                        }
                        
                        //print("self!.eventStore.sources: \(self!.eventStore.sources)")
                        //print("self!.eventStore.defaultCalendarForNewEvents: \(self!.eventStore.defaultCalendarForNewEvents)")
                        
                        if customCalendar == nil { // 여행 신규 생성
                            customCalendar = EKCalendar(for: .event, eventStore: store)
                            customCalendar!.title = self.tripTitle!
                            customCalendar!.cgColor = UIColor(hex: self.tripTagColor!)?.cgColor
                            //customCalendar!.source = iCloudSource
                            
//                            if let localSource = self.eventStore.sources.first(where: {
                            if let localSource = eventStore.sources.first(where: {
                                $0.sourceType == .calDAV && $0.title == "iCloud"}) { // iCloud 버전
                                print("$0.sourceType == .calDAV && $0.title == iCloud")
                                let alertController = UIAlertController(title: "Saves schedules to iCloud".localized(), message: "You can also check schedules using iCloud on other devices".localized(), preferredStyle: .alert)
                                let action = UIAlertAction(title: "OK".localized(), style: .default) { _ in
                                    
                                    customCalendar!.source = localSource
                                    newEvent.calendar = customCalendar
                                    
                                    do {
//                                        try self.eventStore.saveCalendar(customCalendar!, commit: true)
                                        try eventStore.saveCalendar(customCalendar!, commit: true)
                                        
                                    } catch {
                                        print("Error saving custom calendar: \(error)")
                                    }
                                    
                                    let vc = EKEventEditViewController()
                                    vc.editViewDelegate = self
                                    vc.eventStore = store
                                    vc.event = newEvent
                                    self.present(vc, animated: true, completion: nil)
                                    
                                }
                                alertController.addAction(action)
                                self.present(alertController, animated: true)
                                
//                            } else if let iCloudSource = self.eventStore.sources.first(where: {
                            } else if let iCloudSource = eventStore.sources.first(where: {
                                
                                $0.sourceType == .local }){ // 로컬 버전
                                print(" $0.sourceType == .local")
                                let alertController = UIAlertController(title: "Saves schedules to the local device".localized(), message: "If you want to sync with iCloud, enable the use of iCloud calendars in Settings\n\n1. Go to Settings > your name\n2. Tap iCloud > Tap Show All\n3. Turn on Calendar".localized(), preferredStyle: .alert)
                                let action = UIAlertAction(title: "OK".localized(), style: .default) { _ in
                                    
                                    customCalendar!.source = iCloudSource
                                    newEvent.calendar = customCalendar
                                    
                                    do {
                                        //try self.eventStore.saveCalendar(customCalendar!, commit: true)
                                        try eventStore.saveCalendar(customCalendar!, commit: true)
                                        
                                    } catch {
                                        print("Error saving custom calendar: \(error)")
                                    }
                                    
                                    let vc = EKEventEditViewController()
                                    vc.editViewDelegate = self
                                    vc.eventStore = store
                                    vc.event = newEvent
                                    self.present(vc, animated: true, completion: nil)
                                    
                                }
                                alertController.addAction(action)
                                self.present(alertController, animated: true)
                                
                            } else {
                                
//                                if let defaultCalendarForNewEvents = self.eventStore.defaultCalendarForNewEvents {
                                if let defaultCalendarForNewEvents = eventStore.defaultCalendarForNewEvents {
                                    
                                    let alertController = UIAlertController(title: "Fail to save schedules on \(defaultCalendarForNewEvents.title)".localized(), message: "To sync with iCloud, enable the use of iCloud calendars in Settings\n\n1. Go to Settings > your name\n2. Tap iCloud > Tap Show All\n3. Turn on Calendar".localized(), preferredStyle: .alert)
                                    
                                    let action1 = UIAlertAction(title: "Back".localized(), style: .default, handler: nil)
                                    let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { _ in
                                        self.openAppSettings()
                                    }
                                    alertController.addAction(action1)
                                    alertController.addAction(action2)
                                    self.present(alertController, animated: true)
                                }
                                
                            }
                            
                            newEvent.calendar = customCalendar
                            
                            do {
//                                try self.eventStore.saveCalendar(customCalendar!, commit: true)
                                try eventStore.saveCalendar(customCalendar!, commit: true)
                                
                            } catch {
                                print("Error saving custom calendar: \(error)")
                            }
                        } else { // 기존에 생성된 캘린더 존재
                            newEvent.calendar = customCalendar
                        }
                        
                        let vc = EKEventEditViewController()
                        vc.editViewDelegate = self
                        vc.eventStore = store
                        vc.event = newEvent
                        self.present(vc, animated: true, completion: nil)
                        
                    }
//                } else {
//                    // 권한이 거부되었을 때의 처리
//                    print("권한이 거부")
//                    print("error", error)
//                    
//                    DispatchQueue.main.async {
//                        
//                        let alertController = UIAlertController(title: "Please enable Full Access to your Calendar in Settings".localized(), message: "Calendar access has been denied".localized(), preferredStyle: .alert)
//                        let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
//                        let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
//                            
//                            self!.openAppSettings()
//                        }
//                        
//                        alertController.addAction(action1)
//                        alertController.addAction(action2)
//                        self!.present(alertController, animated: true)
//                    }
//                        
//                    
//                }
            //}
        } else {
            let eventStore = eventStore
            
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    // 권한이 허용되었을 때의 처리
                    DispatchQueue.main.async {
                        
//                        let store = CNContactStore()
//                        store.requestAccess(for: .contacts) { granted, error in
//                            if granted {
//                                
//                            }
//                        }
                        
//                        guard let store = self?.eventStore else {
//                            print("guard let store = self?.eventStore else")
//                            return
//                            
//                        }
//                        let eventStore = EKEventStore()
                        let store = eventStore
                        let newEvent = EKEvent(eventStore: store)
                        newEvent.title = eventTitle
                        
                        if let index = index { // dateCollectionView에서 날짜를 클릭한 경우
                            newEvent.startDate = calendar.date(byAdding: .day, value: index, to: self.tripStartDate!)
                            newEvent.endDate = calendar.date(byAdding: .day, value: index, to: self.tripStartDate!)
                        } else { // dateCollectionView에서 All을 클릭한 경우
                            newEvent.startDate = calendar.date(byAdding: .day, value: 0, to: self.tripStartDate!)
                            newEvent.endDate = calendar.date(byAdding: .day, value: 0, to: self.tripStartDate!)
                        }
                        
                        newEvent.isAllDay = true
                        newEvent.alarms = []
                        
                        // Set up the structured location
                        let structuredLocation = EKStructuredLocation(title: locationTitle)
                        newEvent.structuredLocation = structuredLocation
                        
                        // Find or create a custom calendar
                        var customCalendar: EKCalendar?
                        
                        for calendar in store.calendars(for: .event) {
                            if calendar.title == self.tripTitle {
                                customCalendar = calendar
                                break
                            }
                        }
                        
                        //print("self!.eventStore.sources: \(self!.eventStore.sources)")
                        //print("self!.eventStore.defaultCalendarForNewEvents: \(self!.eventStore.defaultCalendarForNewEvents)")
                        
                        if customCalendar == nil { // 여행 신규 생성
                            customCalendar = EKCalendar(for: .event, eventStore: store)
                            customCalendar!.title = self.tripTitle!
                            customCalendar!.cgColor = UIColor(hex: self.tripTagColor!)?.cgColor
                            //customCalendar!.source = iCloudSource
                            
                            if let localSource = eventStore.sources.first(where: {
                            //if let localSource = self.eventStore.sources.first(where: {
                                $0.sourceType == .calDAV && $0.title == "iCloud"}) { // iCloud 버전
                                print("$0.sourceType == .calDAV && $0.title == iCloud")
                                let alertController = UIAlertController(title: "Saves schedules to iCloud".localized(), message: "You can also check schedules using iCloud on other devices".localized(), preferredStyle: .alert)
                                let action = UIAlertAction(title: "OK".localized(), style: .default) { _ in
                                    
                                    customCalendar!.source = localSource
                                    newEvent.calendar = customCalendar
                                    
                                    do {
//                                        try self!.eventStore.saveCalendar(customCalendar!, commit: true)
                                        try eventStore.saveCalendar(customCalendar!, commit: true)
                                        
                                    } catch {
                                        print("Error saving custom calendar: \(error)")
                                    }
                                    
                                    let vc = EKEventEditViewController()
                                    vc.editViewDelegate = self
                                    vc.eventStore = store
                                    vc.event = newEvent
                                    self.present(vc, animated: true, completion: nil)
                                    
                                }
                                alertController.addAction(action)
                                self.present(alertController, animated: true)
                                
                            //} else if let iCloudSource = self!.eventStore.sources.first(where: {
                            } else if let iCloudSource = eventStore.sources.first(where: {
                                
                                $0.sourceType == .local }){ // 로컬 버전
                                print(" $0.sourceType == .local")
                                let alertController = UIAlertController(title: "Saves schedules to the local device".localized(), message: "If you want to sync with iCloud, enable the use of iCloud calendars in Settings\n\n1. Go to Settings > your name\n2. Tap iCloud > Tap Show All\n3. Turn on Calendar".localized(), preferredStyle: .alert)
                                let action = UIAlertAction(title: "OK".localized(), style: .default) { _ in
                                    
                                    customCalendar!.source = iCloudSource
                                    newEvent.calendar = customCalendar
                                    
                                    do {
                                        //try self!.eventStore.saveCalendar(customCalendar!, commit: true)
                                        try eventStore.saveCalendar(customCalendar!, commit: true)
                                        
                                    } catch {
                                        print("Error saving custom calendar: \(error)")
                                    }
                                    
                                    let vc = EKEventEditViewController()
                                    vc.editViewDelegate = self
                                    vc.eventStore = store
                                    vc.event = newEvent
                                    self.present(vc, animated: true, completion: nil)
                                    
                                }
                                alertController.addAction(action)
                                self.present(alertController, animated: true)
                                
                            } else {
                                
                                if let defaultCalendarForNewEvents = eventStore.defaultCalendarForNewEvents {
                                   // if let defaultCalendarForNewEvents = self!.eventStore.defaultCalendarForNewEvents {
                                    
                                    let alertController = UIAlertController(title: "Fail to save schedules on \(defaultCalendarForNewEvents.title)".localized(), message: "To sync with iCloud, enable the use of iCloud calendars in Settings\n\n1. Go to Settings > your name\n2. Tap iCloud > Tap Show All\n3. Turn on Calendar".localized(), preferredStyle: .alert)
                                    
                                    let action1 = UIAlertAction(title: "Back".localized(), style: .default, handler: nil)
                                    let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { _ in
                                        self.openAppSettings()
                                    }
                                    alertController.addAction(action1)
                                    alertController.addAction(action2)
                                    self.present(alertController, animated: true)
                                }
                                
                            }
                            
                            newEvent.calendar = customCalendar
                            
                            do {
//                                try self!.eventStore.saveCalendar(customCalendar!, commit: true)
                                try eventStore.saveCalendar(customCalendar!, commit: true)
                                
                            } catch {
                                print("Error saving custom calendar: \(error)")
                            }
                        } else { // 기존에 생성된 캘린더 존재
                            newEvent.calendar = customCalendar
                        }
                        
                        let vc = EKEventEditViewController()
                        vc.editViewDelegate = self
                        vc.eventStore = store
                        vc.event = newEvent
                        self.present(vc, animated: true, completion: nil)
                        
                    }
                } else {
                    // 권한이 거부되었을 때의 처리
                    print("권한이 거부")
                    DispatchQueue.main.async {
                        
                        let alertController = UIAlertController(title: "Please enable Full Access to your Calendar in Settings".localized(), message: "Calendar access has been denied".localized(), preferredStyle: .alert)
                        let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
                        let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
                            
                            self.openAppSettings()
                        }
                        
                        alertController.addAction(action1)
                        alertController.addAction(action2)
                        self.present(alertController, animated: true)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.tripCollectionView.reloadData()
        }
    }

    
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        
        if action == .done {
            
            if let updatedEvent = controller.event, let updatedLocation = updatedEvent.structuredLocation {
                
                if let updatedEventLocation = updatedEvent.location, let schedule = updatedEvent.title {
                    
                    let addressComponents = updatedEventLocation.components(separatedBy: "\n")
                    
                    let placeTitle = addressComponents.first!
                    let placeSubTitle = addressComponents.last!
                    print("placeTitle: \(placeTitle)")
                    print("placeSubTitle: \(placeSubTitle)")
                    
                    if let location = updatedLocation.geoLocation {
                        geocoder.reverseGeocodeLocation(location) { placemarks, error in
                            
                            if let placemark = placemarks?.first {
                                if let location = placemark.location {
                                    
                                    let latitude = location.coordinate.latitude
                                    let longitude = location.coordinate.longitude
                                    
                                    guard let startDate = updatedEvent.startDate else { return }
                                    print("startDate: \(startDate)")
                                    guard let endDate = updatedEvent.endDate else { return }
                                    print("endDate: \(endDate)")
                                    
                                    self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)  {
                                        
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                }
                
            }
            
            DispatchQueue.main.async {
                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!) {
                    
                }
            }
            
            //sleep(UInt32(0.1))
            if self.isMapVisible { // 지도를 클릭함
                
            } else { // 지도가 켜져있음)
                NotificationCenter.default.post(name: Notification.Name("showMap"), object: nil)
            }
            DispatchQueue.main.async {
                self.tripCollectionView.reloadData()
            }
            controller.dismiss(animated: true, completion: nil)
            print("DONE")
            
        } else if action == .responded {
            DispatchQueue.main.async {
                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!) {
                    
                }
            }
            
            controller.dismiss(animated: true, completion: nil)
            print("responded")
            DispatchQueue.main.async {
                self.tripCollectionView.reloadData()
            }
            
        } else {
            DispatchQueue.main.async {
                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)  {
                    
                }
            }
            
            controller.dismiss(animated: true, completion: nil)
            print("CANNCELLED")
            DispatchQueue.main.async {
                self.tripCollectionView.reloadData()
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // EKEventViewController가 화면에 나타날 때의 추가 동작 수행
        
    }
    
    
    
}

extension TripViewController : EKEventEditViewDelegate {

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        //let eventStore = EKEventStore()
        switch action {
            case .saved: // 사용자가 이벤트를 저장했을 때
                if let event = controller.event {
                    do {
                        try eventStore.save(event, span: .thisEvent)
                        print("Event saved successfully.")
                    } catch {
                        print("Error saving event: \(error.localizedDescription)")
                    }
                    
                    if self.isMapVisible{
                        
                    } else {// 지도가 켜져있음
                        NotificationCenter.default.post(name: Notification.Name("showMap"), object: nil)
                    }
                    print("Saved")
                    
                    DispatchQueue.main.async {
                        self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!) {
                            
                        }
                        self.tripCollectionView.reloadData()
                    }
                    
                } else {
                    print("!let event = controller.event")
                }
            case .canceled: // 사용자가 편집을 취소했을 때
                print("Event editing canceled.")
            
            case .deleted: // 사용자가 이벤트를 삭제했을 때
                print("Event deleted.")
                DispatchQueue.main.async {
                    self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)  {
                        
                    }
                    self.tripCollectionView.reloadData()
                }
            
            default:
                print("default")
                break
            }
        
            // 편집 뷰 컨트롤러를 닫습니다.
            controller.dismiss(animated: true, completion: nil)
        //
        
//        if action == .saved {
//            
//            if let updatedEvent = controller.event, let updatedLocation = updatedEvent.structuredLocation {
//                
//                if let updatedEventLocation = updatedEvent.location, let schedule = updatedEvent.title {
//                    
//                    let addressComponents = updatedEventLocation.components(separatedBy: "\n")
//                    
//                    let placeTitle = addressComponents.first!
//                    let placeSubTitle = addressComponents.last!
//                    print("placeTitle: \(placeTitle)")
//                    print("placeSubTitle: \(placeSubTitle)")
//                    
//                    if let location = updatedLocation.geoLocation {
//                        geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                            
//                            if let placemark = placemarks?.first {
//                                if let location = placemark.location {
//                                    
//                                    let latitude = location.coordinate.latitude
//                                    let longitude = location.coordinate.longitude
//                                    
//                                    guard let startDate = updatedEvent.startDate else { return }
//                                    print("startDate: \(startDate)")
//                                    guard let endDate = updatedEvent.endDate else { return }
//                                    print("endDate: \(endDate)")
//                                    
//                                    //self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)
//                                    
//                                    
//                                }
//                                
//                            }
//                        }
//                    }
//                }
//                
//            }
//            
//            //self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)
//            if self.isMapVisible{
//                
//            } else {// 지도가 켜져있음
//                NotificationCenter.default.post(name: Notification.Name("showMap"), object: nil)
//            }
//            print("Saved")
//            DispatchQueue.main.async {
//                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)
//                self.tripCollectionView.reloadData()
//            }
//            controller.dismiss(animated: true, completion: nil)
            
//        } else if action == .deleted {
//            DispatchQueue.main.async {
//                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)
//            }
//            print("responded")
//            DispatchQueue.main.async {
//                self.tripCollectionView.reloadData()
//            }
//            controller.dismiss(animated: true, completion: nil)
            
//        } else if action == .canceled {
//            DispatchQueue.main.async {
//                self.fetchEventsFromCalendar(startDate: self.tripStartDate!, endDate: self.tripEndDate!)
//            }
//            print("CANNCELLED")
//            DispatchQueue.main.async {
//                self.tripCollectionView.reloadData()
//            }
//            controller.dismiss(animated: true, completion: nil)
//        }
        
    }
    
    
}

extension TripViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func calculateEventCountsByDate() {
        DispatchQueue.main.async {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            
            self.eventCountsByDate = Dictionary(grouping: self.filteredEvents) { event in
                return dateFormatter.string(from: event.startDate)
            }
            .mapValues { events in
                
                return events.count
            }
            //print("eventCountsByDate: \(self.eventCountsByDate)")

        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView.tag == 1 {
            return 1
        } else {
            if clickedCellTitle == "All" {
                return eventCountsByDate.count
            } else if clickedCellTitle != "All" {
                return 1
            } else {
                return 0
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView.tag == 1 {
            
            return timeInterval.count + 1
            
        } else {
            
            let placeholderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tripCollectionView.bounds.size.width, height: tripCollectionView.bounds.size.height))
            placeholderLabel.text = "No Schedule".localized()
            placeholderLabel.textAlignment = .center
            placeholderLabel.textColor = .gray
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            
            //let sortedKeysEventCountsByDate = eventCountsByDate.keys.sorted()
            let sortedValuesEventCountsByDate = Array(eventCountsByDate.values)
            
            let sortedKeysEventCountsByDate = eventCountsByDate.keys.sorted { (dateString1, dateString2) -> Bool in
                if let date1 = dateFormatter.date(from: dateString1),
                   let date2 = dateFormatter.date(from: dateString2) {
                    return date1 < date2
                }
                return false
            }
            
            self.keysArray = sortedKeysEventCountsByDate // 8.1 , 8.2, ...
            self.valuesArray = sortedValuesEventCountsByDate // 1, 1, 10..
            
//            print("keysArraySection: ", keysArraySection)
//            print("section: ", section)
            
            if !isfilteredEventUsable! {
                
                if self.keysArray != [] {
                    
                    let keysArraySection = self.keysArray[section]
                    //if let itemNumber = eventCountsByDate[sortedArray[section]] {
                    if let itemNumber = eventCountsByDate[keysArraySection] {
                        //print("###eventCountsByDate: ", eventCountsByDate, "keysArray[section]: ", keysArray[section], "itemNumber: ", itemNumber)
                        //print("itemNumber: ", itemNumber)
                        //print("")
                        return itemNumber
                        
                    } else {
                        return 1
                    }
                } else {
                    return 0
                }
            } else {
                
                return filteredEvents.count
                
            }
            
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView.tag == 1 {
            return 30
        } else {
            return 20
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView.tag == 1 { // dateCollectionView
            
            if let selectedCell = dateCollectionView.cellForItem(at: indexPath) as? TripViewCollectionViewCell {
                
                if indexPath.row == 0 { // '전체' 클릭시
                    clickedCellTitle = selectedCell.tripDateLabel.text!
                    dateCollectionViewIndex = nil
                    indexRow = indexPath.row
                    isfilteredEventUsable = false
                    
                    // 해당 날짜가 startDate인 일정 가져와야함
                    updateFilteredEvents(indexRow: indexRow)
                    
                    for cell in dateCollectionView.visibleCells {
                        if let tripCell = cell as? TripViewCollectionViewCell {
                            tripCell.clickCount = 0
                        }
                    }
                    isViewDidLoad = false
                    
                    selectedCell.clickCount = 1
                    
                    DispatchQueue.main.async {
                        self.labelNumber = 0
                        self.addRouteToMap(transportType: self.transportType)
                        //self.addPolylinesToMap()
                        self.mapViewAnimation()
                    }
                    
                } else { // 1일차, 2일차, 3일차... 클릭시
                    
                    clickedCellTitle = selectedCell.tripDateLabel.text!
                    dateCollectionViewIndex = indexPath.row - 1
                    //indexRow = indexPath.row
                    indexRow = indexPath.row
                    isfilteredEventUsable = true
                    
                    // 해당 날짜가 startDate인 일정 가져와야함
                    updateFilteredEvents(indexRow: indexRow)
                    
                    for cell in dateCollectionView.visibleCells {
                        if let tripCell = cell as? TripViewCollectionViewCell {
                            tripCell.clickCount = 0
                        }
                    }
                    isViewDidLoad = false
            
                    selectedCell.clickCount = 1
                    
                    DispatchQueue.main.async {
                        self.labelNumber = 0
                        self.addRouteToMap(transportType: self.transportType)
                        //self.addPolylinesToMap()
                        self.mapViewAnimation()
                    }
                }
            }
            
        } else { // tripCollectionView
            isAnnotationClicked = false
            
            if let cell = collectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
                //cell.isSelected = true
                if !collectionView.allowsMultipleSelection {
                    collectionView.deselectItem(at: indexPath, animated: true)
                } else {
                    
                }
                
                if !isDollarSignEnable {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "M/d (E)"
                    
                    let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
                        if let date1 = dateFormatter.date(from: dateString1),
                           let date2 = dateFormatter.date(from: dateString2) {
                            return date1 < date2
                        }
                        return false
                    }
                    
                    let sectionTitle = sortedArray[indexPath.section]
                    
                    //let sectionTitle = keysArray[indexPath.section]
                    let sectionItemCount = valuesArray[indexPath.section]
                    
                    //print("sectionTitle: \(sectionTitle)")
                    //print("sectionItemCount: \(sectionItemCount)")
                    
                    let event: EKEvent
                    
                    if let eventsInSection = sectionedEvents[sectionTitle] {
                        if !collectionView.isEditing {
                            if !isfilteredEventUsable! {
                                print("eventsInSection")
                                event = eventsInSection[indexPath.row]
                                print("sectionedEvents: ", sectionedEvents)
                                print("event: ", event)
                                showEventDetails(event)
                            } else {
                                print("filteredEvents")
                                event = filteredEvents[indexPath.row]
                                print("sectionedEvents: ", sectionedEvents)
                                print("event: ", event)
                                showEventDetails(event)
                            }
                        } else {
                            multiSelection.append(indexPath)
                            print("multiSelection: \(multiSelection)")
                            
                        }
                    }
                    
                } else { // 유저가 비용계산기를 누른 상태 (달러 사인이 보여야 함)
                    
                }
                
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView.tag == 1 { // dateCollectionView
            
        } else { // tripCollectionView
            
            if let cell = collectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
                //cell.isSelected = false
                collectionView.reloadItems(at: [indexPath]) // 셀 업데이트
            }
            
            if collectionView.isEditing {
                if let index = multiSelection.firstIndex(of: indexPath) {
                    multiSelection.remove(at: index)
                    print("multiSelection after deselection: \(multiSelection)")
                }
            }
            
        }
    }
    
    func updateFilteredEvents(indexRow: Int) {
        
        let calendar = Calendar.current
        
        if indexRow == 0 {
            
            DispatchQueue.main.async {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/d (E)"
                
                let sortedKeysEventCountsByDate = self.eventCountsByDate.keys.sorted { (dateString1, dateString2) -> Bool in
                    if let date1 = dateFormatter.date(from: dateString1),
                       let date2 = dateFormatter.date(from: dateString2) {
                        return date1 < date2
                    }
                    return false
                }
                //print("sortedKeysEventCountsByDate: ", sortedKeysEventCountsByDate)
                
                self.keysArray = sortedKeysEventCountsByDate // 8.1 , 8.2, ...
                //self.valuesArray = sortedValuesEventCountsByDate // 1, 1, 10..

                //self.keysArray = self.eventCountsByDate.keys.sorted() //8.1, 8.2...
                self.valuesArray = Array(self.eventCountsByDate.values) // 2, 1, 6
                //print("updateFilteredEvents keysArray: ", self.keysArray)
                var startIndex = 0
                var endIndex = 0
                
                for i in 0..<self.keysArray.count {
                    let sectionTitle = self.keysArray[i]
                    let rowCount = self.eventCountsByDate[sectionTitle]
                    
                    startIndex = endIndex
                    endIndex = endIndex + rowCount!
                    
                    let extractedEvents = Array(self.events[startIndex..<endIndex])
                    self.sectionedEvents[sectionTitle] = extractedEvents
                    
                    // endIndex는 범위의 끝 다음 인덱스를 나타내므로 6
                }

                // 섹션 타이틀을 얻어옴
                
                self.tripCollectionView.reloadData()
            }
            
        } else {
            DispatchQueue.main.async {
                if let startDate = calendar.date(
                    byAdding: .day,
                    value: self.dateCollectionViewIndex!,
                    to: self.tripStartDate!) {
                    //print("dateCollectionViewIndex! ", self.dateCollectionViewIndex!)
                    print("startDate ", startDate)
                    print("self.tripStartDate ", self.tripStartDate)
                    
                    self.filteredEvents = self.events.filter { event in
                        print("event.startDate", event.startDate)
                        return Calendar.current.isDate(event.startDate, inSameDayAs: startDate) ||
                        (event.startDate <= startDate && event.endDate >= startDate)
                    }
                    print("self.filteredEvents.count", self.filteredEvents.count)
                    
                } else {
                    // Handle case where tripStartDate is nil
                    self.filteredEvents = []
                    
                }
                self.tripCollectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView.tag == 1 {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TripViewCollectionViewCell", for: indexPath) as! TripViewCollectionViewCell
            
            cell.tripDateLabel.clipsToBounds = true
            
            if indexPath.row == 0 {
                isfilteredEventUsable = false
                cell.tripDateLabel.text = "All"
                
                if isViewDidLoad == true {
                    cell.clickCount = 1
                    //print("클릭 클릭!")
                }
                
            } else {
                
                let components = timeInterval[indexPath.row - 1].components(separatedBy: " ")
                if let dateSubstring = components.first { //dateSubstring: 8.1로 이름 입력
                    cell.tripDateLabel.text = dateSubstring
                }
            }
            
            if let dateString = cell.tripDateLabel.text {
                //print("dateString: \(dateString)")
                let components = dateString.components(separatedBy: "/")
                if components.count == 2 {
                    let string0 = components[0] // 날짜 중 '월'
                    let string1 = components[1] // 날짜 중 '일'
                    if let month = Int(string0), let day = Int(string1) {
                        let color = day % 9
                        let tintColor = colorSelection(color)
                        cell.circleImageView.tintColor = UIColor(hex: tintColor)
                    }
                } else {
                    let tintColor = colorSelection(-1)
                    cell.circleImageView.tintColor = UIColor(hex: tintColor)
                }
                
            }
            
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tripCollectionViewCell", for: indexPath) as! tripCollectionViewCell
            //var contentConfiguration = UIListContentConfiguration.valueCell()
            //cell.contentConfiguration = contentConfiguration
            cell.accessories = [
                .multiselect(displayed: .whenEditing)
            ]
            cell.backgroundColor = .clear
            
            keysArray = eventCountsByDate.keys.sorted()
            valuesArray = Array(eventCountsByDate.values)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            
            let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
                if let date1 = dateFormatter.date(from: dateString1),
                   let date2 = dateFormatter.date(from: dateString2) {
                    return date1 < date2
                }
                return false
            }
            
            //print("sortedArray: ", sortedArray)
            let sectionTitle = sortedArray[indexPath.section]
            //let sectionTitle = keysArray[indexPath.section]
            //print("sectionTitle: ", sectionTitle)

            let sectionItemCount = valuesArray[indexPath.section]
            
            let event: EKEvent
            if let eventsInSection = sectionedEvents[sectionTitle] {
                if !isfilteredEventUsable! { //print("eventsInSection")
                    //print("sectionedEvents: ", sectionedEvents.count)
                    //print("eventsInSection: ", eventsInSection)
                    event = eventsInSection[indexPath.row]
                    cell.dateLabel.text = sectionTitle
                    cell.scheduleUID = event.eventIdentifier
                    cell.tripStartDate = event.startDate
                    cell.tripEndDate = event.endDate
                    
                } else { //print("filteredEvents")
                    //print("filteredEvents: ", filteredEvents)
                    event = filteredEvents[indexPath.row]
                    cell.dateLabel.text = timeInterval[indexRow - 1]
                    cell.scheduleUID = event.eventIdentifier
                    //print("filteredEvents event.eventIdentifier: \(event.eventIdentifier)")
                    //print("--------------------")
                    cell.tripStartDate = event.startDate
                    cell.tripEndDate = event.endDate
                    
                }
                
                cell.layer.cornerRadius = 8
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1)
                cell.layer.shadowRadius = 4
                cell.layer.shadowOpacity = 0.3
                //cell.layer.borderWidth = 1
                //cell.layer.borderColor = UIColor.gray.cgColor
                
                cell.tripTitleLabel.text = event.title
//                if let structuredLocationTitle = event.structuredLocation?.title {
//                    cell.tripSubTitleLabel.text = structuredLocationTitle
//                } else {
//                    print("event.title: ", event.title)
//                    print("event.location: ", event.location)
//                    cell.tripSubTitleLabel.text = ""
//                }
                
                if let structuredLocationTitle = event.structuredLocation?.title {
                    cell.tripSubTitleLabel.text = event.structuredLocation?.title
                } else {
                    cell.tripSubTitleLabel.text = " "
                }
                
                if !isDollarSignEnable { // 비용계산기 꺼짐
                    cell.dollarSignButton.isEnabled = false
                    cell.dollarSignButton.isHidden = true
                    cell.indexImageView.isHidden = false
                    cell.label.isHidden = false
                    
                    cell.isPickerViewSelected = false
                    cell.removeObserver()
                    cell.expenseView.transform = cell.startTransform
                    
                } else { // 비용계산기 켜짐
                    cell.dollarSignButton.isEnabled = true
                    cell.dollarSignButton.isHidden = false
                    cell.indexImageView.isHidden = true
                    cell.label.isHidden = true
                    
                    
                    NSLayoutConstraint.activate([
                        cell.dollarSignButton.heightAnchor.constraint(equalToConstant: cell.frame.height),
                        cell.dollarSignButton.widthAnchor.constraint(equalToConstant: cell.dollarSignButton.frame.width + 50)
                    ])
                    
                }
                
                cell.indexImageView.image = UIImage(systemName: "circle")
                cell.indexImageView.tintColor = UIColor(named: "reversed Color")
                
                cell.label.text = "\(indexPath.row + 1)"
                
                if let startDate = event.startDate, let endDate = event.endDate {
                    let currentTimeZone = TimeZone.current.identifier
                    
                    let dateFormatter0 = DateFormatter()
                    dateFormatter0.dateFormat = "HH:mm"
                    dateFormatter0.timeZone = TimeZone(identifier: currentTimeZone)
                    
                    let startTime0 = dateFormatter0.string(from: startDate)
                    let endTime0 = dateFormatter0.string(from: endDate)
                    //----------------------------------
                    let dateFormatter1 = DateFormatter()
                    dateFormatter1.dateFormat = "M/d (E)"
                    dateFormatter1.timeZone = TimeZone(identifier: currentTimeZone)
                    
                    let startTime1 = dateFormatter1.string(from: startDate)
                    let endTime1 = dateFormatter1.string(from: endDate)
                    //----------------------------------
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateFormat = "M/d"
                    dateFormatter2.timeZone = TimeZone(identifier: currentTimeZone)
                    
                    let startTime2 = dateFormatter2.string(from: startDate)
                    let endTime2 = dateFormatter2.string(from: endDate)
                    
                    let timeLabelText: String
                    let timeLabelFont: UIFont
                    var secondText: String
                    
                    if "\(startTime0)" == "00:00" && "\(endTime0)" == "23:59" {
                        // 시작 시간과 종료시간이 all day로 설정된 경우
                        if startTime1 != endTime1 { // 2일 이상 걸쳐있는 날짜
                            timeLabelText = "\(startTime2)\n\(endTime2)"
                            timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                            secondText = endTime2
                        } else { // 같은 날짜
                            timeLabelText = "All Day".localized()
                            timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .regular) // Set a default font
                            secondText = ""
                        }
                        
                    } else if startTime1 != endTime1 { // 2일 이상 걸쳐있는 날짜
                        //print("startTime1", startTime1)
                        //print("endTime1", endTime1)
                        if startTime2 == clickedCellTitle {
                            print("if startTime2 == clickedCellTitle {")
                            print("startTime2", startTime2)
                            print("startTime0", startTime0)
                            timeLabelText = "\(startTime0)\n24:00"
                            timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .light)
                            secondText = "24:00"
                        } else if endTime2 == clickedCellTitle {
                            print("else if endTime2 == clickedCellTitle")
                            print("endTime2", endTime2)
                            print("endTime0", endTime0)
                            timeLabelText = "00:00\n\(endTime0)"
                            timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .light)
                            secondText = endTime0
                        } else if clickedCellTitle == "All" { // 전체 일정
                            if endTime0 != "00:00" {
                                print(" if endTime0 != 24:00 {")
                                timeLabelText = "\(startTime2)\n\(endTime2)"
                                timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                                secondText = endTime2
                                
                            } else { // endTime0 == "24:00"
                                print("!! if endTime0 != 24:00 {")
                                timeLabelText = "\(startTime0)\n24:00"
                                timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .light)
                                secondText = "24:00"
                            }
                        } else {
                            print("} else {")
                            timeLabelText = "All Day".localized()
                            timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .regular) // Set a default font
                            secondText = ""
                        }
                        
                    } else {
                        // Same day with non-full day event
                        timeLabelText = "\(startTime0)\n\(endTime0)"
                        timeLabelFont = UIFont.systemFont(ofSize: 12, weight: .light)
                        secondText = endTime0
                    }
                    
                    let attributedString = NSMutableAttributedString(string: timeLabelText)
                    let rangeOfSecondLine = (timeLabelText as NSString).range(of: secondText)
                    
                    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .light), range: rangeOfSecondLine)
                    
                    cell.timeLabel.attributedText = attributedString
                    
                }
                
                if collectionView.isEditing {
                    cell.timeLabel.alpha = 0
                } else {
                    cell.timeLabel.alpha = 1
                }
                
                if let dateString = cell.dateLabel.text {
                    let color = returnColor(dateString)
                    let tintColor = colorSelection(color)
                    cell.tagColorView.backgroundColor = UIColor(hex: tintColor)
                    
                }
                
            }
            return cell

        }
        
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //updateVisibleCells()
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        //updateVisibleCells()
    }
    
    @objc private func updateVisibleCells() {
        
        guard isDollarSignEnable else {
            return
        }
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "hand.point.up.left.fill")
        imageAttachment.image = imageAttachment.image?.withTintColor(UIColor(named: "gray Color")!)
        let imageString = NSAttributedString(attachment: imageAttachment)
        
        // 문자열 추가
        let textString = NSAttributedString(string: "")

        // 두 NSAttributedString을 결합
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(imageString)
        mutableAttributedString.append(textString)
        
        DispatchQueue.main.async {
            
            let indexPaths = self.tripCollectionView.indexPathsForVisibleItems // 보이는 셀에만 해당됨
            
            for indexPath in indexPaths {
                if let cell = self.tripCollectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
                    
                    cell.dollarSignButton.isUserInteractionEnabled = true
                                      
                    let totalMoneyForSchedule = self.totalMoneyForSchedule(scheduleUID: cell.scheduleUID!)
                    
                    if totalMoneyForSchedule != [] {
                        if let money = totalMoneyForSchedule.first?.money,
                           let currecncy = totalMoneyForSchedule.first?.currecncy {
                            
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                            ]
                            
                            let attributedString = NSMutableAttributedString(string: "\(currecncy )\n\(Int(money))", attributes: attributes)
                            
                            let rangeOfSecondLine = ("\(currecncy)\n\(Int(money))" as NSString).range(of: "\(Int(money))")
                            
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: rangeOfSecondLine)
                            
                            cell.dollarSignButton.setAttributedTitle(attributedString, for: .normal)
                            cell.menuButton.setTitle("\(currecncy)", for: .normal)
                            cell.expenseTextField.text = "\(Int(money))"
                            
                        }
                    } else {
                        
                        cell.dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
                        cell.menuButton.setTitle("Set Currecncy".localized(), for: .normal)
                        cell.expenseTextField.text = ""
                    }

                }
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        updateVisibleCells()
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedEvent = filteredEvents.remove(at: sourceIndexPath.row)
        filteredEvents.insert(movedEvent, at: destinationIndexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if collectionView.tag == 1 {
            return CGSize(width: 0, height: 0)
        } else {
            
            return CGSize(width: collectionView.bounds.width - 80, height: 50)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView.tag == 2 {
            return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0) // Adjust the left inset as needed
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView.tag == 1 {
            return CGSize(width: 60, height: 40)
        } else {
            return CGSize(width: 380, height: 60)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView.tag == 1 {
            return 1
        } else {
            return 10
        }
    }
    
    
    // 헤더 뷰를 반환하는 메서드
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if collectionView.tag == 1 {
            
            return UICollectionReusableView()
            
        } else {
            
            let headerView = tripCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "tripCollectionHeaderView", for: indexPath) as! tripCollectionHeaderView
            
            if !isDollarSignEnable {
                headerView.expenseTextView.isHidden = true
            } else {
                headerView.expenseTextView.isHidden = false
            }
            
            let currencyExpenses = expenseDataForSection(indexPath.section) // 헤더에 섹션별 화폐 단위 및 비용 표시용
            //print("currencyExpenses: \(currencyExpenses)")
            
            let sortedCurrencies = currencyExpenses.keys.sorted() // 정렬된 키 배열
            
            var expenseLabelText = ""
            for (index, currency) in sortedCurrencies.enumerated() {
                if let money = currencyExpenses[currency] {
                    // currency와 money를 사용하여 expenseLabelText를 구성
                    expenseLabelText.append("\(Int(money)) \(currency)")
                    
                    if index < sortedCurrencies.count - 1 {
                        expenseLabelText.append("\n")
                    }
                }
            }
            
            headerView.expenseLabelText = expenseLabelText
            headerView.configure()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            
            if !isfilteredEventUsable! {

                let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
                    if let date1 = dateFormatter.date(from: dateString1),
                       let date2 = dateFormatter.date(from: dateString2) {
                        return date1 < date2
                    }
                    return false
                }
                headerView.label.text = sortedArray[indexPath.section]
                //headerView.label.text = keysArray[indexPath.section]
                //print("sortedArray: ", sortedArray)
            } else {
                headerView.label.text = timeInterval[indexRow - 1]
            }
            //self.view.sendSubviewToBack(headerView)
            //self.tripCollectionView.sendSubviewToBack(headerView)
            
            return headerView
        }
        
    }
    
    func expenseDataForSection(_ section: Int) -> [String: Double] {
        
        let numberOfItems = tripCollectionView.numberOfItems(inSection: section)
        var currencyExpenses: [String: Double] = [:]
        
        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: section)
            
            //if let cell = tripCollectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            
            let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
                if let date1 = dateFormatter.date(from: dateString1),
                   let date2 = dateFormatter.date(from: dateString2) {
                    return date1 < date2
                }
                return false
            }
            
            let sectionTitle = sortedArray[indexPath.section]
            
            //let sectionTitle = keysArray[indexPath.section] // 문제 없읍
            let event: EKEvent
            
            if let eventsInSection = sectionedEvents[sectionTitle] { // 문제 없읍
                
                if !isfilteredEventUsable! { // eventsInSection
                    //print("eventsInSection")
                    event = eventsInSection[indexPath.row]
                    
                    let sectionExpenses = tripForExpense.filter { expense in
                        expense.scheduleUID == event.eventIdentifier
                    }
                    //print("sectionExpenses: \(sectionExpenses)")
                    
                    for expense in sectionExpenses {
                        if let currency = expense.currecncy, let money = expense.money {
                            if let currentTotal = currencyExpenses[currency] {
                                currencyExpenses[currency] = currentTotal + money
                            } else {
                                currencyExpenses[currency] = money
                            }
                        }
                    }
                    
                } else { // filteredEvents
                    //print("filteredEvents")
                    event = filteredEvents[indexPath.row]
                    
                    let sectionExpenses = tripForExpense.filter { expense in
                        expense.scheduleUID == event.eventIdentifier
                    }
                    //print("sectionExpenses: \(sectionExpenses)")
                    
                    if let expense = sectionExpenses.first {
                        if let currency = expense.currecncy, let money = expense.money {
                            if let currentTotal = currencyExpenses[currency] {
                                currencyExpenses[currency] = currentTotal + money
                            } else {
                                currencyExpenses[currency] = money
                            }
                        }
                    }
                    
                }
                
            }
            
            //}
        }
        
        return currencyExpenses
    }
    
    
}


extension TripViewController : UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        print("drag>", indexPath)
        return []
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        //print("drop>", coordinator.destinationIndexPath)
        //[UIDragItem(itemProvider: NSItemProvider())]
        if collectionView.tag == 2 {
            var destinationIndexPath: IndexPath
            if let indexPath = coordinator.destinationIndexPath {
                destinationIndexPath = indexPath
            } else {
                let row = collectionView.numberOfItems(inSection: 0)
                destinationIndexPath = IndexPath(item: row - 1, section: 0)
            }
            
            if coordinator.proposal.operation == .move {
                reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        //        if collectionView.hasActiveDrag {
        //            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        //        }
        //        return UICollectionViewDropProposal(operation: .forbidden)
        guard collectionView.hasActiveDrag else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        
        if let item = coordinator.items.first,
           let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates({
                
                let temp = filteredEvents[sourceIndexPath.item]
                filteredEvents.remove(at: sourceIndexPath.item)
                filteredEvents.insert(temp, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
                
            }) { done in
                
            }
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
    
}

extension TripViewController : MKMapViewDelegate {

    func addRouteToMap(transportType: Int) { //polyline .automobile .walking, .transit
        
        mapView.removeOverlays(mapView.overlays)
        
        var coordinateArray : [CLLocationCoordinate2D] = []
        
        keysArray = self.eventCountsByDate.keys.sorted() //8.1, 8.2...
        valuesArray = Array(self.eventCountsByDate.values) // 2, 1, 6
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d (E)"
        
        let sortedArray = keysArray.sorted { (dateString1, dateString2) -> Bool in
            if let date1 = dateFormatter.date(from: dateString1),
               let date2 = dateFormatter.date(from: dateString2) {
                return date1 < date2
            }
            return false
        }
        
        if !isfilteredEventUsable! {
            
            for dateKey in keysArray {
                guard let events = sectionedEvents[dateKey] else {
                    continue // Skip if there are no events for this date
                }
                //print("events: \(events)") // 섹션 별로 1번씩 반복됨
                for event in events {
                    if let eventLocation = event.structuredLocation,
                       let geoLocation = eventLocation.geoLocation {
                        let coordinate = geoLocation.coordinate
                        
                        coordinateArray.append(coordinate)
                    }
                }
            }
        } else {
            for event in filteredEvents {
                if let eventLocation = event.structuredLocation,
                   let geoLocation = eventLocation.geoLocation {
                    let coordinate = geoLocation.coordinate
                    
                    coordinateArray.append(coordinate)
                    
                }
            }
        }
        
        if coordinateArray.isEmpty {
            timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
            timeLabel.text = "ETT -- min".localized()
            return
        }
        
        let (minLatitude, maxLatitude, minLongitude, maxLongitude) = calculateBoundingCoordinates(from: coordinateArray)
        
        let centerLatitude = (maxLatitude + minLatitude) / 2
        let centerLongitude = (maxLongitude + minLongitude) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        
        //let span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude, longitudeDelta: maxLongitude - minLongitude)
        
        //let screenWidth = view.window?.windowScene?.screen.bounds.width
        
        let span: MKCoordinateSpan
        if maxLatitude - minLatitude > 100 || maxLongitude - minLongitude > 100 {
            print("> 100 ||")

            span = MKCoordinateSpan(latitudeDelta: maxLatitude, longitudeDelta: maxLongitude)
            let centerCoordinate1 = CLLocationCoordinate2D(latitude: coordinateArray.first?.latitude ?? centerLatitude, longitude: coordinateArray.first?.longitude ?? centerLongitude)

            mapView.region = MKCoordinateRegion(center: centerCoordinate1, span: span)
            
        } else if (10 < maxLongitude - minLongitude) && (maxLongitude - minLongitude < 50) || (10 < maxLatitude - minLatitude) && (maxLatitude - minLatitude < 50) {
            
            print("10 < && < 50")
            span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude + 3, longitudeDelta: maxLongitude - minLongitude + 3)
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
            
        } else if (5 < maxLongitude - minLongitude) && (maxLongitude - minLongitude < 10) || (5 < maxLatitude - minLatitude) && (maxLatitude - minLatitude < 10) {
            
            print("10 < && < 50")
            span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude + 1, longitudeDelta: maxLongitude - minLongitude + 1)
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
            
        } else if (1 < maxLongitude - minLongitude) && (maxLongitude - minLongitude < 5) || (1 < maxLatitude - minLatitude) && (maxLatitude - minLatitude < 5) {
            
            print("1 < && < 5")
            span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude + 0.5, longitudeDelta: maxLongitude - minLongitude + 0.5)
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
            
        } else if maxLatitude - minLatitude < 1 && maxLongitude - minLongitude < 1 {
            
            print("< 1 &&")
            span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude + 0.05, longitudeDelta: maxLongitude - minLongitude + 0.05)
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
            
        } else { // 50 과 100 사이
            
            print("50 과 100 사이")
            span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude + 5, longitudeDelta: maxLongitude - minLongitude + 5)
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
        }
        
        //let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        
        
        switch transportType {
        case 0: //polyline
            let polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
            mapView.addOverlay(polyline)
            
            timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
            timeLabel.text = "ETT -- min".localized()
            
        case 1: //automobile
            
            for i in 0..<coordinateArray.count {
                if i+1 != coordinateArray.count {
                    let sourcePlacemark = MKPlacemark(coordinate: coordinateArray[i])
                    let destinationPlacemark = MKPlacemark(coordinate: coordinateArray[i+1])
                    
                    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    
                    let directionRequest = MKDirections.Request()
                    directionRequest.source = sourceMapItem
                    directionRequest.destination = destinationMapItem
                    directionRequest.transportType = .automobile
                    
                    let directions = MKDirections(request: directionRequest)
                    directions.calculate { (response, error) in
                        guard let route = response?.routes.first else {
                            return
                        }
                        let expectedTravelTimeInSeconds = route.expectedTravelTime
                        let expectedTravelTimeInMinutes = expectedTravelTimeInSeconds / 60
                        self.expectedTravelTime += expectedTravelTimeInMinutes
                        self.mapView.addOverlay(route.polyline)
                        print("self.expectedTravelTime: \(self.expectedTravelTime)")
                        
                        if self.expectedTravelTime != 0 {
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                            ]
                            let minutes = Int(self.expectedTravelTime)
                            let hours = minutes / 60
                            let remainingMinutes = minutes % 60

                            let attributedString: NSMutableAttributedString
                            let text: String

                            if hours > 0 {
                                if remainingMinutes > 0 {
                                    text = String(format: "ETT %d hour %d min".localized(with: [hours, remainingMinutes]), hours, remainingMinutes)
                                                  
                                } else {
                                    text = String(format: "ETT %d hour".localized(with: [hours]), hours)
                                }
                            } else {
                                text = String(format: "ETT %d min".localized(with: [remainingMinutes]), remainingMinutes)
                            }

                            attributedString = NSMutableAttributedString(string: text, attributes: attributes)
                            let range = NSRange(location: 0, length: text.count)
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: range)

                            self.timeLabel.attributedText = attributedString
                            
                        } else {
                            self.timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
                            self.timeLabel.text = "ETT -- min".localized()
                        }
                    }
                }
            }
            
        case 2: //transit
            
            for i in 0..<coordinateArray.count {
                if i+1 != coordinateArray.count {
                    let sourcePlacemark = MKPlacemark(coordinate: coordinateArray[i])
                    let destinationPlacemark = MKPlacemark(coordinate: coordinateArray[i+1])
                    
                    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    
                    let directionRequest = MKDirections.Request()
                    directionRequest.source = sourceMapItem
                    directionRequest.destination = destinationMapItem
                    directionRequest.transportType = .transit
                    
                    let directions = MKDirections(request: directionRequest)
                    directions.calculateETA { etaResponse, error in
                        
                        guard let route = etaResponse?.expectedTravelTime else {
                            print("errer: \(error)")
                            self.timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
                            self.timeLabel.text = "ETT -- min".localized()
                            return
                        }
                        let expectedTravelTimeInMinutes = route/60
                        self.expectedTravelTime += expectedTravelTimeInMinutes
                        
                        if self.expectedTravelTime != 0 {
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                            ]
                            let minutes = Int(self.expectedTravelTime)
                            let hours = minutes / 60
                            let remainingMinutes = minutes % 60
                            print("minutes", minutes)
                            print("hours", hours)
                            print("remainingMinutes", remainingMinutes)
                            let attributedString: NSMutableAttributedString
                            let text: String

                            if hours > 0 {
                                if remainingMinutes > 0 {
                                    text = String(format: "ETT %d hour %d min".localized(with: [hours, remainingMinutes]), hours, remainingMinutes)
                                                  
                                } else {
                                    text = String(format: "ETT %d hour".localized(with: [hours]), hours)
                                }
                            } else {
                                text = String(format: "ETT %d min".localized(with: [remainingMinutes]), remainingMinutes)
                            }

                            attributedString = NSMutableAttributedString(string: text, attributes: attributes)
                            let range = NSRange(location: 0, length: text.count)
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: range)

                            self.timeLabel.attributedText = attributedString
                            
                        } else {
                            self.timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
                            self.timeLabel.text = "ETT -- min".localized()
                        }
                    }
                }
            }
        case 3: //walking
            
            for i in 0..<coordinateArray.count {
                if i+1 != coordinateArray.count {
                    let sourcePlacemark = MKPlacemark(coordinate: coordinateArray[i])
                    let destinationPlacemark = MKPlacemark(coordinate: coordinateArray[i+1])
                    
                    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    
                    let directionRequest = MKDirections.Request()
                    directionRequest.source = sourceMapItem
                    directionRequest.destination = destinationMapItem
                    directionRequest.transportType = .walking
                    
                    let directions = MKDirections(request: directionRequest)
                    directions.calculate { (response, error) in
                        guard let route = response?.routes.first else {
                            return
                        }
                        let expectedTravelTimeInSeconds = route.expectedTravelTime
                        let expectedTravelTimeInMinutes = expectedTravelTimeInSeconds / 60
                        self.expectedTravelTime += expectedTravelTimeInMinutes
                        self.mapView.addOverlay(route.polyline)
                        
                        self.timeLabel.text = "ETT -- min".localized()
                        
                        if self.expectedTravelTime != 0 {
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                            ]
                            let minutes = Int(self.expectedTravelTime)
                            let hours = minutes / 60
                            let remainingMinutes = minutes % 60
                            print("minutes", minutes)
                            print("hours", hours)
                            print("remainingMinutes", remainingMinutes)
                            let attributedString: NSMutableAttributedString
                            let text: String

                            if hours > 0 {
                                if remainingMinutes > 0 {
                                    text = String(format: "ETT %d hour %d min".localized(with: [hours, remainingMinutes]), hours, remainingMinutes)
                                                  
                                } else {
                                    text = String(format: "ETT %d hour".localized(with: [hours]), hours)
                                }
                            } else {
                                text = String(format: "ETT %d min".localized(with: [remainingMinutes]), remainingMinutes)
                            }

                            attributedString = NSMutableAttributedString(string: text, attributes: attributes)
                            let range = NSRange(location: 0, length: text.count)
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: range)

                            self.timeLabel.attributedText = attributedString
                            
                        } else {
                            self.timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
                            self.timeLabel.text = "ETT -- min".localized()
                        }
                    }
                }
            }
        default: //polyline
            let polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
            mapView.addOverlay(polyline)
            timeLabel.font = .systemFont(ofSize: 12, weight: .ultraLight)
            timeLabel.text = "ETT -- min".localized()
        }
        
        
    }
    
    // MKMapViewDelegate method to customize overlay rendering
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(hex: "E3582D")//UIColor(hex: tripTagColor!)
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func calculateBoundingCoordinates(from coordinates: [CLLocationCoordinate2D]) -> (CLLocationDegrees, CLLocationDegrees, CLLocationDegrees, CLLocationDegrees) {
        var minLatitude = coordinates.first!.latitude
        var maxLatitude = coordinates.first!.latitude
        var minLongitude = coordinates.first!.longitude
        var maxLongitude = coordinates.first!.longitude
        
        for coordinate in coordinates {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }
        
        return (minLatitude, maxLatitude, minLongitude, maxLongitude)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotation else {
            return nil
        }
        
        let identifier = "FirstMKAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? FirstMKAnnotationView
        
        if annotationView == nil {
            annotationView = FirstMKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            annotationView?.contentMode = .scaleAspectFit
            
            //            let miniButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            //            miniButton.setImage(UIImage(named: "circle"), for: .normal)
            //            miniButton.tintColor = .blue
            //            annotationView?.rightCalloutAccessoryView = miniButton
            
        } else {
            annotationView?.annotation = annotation
        }
        
        var image = UIImage(systemName: "circle.fill")
        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContext(size)
        
        var color = annotation.color! % 9
        
        image = image?.withTintColor(UIColor(hex: colorSelection(color))!)
        
        // 이미지 크기 조절
        let resizedImage = UIGraphicsImageRenderer(size: size).image { _ in
            image?.draw(in: CGRect(origin: .zero, size: size))
        }
        
        annotationView?.image = resizedImage
        
        annotationView?.numberlabel.text = "\(annotation.labelNumber! + 1)"
        annotationView?.titelLabel.text = "\(annotation.title!)"
        annotationView?.locationLabel.text = "\(annotation.location ?? "")"
        
        // 이미지 위치 조정
        annotationView?.centerOffset = CGPoint(x: 0, y: 0) // 원하는 만큼 조정 가능
        
        return annotationView
    }
    
    func addCustomPin(color: Int, coordinate: CLLocationCoordinate2D, labelNumber: Int, title: String, location: String, ekEvent: EKEvent) {
        let pin = CustomAnnotation(color: color, coordinate: coordinate, labelNumber: labelNumber, title: title, location: location, ekEvent: ekEvent)
        mapView.addAnnotation(pin)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //print("view: \(view)")
        
        
        if let customAnnotation = view.annotation as? CustomAnnotation {
            if let event = customAnnotation.ekEvent {
                
                showEventDetails(event)
                
                //sleep(UInt32(0.1))
                isAnnotationClicked = true
                NotificationCenter.default.post(name: Notification.Name("showMap"), object: nil)
            }
        }
    }
    
}

extension TripViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func shareButtonPressed() {
        
        let fullSizeImage = captureCollectionViewInSectionsWithInsets(collectionView: tripCollectionView, inset: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
        
        //UIImageWriteToSavedPhotosAlbum(fullSizeImage!,self, nil, nil)
        
        let excludedTypes: Array<UIActivity.ActivityType> = [
//            .airDrop,
//            .assignToContact,
//            .copyToPasteboard,
//            .mail,
//            .markupAsPDF,
//            .message,
//            .openInIBooks,
//            .postToFacebook,
//            .postToFlickr,
//            .postToTencentWeibo,
//            .postToTwitter,
//            .postToVimeo,
//            .postToWeibo,
//            .print,
//            .saveToCameraRoll
            ]
        
        let imageName = tripTitle
        
        let activityViewController = UIActivityViewController(activityItems: [fullSizeImage as Any, imageName as Any], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                if completed {
                    // 사용자가 이미지를 성공적으로 공유했을 때
                    if activityType == UIActivity.ActivityType.saveToCameraRoll {
                        // 이미지를 사진첩에 저장한 경우
                        self.alert(title: "Saved".localized(), message: "The itinerary has been saved to your photo library".localized(), actionTitle: "OK".localized())
                    }
                } else {
                    // 사용자가 취소한 경우 또는 에러가 발생한 경우
                    if let error = activityError {
                        print("Error during sharing: \(error.localizedDescription)")
                    }
                }
            }
   
        activityViewController.excludedActivityTypes = excludedTypes
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = self.view.bounds
        }
        
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    func showAlertForPhotoLibraryPermission() {
        let alert = UIAlertController(title: "Photo Library Access Required".localized(), message: "Access to your photo library is required to save photos. Please enable the permission in Settings".localized(), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Go to Settings".localized(), style: .default) { (action) in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func captureCollectionViewInSectionsWithInsets(collectionView: UICollectionView, inset: UIEdgeInsets) -> UIImage? {
        // 컬렉션 뷰 크기와 콘텐츠 크기 가져오기
        let collectionViewSize = collectionView.bounds.size
        let contentSize = collectionView.contentSize

        // 컨텐츠 크기에 여백 적용
        let contentSizeWithInsets = CGSize(width: contentSize.width, height: contentSize.height + inset.top + inset.bottom)

        // 한 번에 찍을 수 있는 화면 크기 계산 (컬렉션 뷰 크기와 동일하거나 작을 수 있습니다)
        let screenSize = CGSize(width: collectionViewSize.width, height: collectionViewSize.height)

        // 총 페이지 수 계산
        let totalPages = Int(ceil(contentSizeWithInsets.height / screenSize.height))

        // 컬렉션 뷰에 여백 적용
        collectionView.contentInset = inset

        // 전체 컬렉션 뷰 스크린샷을 합칠 이미지 컨텍스트 생성
        UIGraphicsBeginImageContextWithOptions(contentSizeWithInsets, false, UIScreen.main.scale)

        // 페이지 별로 스크롤하면서 스크린샷 찍고 이미지 컨텍스트에 합치기
        for page in 0 ..< totalPages {
            let yOffset = CGFloat(page) * screenSize.height
            collectionView.contentOffset = CGPoint(x: 0, y: yOffset)

            // 스크린샷 찍기
            collectionView.layer.render(in: UIGraphicsGetCurrentContext()!)
        }

        // 전체 컬렉션 뷰 스크린샷 가져오기
        let fullSizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // 초기 위치로 스크롤 복원
        collectionView.contentOffset = .zero
        collectionView.contentInset = .zero

        return fullSizeImage
    }

    func requestPhotoLibraryAccess() {
        DispatchQueue.main.async {
            
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: { status in
                switch status {
                case .authorized:
                    // 사용자가 권한을 허용한 경우, 여기에서 사진첩 접근 코드를 실행할 수 있습니다.
                    print("authorized")
                    DispatchQueue.main.async {
                        self.shareButtonPressed()
                    }
                case .denied, .restricted:
                    // 사용자가 권한을 거부하거나 제한한 경우에 대한 처리를 추가합니다.
                    print("denied, restricted")
                    self.alert(title: "status", message: "", actionTitle: "OK".localized())
                    
                case .notDetermined:
                    // 사용자가 아직 선택하지 않은 경우, 권한 요청이 대기 중이므로 아무것도 하지 않습니다.
                    print("notDetermined")
                    DispatchQueue.main.async {
                        self.requestPhotoLibraryAccess()
                    }
                    
                    
                case .limited:
                    print("limited")
                @unknown default:
                    break
                }
            })
        }
    }
    
}
