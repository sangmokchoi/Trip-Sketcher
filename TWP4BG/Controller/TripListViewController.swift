//
//  TripListViewController.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import UIKit
import CoreLocation
import MapKit
import EventKit
import MessageUI
import RealmSwift
//import FirebaseFunctions
//import FirebaseStorage

var performSegueisOK: Bool = false

class TripListViewController: UIViewController {
    
    let eventStore = EKEventStore()
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var settingButton: UIBarButtonItem = {
        let settingButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)//#selector(addTripList(_:)))
        let feedbackAction = UIAction(title: "Send Feedback".localized(), image: nil) { _ in
            
            if MFMailComposeViewController.canSendMail() {
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    
                    let compseVC = MFMailComposeViewController()
                    compseVC.mailComposeDelegate = self
                    compseVC.setToRecipients(["simonwork177@simonwork.net"])
                    compseVC.setSubject("Trip Sketcher Feedback & Help".localized())
                    compseVC.setMessageBody(
                        "===============\nPlease provide feedback if you have any inconvenience or suggestions while using Trip Sketcher.\n\nModel: \(UIDevice.current.name)\nOS Version: \(UIDevice.current.systemVersion)\nVersion : \(version)\n\n(write your comments below. Including screenshots would be even more helpful. Thank You)\n===============\n", isHTML: false)
                    
                    self.present(compseVC, animated: true, completion: nil)
                }
                
            } else { // 메일 사용이 불가한 경우
                self.alert(title: "Fail to send mail".localized(), message: "Check Mail App setting in your phone" .localized(), actionTitle: "OK".localized())
            }
        }
        
        let IAPAction = UIAction(title: "Pro version upgrade".localized(), image: nil) { _ in
            self.performSegue(withIdentifier: "tripListToIAP", sender: UIMenu())
        }
        
        let ratingAction = UIAction(title: "Tap to Rate".localized(), image: nil) { _ in
            if let url = URL(string: "itms-apps://apps.apple.com/app/id6464154800") {
                print("url: \(url)")
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                
            } else {
                self.alert(title: "Unable to open App Store".localized(), message: "Sorry for your inconvenience".localized(), actionTitle: "OK".localized())
            }
        }
        
        let fetchFromCalendarAction = UIAction(title: "Load Existing Calendar".localized(), image: nil) { _ in
            
            self.reFetchFromCalendar()
        }
        
        let menu = UIMenu(title: "Setting", children: [feedbackAction, IAPAction, ratingAction, fetchFromCalendarAction])
        settingButton.menu = menu
        settingButton.tintColor = UIColor(named: "gray Color")
        return settingButton
    }()
    
    private func reFetchFromCalendar() {
        
        self.loadTripList() {
            
            if tripList == [] {
                
                switch EKEventStore.authorizationStatus(for: .event) {
                case .fullAccess:
                    
                    let calendars = self.eventStore.calendars(for: .event)
                    
                    let filteredCalendars = calendars.filter { calendar in
                        return calendar.title.contains("(") && calendar.title.contains("~") && calendar.title.contains(") ") && calendar.title.contains(".")
                    }
                    
                    print("filteredCalendars: ", filteredCalendars)
                    
                    if filteredCalendars != [] {
                        for filteredCalendar in filteredCalendars {
                            // filteredCalendar의 title을 추출
                            let title = filteredCalendar.title
                            
                            // title을 공백 문자 " "를 기준으로 분할
                            let components = title.components(separatedBy: " (")
                            //let components = title.components(separatedBy: CharacterSet(charactersIn: " ("))
                            
                            let startIndex = title.index(title.endIndex, offsetBy: -23)
                            let endIndex = title.index(before: startIndex)
                            
                            let suffixCharacters = String(title[startIndex...]) // " (12.20.23 ~ 12.25.23) "
                            let extractedTitle = String(title[...endIndex])
                            
                                //let extractedTitle = components[0] // "뉴욕 여행"
                            let dateInfo = suffixCharacters // "12.22.23 ~ 12.25.23) "
                            //let dateInfo = components[1] // "12.22.23 ~ 12.25.23) "
                            
                            print("extractedTitle: \(extractedTitle)")
                            print("dateInfo: \(dateInfo)")
                                if let dateInfoRange = dateInfo.range(of: " ~ ") {
                                    let startDateString = dateInfo[..<dateInfoRange.lowerBound] // "12.22.23"
                                    var endDateString = dateInfo[dateInfoRange.upperBound...] // "12.25.23)"
                                    
                                    // endDateString에서 마지막 괄호 제거
                                    endDateString.removeLast()
                                    
                                    print("extractedTitle: \(extractedTitle)")
                                    print("startDateString: \(startDateString)")
                                    print("endDateString: \(endDateString)")
                                    
                                    // startDateString과 endDateString에서 괄호 및 물결표시 제거
                                    let startDateStringWithoutSymbols = startDateString.replacingOccurrences(of: "(", with: "")
                                    let endDateStringWithoutSymbols = endDateString.replacingOccurrences(of: ")", with: "")
                                    print("startDateStringWithoutSymbols: \(startDateStringWithoutSymbols)")
                                    print("endDateStringWithoutSymbols: \(endDateStringWithoutSymbols)")
                                    
                                    // 날짜 형식으로 변환
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "MM.dd.yy"
                                    
                                    let utcTimeZone = TimeZone(abbreviation: "UTC")!
                                    let currentTimeZone = TimeZone.current.identifier
                                    dateFormatter.timeZone = utcTimeZone
                                    dateFormatter.locale = Locale(identifier: Locale.current.identifier)
                                    
                                    let startDate = dateFormatter.date(from: startDateStringWithoutSymbols)
                                    let endDate = dateFormatter.date(from: endDateStringWithoutSymbols)
                                    
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.year, .month, .day], from: startDate!)
                                    
                                    let componentsDate = calendar.date(from: components)
                                    let dateString = dateFormatter.string(from: componentsDate!)
                                    // 추출한 데이터를 사용하거나 저장
                                    print("Extracted Title: \(extractedTitle)")
                                    print("Start Date: \(startDate)")
                                    print("End Date: \(endDate)")
                                    
                                    guard let calendarColor = filteredCalendar.cgColor else { return }
                                    
                                    let uiColor = UIColor(cgColor: calendarColor)
                                    // UIColor를 사용하여 색상을 표현
                                    let colorString = uiColor.toHexString()
                                    
                                    let tripList = TripList(title: title, subTitle: "", place: "", startDate: startDate, endDate: endDate, tagColor: colorString)
                                    print("tripList: \(tripList)")
                                    
                                    let realm = try! Realm()
                                    try! realm.write {
                                        realm.add(tripList)
                                    }
                                }
                                
                            
                            // 여기에서 필요한 로직을 추가하거나 TripList 객체를 만들어서 저장할 수 있음
                            self.loadTripList() {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    } else {
                        self.alert(title: "No calendar loaded".localized(), message: "If you have a calendar saved in iCloud through Trip Sketcher, please check your account information in the calendar or refresh the calendar".localized(), actionTitle: "OK".localized())
                    }
                    
                case .notDetermined:
                    
                    let alertController = UIAlertController(title: "Please enable Full Access to your Calendar".localized(), message: "Required for adding and managing schedules".localized(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                        
                        if #available(iOS 17.0, *) {
                            self.eventStore.requestFullAccessToEvents() { granted, error in
                                if granted {
                                    DispatchQueue.main.async {
                                        self.reFetchFromCalendar()
                                    }
                                }
                            }
                        } else {
                            self.eventStore.requestAccess(to: .event) { granted, error in
                                if granted {
                                    DispatchQueue.main.async {
                                        self.reFetchFromCalendar()
                                    }
                                }
                            }
                        }
                    }
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                    
                case .denied, .restricted, .writeOnly:
                    let alertController = UIAlertController(title: "Calendar access has been denied".localized(), message: "Please enable Full Access to your Calendar in Settings".localized(), preferredStyle: .alert)
                    let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
                    let action2 = UIAlertAction(title: "Go to Settings".localized(), style: .default) { UIAlertAction in
                        
                        self.openAppSettings()
                    }
                    
                    alertController.addAction(action1)
                    alertController.addAction(action2)
                    self.present(alertController, animated: true)

                @unknown default:
                    print("Unknown authorization status")
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.alert(title: "There are existing saved trips".localized(), message: "You can only load trips from the calendar if there are no saved trips".localized(), actionTitle: "OK".localized())
            }
        }
    }
    
    lazy var addButton: UIButton = {
        let addButton = UIButton()
        
        addButton.translatesAutoresizingMaskIntoConstraints = false // 버튼에 대한 오토레이아웃 설정
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
        let image = UIImage(systemName: "plus.circle.fill", withConfiguration: imageConfig)
        
        addButton.setImage(image, for: .normal)
        addButton.tintColor = UIColor(hex: "E3582D") // 이미지 색상 설정 // 감귤: E3582D
        addButton.backgroundColor = .white
        addButton.layer.cornerRadius = 60
        addButton.addTarget(self, action: #selector(self.addTripList(_:)), for: .touchUpInside)
        
        return addButton
    }()
    
    @objc internal func addTripList(_ sender: UIButton) {
        
        //q        if performSegueisOK == true { //
        print("tripList.count: \(tripList.count)")
        
        if tripList.count < 1 {
            print("tripList.count < 1")
            performSegue(withIdentifier: "tripListToEntry", sender: UIButton())
            
        } else {// 구매 여부 검증 필요
            if performSegueisOK {
                print("if performSegueisOK {")
                performSegue(withIdentifier: "tripListToEntry", sender: UIButton())
                
            } else {
                print("!if performSegueisOK {")
                let alertController = UIAlertController(title: "The number of trips offered in the free version is 1\nIf you've previously purchased the Pro version, please restore your purchase".localized(), message: "If you upgrade the pro version, you can add and manage your trip list unlimitedly".localized(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                    
                }
                alertController.addAction(action)
                self.present(alertController, animated: true)
            }
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TripListViewController viewDidLoad")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = settingButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadIAPDataForCheck), name: NSNotification.Name(rawValue: "loadIAPDataForCheck"), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("TripListViewController viewWillAppear")
        
        loadIAPDataForCheck()
        
        loadTripList {
            self.tableView.reloadData()
        }
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), // 오른쪽 여백 조절
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), // 아래 여백 조절
            addButton.widthAnchor.constraint(equalToConstant: 60), // 버튼 크기 조절
            addButton.heightAnchor.constraint(equalToConstant: 60), // 버튼 크기 조절
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(userInputEntryUpdate), name: NSNotification.Name(rawValue: "userInputEntryUpdate"), object: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("loadIAPDataForCheck"), object: nil)
        }
        
    }
    
    @objc func loadIAPDataForCheck() {
        
        loadIAPData() {

            if iapDatas == [] { // 구매한 적이 없음 -> triplist가 1개여야 함
                print("performSegueisOK = false")
                
                if !UserDefaults.standard.bool(forKey: "initialGuide") {
                    
                    let alertController = UIAlertController(title: "The number of trips offered in the free version is 1\nIf you've previously purchased the Pro version, please restore your purchase".localized(), message: "If you upgrade the pro version, you can add and manage your trip list unlimitedly".localized(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                        UserDefaults.standard.setValue(true, forKey: "initialGuide")  // pro 버전을 구매하기 전까지는 tripList의 개수가 최대 1개임을 인지
                        self.AccessCalendar()
                    }
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                    
                } else { // initialGuide를 이미 읽었음
                    // initialGuide가 1개인지 아닌 지를 확인해야 함
                    performSegueisOK = false

                    self.requestAccess()
                }
                
            } else { // iapData != nil, 구매한 적 있음
                print("iapData != nil iapData:")
                
                for iapData in iapDatas {
                    
                    if iapData.type == "Non-Consumable" { // 비소모성 구매
                        // 비소모성 구매를 완료했으므로, triplist 2개 이상 사용 가능
                        // performSegue 허용
                        print("비소모성 구매를 완료했으므로, triplist 2개 이상 사용 가능")
                        performSegueisOK = true
                        //print("iapData:", iapData)
                        break
                    } else { // 구독
                        // Date(timeIntervalSince1970: iapData.expiresDate)
                        if iapData.expiresDate! > Date() {
                            // 구독 정보 중 아직 구독 만료일이 도래하지 않은 값이 있으므로, triplist 2개 이상 사용 가능
                            print("구독 정보 중 아직 구독 만료일이 도래하지 않은 값이 있으므로, triplist 2개 이상 사용 가능")
                            // performSegue 허용
                            //print("iapData: \(iapData)")
                            performSegueisOK = true
                            break
                        } else {
                            // 구독 정보 중 구독 만료 됨
                            print("구독 정보 중 구독 만료 됨")
                            performSegueisOK = false
                        }
                        
                    }
                }
            }
            
        }
    }
    
    func AccessCalendar() {
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Please enable Full Access to your Calendar".localized(), message: "Required for adding and managing schedules".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                self.requestAccess()
            }
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }

    }
    
    func requestAccess() {
        if #available(iOS 17.0, *) {
            self.eventStore.requestFullAccessToEvents() { granted, error in
                
                if granted {
                    print("requestFullAccessToEvents granted")
                } else {
                    print("requestFullAccessToEvents not granted")
                }
                
            }
        } else {
            print("!!if #available(iOS 17.0, *) {")
            self.eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    
                } else {
                    
                }
            }
        }
    }
    
    @objc func userInputEntryUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.navigationItem.backBarButtonItem = backBarButtonItem // Back 버튼 삭제
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tripListToTrip" { // 작성한 일정을 확인하러 갈때
            let nextVc = segue.destination as! TripViewController
            if let index = sender as? Int {
                //print("index: \(index)")
                //let title = tripList[index].title
                //let truncatedTitle = title!.prefix(title!.count - 23)
                nextVc.index = index
                nextVc.tripTitle = tripList[index].title
                nextVc.tripStartDate = tripList[index].startDate
                nextVc.tripEndDate = tripList[index].endDate
                nextVc.tripTagColor = tripList[index].tagColor
                nextVc.tripPlace = tripList[index].place
                
            }
        } else if segue.identifier == "tripListToEntry" { // 작성한 여행의 내용을 수정할때
            let nextVc = segue.destination as! EntryViewController
            if let index = sender as? Int {
                //print("index: \(index)")
                //let title = tripList[index].title
                //let truncatedTitle = title!.prefix(title!.count - 23)
                nextVc.index = index
                nextVc.tripTitle = tripList[index].title
                nextVc.tripStartDate = tripList[index].startDate
                nextVc.tripEndDate = tripList[index].endDate
                nextVc.tripTagColor = tripList[index].tagColor
                nextVc.tripPlace = tripList[index].place
                //nextVc.tripPlaceList = tripList[index].placeList
                
            }
        }
    }
}

extension TripListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if performSegueisOK {
            
            performSegue(withIdentifier: "tripListToTrip", sender: indexPath.section)
            
        } else {
            
            if indexPath.section == 0 {
                
                performSegue(withIdentifier: "tripListToTrip", sender: indexPath.section)
                
            } else {
                
                let alertController = UIAlertController(title: "Notification".localized(), message: "To create and manage more than 2 trips, you need to upgrade to the Pro version".localized(), preferredStyle: .alert)
                let action1 = UIAlertAction(title: "Cancel".localized(), style: .destructive) { UIAlertAction in
                    
                }
                let action2 = UIAlertAction(title: "OK".localized(), style: .default) { UIAlertAction in
                    
                    self.performSegue(withIdentifier: "tripListToIAP", sender: UIMenu())
                }
                alertController.addAction(action1)
                alertController.addAction(action2)
                self.present(alertController, animated: true)
            }
        }
    }
}

extension TripListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tripList.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripCell", for: indexPath) as! TripTableViewCell
        
        let title = tripList[indexPath.section].title
        let truncatedTitle = title!.prefix(title!.count - 23)
        cell.tripListTitleLabel.text = String(truncatedTitle)
        //cell.tripListTitleLabel.text = tripList[indexPath.section].title
        cell.tripListSubTitleLabel.text = tripList[indexPath.section].subTitle
        cell.tripListPlaceLabel.text = tripList[indexPath.section].place
        
        if let tagColor = tripList[indexPath.section].tagColor {
            cell.tagColorImageView.tintColor = UIColor(hex: tagColor)
        } else {
            cell.tagColorImageView.tintColor = UIColor(hex: "E3582D")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yy"
        
        if let startDate0 = tripList[indexPath.section].startDate, let endDate0 = tripList[indexPath.section].endDate {
            let startDate1 = dateFormatter.string(from: startDate0)
            let endDate1 = dateFormatter.string(from: endDate0)
            cell.tripListDateLabel.text = "\(startDate1) ~ \(endDate1)"
        } else {
            cell.tripListDateLabel.text = ""
        }
        
        let update = UIAction(title: "Edit Trip".localized(), image: UIImage(systemName: "pencil"), handler: { [weak self] _ in
            self?.performSegue(withIdentifier: "tripListToEntry", sender: indexPath.section)
            
        })
        
        let delete = UIAction(title: "Delete Trip".localized(), image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in
            
            
            let alertController = UIAlertController(title: "Are you sure you want to delete this trip?".localized(), message: "It will remove all events not only from Trip Sketcher but also from your Calendar".localized(), preferredStyle: .alert)
            let action1 = UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil)
            let action2 = UIAlertAction(title: "Delete".localized(), style: .destructive) { UIAlertAction in
                
                //NotificationCenter.default.post(name: Notification.Name("deleteAllItems"), object: nil)
                
                let eventStore = EKEventStore()
                
                let calendarIdentifier = tripList[indexPath.section].title
                let calendars = eventStore.calendars(for: .event)

                for calendar in calendars {
                    print("calendar: ", calendar)
                    if calendar.title == calendarIdentifier {
                        print("Deleting calendar: \(calendar.title)")
                        
                        do {
                            try eventStore.removeCalendar(calendar, commit: true)
                            print("Calendar removed successfully")
                            break
                        } catch {
                            print("Error removing calendar: \(error.localizedDescription)")
                        }
                    }
                }
                let realm = try! Realm()
                let removedTrip = tripList[indexPath.section]
                try! realm.write {
                    realm.delete(removedTrip)
                }
                tripList.remove(at: indexPath.section)
                tableView.reloadData()
            }
            
            alertController.addAction(action1)
            alertController.addAction(action2)
            self.present(alertController, animated: true)
            
        })
        
        let menu = UIMenu(title: "", children: [update, delete])
        cell.setButton.menu = menu
        
        return cell
        
    }
    
}

extension TripListViewController : MFMailComposeViewControllerDelegate {
    
}
