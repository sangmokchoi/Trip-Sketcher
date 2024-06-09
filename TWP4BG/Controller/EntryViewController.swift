//
//  EntryViewController.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/10.
//

import UIKit
import EventKit
import EventKitUI
import MapKit
import CoreLocation
import RealmSwift

class EntryViewController: UIViewController, MKLocalSearchCompleterDelegate {
    
    var index: Int?
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    @IBOutlet weak var locationSearchbar: UISearchBar!
    
    @IBOutlet weak var locationSearchButton: UIButton!
    @IBOutlet weak var locationTableView: UITableView!
    
    @IBOutlet weak var calendarLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    
    let searchCompleter = MKLocalSearchCompleter()
    let eventStore = EKEventStore()
    var newTrip: [Trip] = []
    
    var tripTitle: String?
    var editedTripTitle: String?
    
    var tripSubTitle: String?
    var tripPlace: String?
    
    var tripStartDate: Date?
    var editedTripStartDate: Date?
    
    var tripEndDate: Date?
    var editedTripEndDate: Date?
    
    var tripTagColor: String?
    var editedTripTagColor: String?
    
    var tripPlaceList: [EKEvent]?
    
    // 뷰 컨트롤러 속성으로 검색 결과를 저장할 배열 선언
    var searchResults: [MKMapItem] = []
    // location manager
    var locationManager: CLLocationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    
    var typedSearchText = ""
    
    lazy var leftButton: UIButton = {
        let button = UIButton(type: .system)
        let safeArea = view.safeAreaInsets
        
        let Xwidth : CGFloat = view.bounds.width
        let Yheight : CGFloat = view.bounds.height
        print("Xwidth: \(Xwidth)")
        print("Yheight: \(Yheight)")
        
        let width : CGFloat = 60
        let height : CGFloat = 60
        
        button.frame = CGRect(x: width/4, y: 0, width: width, height: height)
        button.setTitle("Cancel".localized(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.tintColor = .systemBlue
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.leftButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var rightButton: UIButton = {
        let button = UIButton(type: .system)
        let safeArea = view.safeAreaInsets
        print("safeArea: \(safeArea.right)")
        
        let Xwidth : CGFloat = view.bounds.maxX
        let Yheight : CGFloat = view.bounds.height
        print("Xwidth: \(Xwidth)")
        print("Yheight: \(Yheight)")
        
        let width : CGFloat = 60
        let height : CGFloat = 60

        button.frame = CGRect(x: Xwidth - width, y: 0, width: width, height: height)
        button.setTitle("Done".localized(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.tintColor = .systemBlue
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.rightButtonPressed(_:)), for: .touchUpInside)
        
        return button
    }()
    
    lazy var titleLabel : UILabel = {
        let Xwidth : CGFloat = view.frame.width
        let width : CGFloat = 80
        let height : CGFloat = 60
        let titleLabel = UILabel(frame: CGRect(x: Xwidth/2 - width/2, y: 0, width: width, height: height))
        
        if index != nil {
            titleLabel.text = "Edit Trip".localized()
        } else {
            titleLabel.text = "Add Trip".localized()
        }
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.tintColor = .black
        
        return titleLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        textFieldConfig()
        tagButtonConfig()
        
        searchCompleter.delegate = self
        
        view.addSubview(leftButton)
        view.addSubview(rightButton)
        view.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalTo: leftButton.heightAnchor).isActive = true
        
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
        rightButton.heightAnchor.constraint(equalTo: leftButton.heightAnchor).isActive = true

    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideKeyboardWhenTappedAround()
    }
    
    internal func configure() {
        
        mainTitleLabel.text = "What kind of trip are you planning?".localized()
        mainTitleLabel.textAlignment = .center
        
        locationTableView.dataSource = self
        locationTableView.delegate = self
        locationTableView.tag = 2
        
        locationSearchbar.placeholder = "Destination (Optional)".localized()
        locationSearchbar.delegate = self
        locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
        
        startDatePicker.addTarget(self, action: #selector(handleStartDatepicker(_:)), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(handleEndDatepicker(_:)), for: .valueChanged)
        
        if index == nil {
            print("index == nil")
            tripStartDate = Date()
            tripEndDate = Date()
            
            editedTripStartDate = tripStartDate
            editedTripEndDate = tripEndDate
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd.yy"
            
        } else {
            print("index != nil")
            tripTitle = tripList[index!].title
            tripSubTitle = tripList[index!].subTitle
            tripPlace = tripList[index!].place
            tripStartDate = tripList[index!].startDate
            tripEndDate = tripList[index!].endDate
            tripTagColor = tripList[index!].tagColor
            
            editedTripTitle = tripTitle
            editedTripStartDate = tripStartDate
            editedTripEndDate = tripEndDate
            editedTripTagColor = tripTagColor
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd.yy"
            startDatePicker.datePickerMode = .date
            startDatePicker.date = tripStartDate!
            endDatePicker.date = tripEndDate!
            locationSearchbar.text = tripPlace!
            
            DispatchQueue.main.async {
                self.performSearch(query: self.tripPlace!) {
                    
                    if self.index != nil {
                        let coordinate = self.searchResults[0].placemark.coordinate
                        let address = self.searchResults[0].placemark.title
                        self.setMapView(coordinate: coordinate, addr: address ?? "")
                    }
                }
            }
        }
        
        locationSearchButton.setTitle("Search".localized(), for: .normal)
    }
    
    internal func textFieldConfig() {
        
        startDateLabel.text = "Start Date".localized()
        endDateLabel.text = "End Date".localized()
        
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = UIFont.systemFont(ofSize: 17)
        titleTextField.font = UIFont.systemFont(ofSize: 17)
        titleTextField.delegate = self
        titleTextField.tag = 0
        

        subtitleTextField.borderStyle = .roundedRect
        subtitleTextField.font = UIFont.systemFont(ofSize: 17)
        subtitleTextField.delegate = self
        subtitleTextField.tag = 1
        
        if index != nil {
            let truncatedTitle = editedTripTitle!.prefix(editedTripTitle!.count - 23)
            titleTextField.text = String(truncatedTitle)
            subtitleTextField.text = tripSubTitle

        } else {
            titleTextField.placeholder = "Trip Title".localized()
            subtitleTextField.placeholder = "Description (Optional)".localized()
        }
    }
    
    internal func tagButtonConfig() {
        
        calendarLabel.text = "Calendar".localized()
        
        if index != nil {
            print("tripTagColor: ", tripTagColor)
            
            if let colorData = colorData.first(where: { $0["color"] as? UIColor == UIColor(hex: tripTagColor!) }),
               let title = colorData["title"] as? String {
                print("Matching title: \(title)")
                tagButton.setTitle(title, for: .normal)
                tagButton.setImage(UIImage(systemName: "circle.fill")?.withTintColor(UIColor(hex: tripTagColor!)!, renderingMode: .alwaysOriginal), for: .normal)
            } else {
                print("No matching title found")
                tagButton.setImage(UIImage(systemName: "circle.fill")?.withTintColor(UIColor(hex: tripTagColor!)!, renderingMode: .alwaysOriginal), for: .normal)
            }
            
            
            
        } else {
            tagButton.setTitle("Ice".localized(), for: .normal)
            tagButton.setImage(UIImage(systemName: "circle.fill")?.withTintColor(UIColor(hex: "CBDCFC")!, renderingMode: .alwaysOriginal), for: .normal)
           
        }
        // 버튼에 이미지 추가
        
        tagButton.imageView?.contentMode = .scaleAspectFit
        tagButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10) // 아이콘과 텍스트 간격 설정
                
        var colorOptions: [(title: String, icon: UIImage?, color: UIColor)] = []
        
        // colorData 이용하여 colorOptions 생성
        for colorInfo in colorData {
            if let title = colorInfo["title"] as? String, let color = colorInfo["color"] as? UIColor {
                print("title:", title)
                let icon = UIImage(systemName: "circle.fill")?.withTintColor(color, renderingMode: .alwaysOriginal)
                
                colorOptions.append((title, icon, color))
            }
        }
        
        // 색상 선택 메뉴 생성
        let colorMenuItems = colorOptions.map { option in
            UIAction(title: option.title, image: option.icon, handler: { [weak self] _ in
                // 사용자가 선택한 옵션
                print("Selected color: \(option.title), Hex: \(option.color.hexColorExtract(tintColor: (self?.tagButton.imageView)!))")
                
                self?.tagButton.setTitle(option.title, for: .normal)
                self?.tagButton.setImage(option.icon, for: .normal)
                self?.tagButton.tintColor = option.color
                
                self?.editedTripTagColor = option.color.hexColorExtract(tintColor: (self?.tagButton.imageView)!)

            })
        }
        
        let colorsMenu = UIMenu(title: "Choose Calendar Color".localized(), options: .displayInline, children: colorMenuItems)
        
        if index != nil {
            
        } else {
            tripTagColor = "CBDCFC"
            editedTripTagColor = tripTagColor
        }
        
        // 버튼에 메뉴 할당
        tagButton.showsMenuAsPrimaryAction = true
        tagButton.menu = colorsMenu
    }
    
    @objc internal func leftButtonPressed(_ sender: UIButton) {
        print("leftButtonPressed")
        actionSheet(
            title: "Back to previous view".localized(),
            message: "Are you sure you want to discard your changes?".localized(),
            actionTitle1: "Discard Changes".localized(),
            actionTitle2: "Cancel".localized())
    }
    
    @objc internal func rightButtonPressed(_ sender: UIButton) {
        
        var title: String?
        var message: String?
        
        if index != nil { // 일정 수정
            title = "Are you sure you want to save your changes".localized()
            message = "Changes will be saved".localized()
        } else { // 일정 신규 추가
            title = "Do you want to add this trip?".localized()
            message = "This trip will be added on the list".localized()
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action0 = UIAlertAction(title: "Cancel".localized(), style: .cancel)
        alertController.addAction(action0)
        let action1 = UIAlertAction(title: "Save".localized(), style: .default) { UIAlertAction in
            
            guard let tripTitle = self.editedTripTitle else {
                self.alert(title: "Can`t save the trip".localized(), message: "Please write title of your trip".localized(), actionTitle: "OK".localized())
                return
            }
            guard let tripStartDate = self.editedTripStartDate else {
                self.alert(title: "Can`t save the trip".localized(), message: "Please fill out the start date of your trip".localized(), actionTitle: "OK".localized())
                return
            }
            guard let tripEndDate = self.editedTripEndDate else {
                self.alert(title: "Can`t save the trip".localized(), message: "Please fill out the end date of your trip".localized(), actionTitle: "OK".localized())
                return
            }
            guard let tripTagColor = self.editedTripTagColor else {
                self.alert(title: "Can`t save the trip".localized(), message: "Please select calendar color of your trip".localized(), actionTitle: "OK".localized())
                return
            }
            
            var tripSubTitle = ""
            var tripPlace = ""
            
            if let optionalTripSubTitle = self.tripSubTitle {
                tripSubTitle = optionalTripSubTitle
            }
            
            if let optionalPlace = self.tripPlace {
                tripPlace = optionalPlace
            }
            
//            guard let optionalTripSubTitle = self.tripSubTitle else {
//                //self.alert(title: "Can`t save the trip".localized(), message: "Please write description of your trip".localized(), actionTitle: "OK".localized())
//                print("asfd")
//                return
//            } // optional
//            tripSubTitle = optionalTripSubTitle
//
//            guard let optionalPlace = self.tripPlace else {
//                //self.alert(title: "Can`t save the trip".localized(), message: "Please select destination of your trip".localized(), actionTitle: "OK".localized())
//                print("asfd")
//                return
//            } // optional
//            tripPlace = optionalPlace
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd.yy"
            
            let startDateString = dateFormatter.string(from: tripStartDate)
            let endDateString = dateFormatter.string(from: tripEndDate)
            
            print("startDateString: \(startDateString)")
            print("endDateString: \(endDateString)")
            
            let newEditedTripTitle : String
            
            if tripTitle.count >= 23 {
                let truncatedTitle = tripTitle.prefix(tripTitle.count - 23)
                newEditedTripTitle = "\(truncatedTitle) (\(startDateString) ~ \(endDateString)) "
                print("newEditedTripTitle: \(newEditedTripTitle)")
            } else {
                // 23글자 이하인 경우 그대로 사용
                newEditedTripTitle = "\(tripTitle) (\(startDateString) ~ \(endDateString)) "
                print("newEditedTripTitle: \(newEditedTripTitle)")
            }
            
            let realm = try! Realm()
            let realmFiltered = realm.objects(TripList.self).filter("title = %@", newEditedTripTitle)
            
            if self.index == nil { // 새로운 여행 생성
                
                if realmFiltered.count != 0 {// 동일한 여행 명이 있음
                    self.alert(title: "It has the same trip title among your trip list".localized(), message: "Use other trip title".localized(), actionTitle: "OK".localized())
                    
                } else { //동일한 여행 명이 없음
                    let realm = try! Realm()
                    let newTrip = TripList(title: newEditedTripTitle, subTitle: tripSubTitle, place: tripPlace, startDate: tripStartDate, endDate: tripEndDate, tagColor: tripTagColor)

                    try! realm.write {
                        realm.add(newTrip)
                    }
                    
                    self.loadTripList() { }
                    
                    NotificationCenter.default.post(name: Notification.Name("userInputEntryUpdate"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
                
                
            } else { // 기존 생성 수정 + 캘린더에다가 태그 컬러 변경 시 반영 및 캘린더 이름 변경 필요
                
                let eventStore = EKEventStore()

                // 원하는 캘린더 식별자를 찾습니다.
                let calendarIdentifier = self.tripTitle // old
                let calendars = eventStore.calendars(for: .event)

                for calendar in calendars {
                    if calendar.title == calendarIdentifier {
                        print("Updating calendar: \(calendar.title)")
                        let originalSource = calendar.source
                        // 캘린더의 이벤트를 가져옵니다.
                        
                        let currentCalendar = Calendar.current
                        
                        let newStartDate = currentCalendar.date(byAdding: .day, value: -1, to: self.tripStartDate!)
                        let newEndDate = currentCalendar.date(byAdding: .day, value: 1, to: self.tripEndDate!)
                        
                        let events = eventStore.events(matching: eventStore.predicateForEvents(withStart: newStartDate!, end: newEndDate!, calendars: [calendar]))

                        // 새로운 캘린더를 생성합니다.
                        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
                        newCalendar.source = originalSource
                        newCalendar.title = newEditedTripTitle // 원하는 이름으로 변경
                        newCalendar.cgColor = UIColor(hex: self.editedTripTagColor!)?.cgColor  // 새로운 태그 컬러로 변경
                        print("newCalendar: \(newCalendar)")
                        
                        // 새로운 캘린더를 추가합니다.
                        do {
                            try eventStore.saveCalendar(newCalendar, commit: true)
                            print("New calendar created successfully")
                            
                        } catch {
                            //실패 시 다른 source로 저장해야됨
                            print("Error creating new calendar: \(error)")
                        }
                        
                        // 이전 캘린더의 이벤트를 새 캘린더로 이동합니다.
                        for event in events {
                            event.calendar = newCalendar
                            do {
                                try eventStore.save(event, span: .thisEvent, commit: true)
                                print("Event moved to new calendar successfully")
                                
                            } catch {
                                print("Error moving event: \(error)")
                            }
                        }
                        
                        // 3. 이전 캘린더를 삭제합니다.
                        do {
                            if let existingCalendar = try eventStore.calendar(withIdentifier: calendar.calendarIdentifier) {
                                do {
                                    try eventStore.removeCalendar(existingCalendar, commit: true)
                                    print("Old calendar removed successfully")
                                } catch {
                                    print("Old calendar removing error: \(error)")
                                }
                            } else {
                                print("Old calendar not found.")
                            }
                        } catch {
                            print("Error Old calendar removing: \(error)")
                        }
                        
                        // 이전 캘린더를 삭제합니다.
//                        do {
//                            try eventStore.removeCalendar(calendar, commit: true)
//                            print("Old calendar removed successfully")
//                        } catch {
//                            print("Error removing old calendar: \(error.localizedDescription)")
//                        }

                    }
                }
                

                
                if let tripListTodelete = realm.object(ofType: TripList.self, forPrimaryKey: self.tripTitle) {
                    // 검색된 객체를 삭제
                    try! realm.write {
                        realm.delete(tripListTodelete)
                    }
                }

                let realm = try! Realm()
                let newTrip = TripList(title: newEditedTripTitle, subTitle: tripSubTitle, place: tripPlace, startDate: tripStartDate, endDate: tripEndDate, tagColor: tripTagColor)
                try! realm.write {
                    realm.add(newTrip, update: .modified)
                }
                
                self.loadTripList() { }
                
                NotificationCenter.default.post(name: Notification.Name("userInputEntryUpdate"), object: nil)
                self.dismiss(animated: true, completion: nil)
                
            }

        }
        alertController.addAction(action1)
        self.present(alertController, animated: true)
    }
    
    @objc private func handleStartDatepicker(_ sender: UIDatePicker) {
        // 시작일은 종료일 보다 같거나 작아야 함
        // 시작일이 종료일 보다 크면, 종료일을 시작일과 동일하게 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yy"
        //tripStartDate = sender.date
        editedTripStartDate = sender.date
        print("editedTripStartDate: \(editedTripStartDate)")
        if editedTripStartDate! > editedTripEndDate! { // 시작일이 종료일 보다 크면, 종료일을 시작일과 동일하게 설정
            print("시작일이 종료일 보다 크면, 종료일을 시작일과 동일하게 설정")
            let startDate = dateFormatter.string(from: tripStartDate!)
            let endDate = dateFormatter.string(from: tripStartDate!)
            //endDatePicker.date = tripStartDate!
            endDatePicker.date = editedTripStartDate!

        } else {
            print("!시작일이 종료일 보다 크면, 종료일을 시작일과 동일하게 설정")
            let startDate = dateFormatter.string(from: tripStartDate!)
            let endDate = dateFormatter.string(from: tripEndDate!)
        }
        
    }
    
    @objc private func handleEndDatepicker(_ sender: UIDatePicker) {
        // 종료일은 시작일 보다 같거나 커야 함
        // 종료일이 시작보다 작으면, 시작일과 종료일을 동일하게 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yy"
        //tripEndDate = sender.date
        editedTripEndDate = sender.date
        print("editedTripEndDate: \(editedTripEndDate)")
        if editedTripEndDate! < editedTripStartDate! { // 종료일이 시작보다 작으면, 시작일과 종료일을 동일하게 설정
            print("종료일이 시작보다 작으면, 시작일과 종료일을 동일하게 설정")
            let startDate = dateFormatter.string(from: tripEndDate!)
            let endDate = dateFormatter.string(from: tripEndDate!)

            //startDatePicker.date = tripEndDate!
            startDatePicker.date = editedTripEndDate!

        } else {
            print("!종료일이 시작보다 작으면, 시작일과 종료일을 동일하게 설정")
            let startDate = dateFormatter.string(from: tripStartDate!)
            let endDate = dateFormatter.string(from: tripEndDate!)
        }
    }
    
    // Implement the delegate method to handle search completions
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Access the completions using completer.results
        for completion in completer.results {
            print(completion.title)
        }
    }
    
    
    @IBAction func locationSearchButtonPressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.performSearch(query: self.typedSearchText) { // 검색 버튼 입력하면 바뀌는 것으로 하자
                
            }
        }
    }
    
}

extension EntryViewController : UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            if let text = textField.text {
                editedTripTitle = text
            }
        } else {
            if let text = textField.text {
                tripSubTitle = text
            }
        }
    }
}

extension EntryViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let placeholderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: locationTableView.bounds.size.width, height: locationTableView.bounds.size.height))
        placeholderLabel.text = "No Search Result".localized()
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        
        if tableView.tag == 1 {
            return 1
        } else {
            if !searchResults.isEmpty {
                DispatchQueue.main.async {
                    self.locationTableView.backgroundView = nil
                }
                return searchResults.count
            } else {
                DispatchQueue.main.async {
                    self.locationTableView.backgroundView = placeholderLabel
                }
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "locationTableViewCell", for: indexPath) as! locationTableViewCell
            
            if !searchResults.isEmpty {
                cell.locationTitleLabel.text = searchResults[indexPath.row].name
                cell.locationAddressLabel.text = searchResults[indexPath.row].placemark.title ?? ""
                cell.mapItems = searchResults
                
                return cell
                
            } else {
                locationTableView.backgroundView = nil
                
                return cell
            }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationTableViewCell", for: indexPath) as! locationTableViewCell
        
        if let selectedCell = locationTableView.cellForRow(at: indexPath) as? locationTableViewCell {
            
            if let name = selectedCell.mapItems?[indexPath.row].name, let coordinate = selectedCell.mapItems?[indexPath.row].placemark.coordinate,
               let address = selectedCell.mapItems?[indexPath.row].placemark.title {
                print("coordinate: \(coordinate)")
                print("address: \(address)")
                
                tripPlace = name
                locationSearchbar.text = name
                setMapView(coordinate: coordinate, addr: address)
            }
        }
    }
}

extension EntryViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText == "" {
            searchResults = []
            typedSearchText = searchText
            DispatchQueue.main.async {
                self.locationTableView.reloadData()
            }
        } else {
            typedSearchText = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Enter 키 또는 검색 버튼을 클릭했을 때 실행할 코드를 여기에 작성합니다.
        if let searchText = searchBar.text {
            performSearch(query: searchText) { }
        }
        
        // 키보드를 숨김 처리할 수도 있습니다.
        searchBar.resignFirstResponder()
    }
    
    func performSearch(query: String, completion: @escaping() -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            print("response: \(response)")
            if let items = response?.mapItems {
                
                self.searchResults = items
                
                DispatchQueue.main.async {
                    self.locationTableView.reloadData()
                }
                completion()
            }
        }
    }
    
    
}

extension EntryViewController : CLLocationManagerDelegate, MKMapViewDelegate {
    
    func findAddress(lat: CLLocationDegrees, long: CLLocationDegrees){
        let findLocation = CLLocation(latitude: lat, longitude: long)
        let locale = Locale(identifier: "Ko-kr")
        
        geocoder.reverseGeocodeLocation(findLocation, preferredLocale: locale, completionHandler: {(placemarks, error) in
            if let address: [CLPlacemark] = placemarks {
                var myAdd: String = ""
                if let area: String = address.last?.locality{
                    myAdd += area
                }
                if let name: String = address.last?.name {
                    myAdd += " "
                    myAdd += name
                }
            }
        })
    }
    
    func setMapView(coordinate: CLLocationCoordinate2D, addr: String){
        // let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta:0.2, longitudeDelta:0.2))
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = addr
        
        self.findAddress(lat: coordinate.latitude, long: coordinate.longitude)
    }
}
