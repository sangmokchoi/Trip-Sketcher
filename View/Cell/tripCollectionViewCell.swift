//
//  tripCollectionViewCell.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/09.
//

import UIKit
import RealmSwift

class tripCollectionViewCell: UICollectionViewListCell {
    
    @IBOutlet weak var indexImageView: UIImageView!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagColorView: UIView!
    
    @IBOutlet weak var tripTitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tripSubTitleLabel: UILabel!
    @IBOutlet weak var dollarSignButton: UIButton!
    
    let expenseView = UIView() //UIPickerView()
    let searchBar = UISearchBar()
    var isPickerViewSelected: Bool = false
    
    private var timeInterval : [String] = []
    
    var scheduleUID: String? // pk, event.eventIdentifier
    var tripStartDate: Date?
    var tripEndDate: Date?
    
    var keyboardHeight: CGFloat?
    var textFieldYInWindow: CGFloat?
    var isKeyboardOpen: Bool = false
    var indexPath: IndexPath = [0, 0]
    
    var startTransform: CGAffineTransform {
        return CGAffineTransform(translationX: 0, y: 0)
    }
    
    var endTransform: CGAffineTransform {
        return CGAffineTransform(translationX: -expenseView.bounds.width - dollarSignButton.bounds.width - 15, y: 0)
    }
    
    lazy var label: UILabel = {
        let label = UILabel()
        
        let labelWidth: CGFloat = 30
        let labelHeight: CGFloat = 30
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.backgroundColor = .clear // Set the background color
        label.textColor = UIColor(named: "reversed Color") // Set the text color
        label.textAlignment = .center
        label.frame = CGRect(
            x: self.bounds.width - labelWidth,
            y: self.bounds.midY - labelHeight/2,
            width: labelWidth,
            height: labelHeight
        )
        label.isHidden = false
        return label
    }()
    
    var recentAction: UIAction!
    var removeAction: UIAction!
    var currencyMenuItems: [UIAction] = []
    var menu = UIMenu()
    
    lazy var menuButton: UIButton = {
        let menuButton = UIButton()
        
        let labelWidth: CGFloat = 90
        let labelHeight: CGFloat = 40
        
        menuButton.setTitle("Set Currecncy".localized(), for: .normal)
        menuButton.setTitleColor(UIColor(named: "reversed Color"), for: .normal)
        
        menuButton.titleLabel?.numberOfLines = 0 // 여러 줄 설정
        menuButton.titleLabel?.lineBreakMode = .byWordWrapping // 단어 단위 줄 바꿈
        
        menuButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        menuButton.contentHorizontalAlignment = .center
        
        menuButton.backgroundColor = .systemGray5
        menuButton.layer.cornerRadius = 15
        
        menuButton.layer.shadowColor = UIColor.black.cgColor
        menuButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        menuButton.layer.shadowRadius = 2
        menuButton.layer.shadowOpacity = 0.5
        
        menuButton.frame = CGRect(
            x: 10,
            y: self.frame.height / 2 - labelHeight / 2 - 5,
            width: labelWidth,
            height: labelHeight
        )
        
        recentAction = UIAction(title: currencyTitle, image: UIImage(systemName: "star.circle")) { [weak self] _ in
            
            self!.menuButton.setTitle(self!.recentAction.title, for: .normal)
        }
        
        removeAction = UIAction(title: "Delete Expense".localized(), image: UIImage(systemName: "xmark.circle.fill"), attributes: .destructive) { [weak self] _ in
            
            guard let scheduleUID = self!.scheduleUID else {
                print("guard let scheduleUID = self!.scheduleUID else")
                return
            }
            
            let realm = try! Realm()
            // 삭제할 객체를 검색
            if let tripForExpenseToDelete = realm.object(ofType: TripForExpense.self, forPrimaryKey: scheduleUID) {
                // 검색된 객체를 삭제
                try! realm.write {
                    realm.delete(tripForExpenseToDelete)
                }
                
                self!.menuButton.setTitle("Set Currecncy".localized(), for: .normal)
                self!.expenseTextField.text = ""
                self!.expenseView.transform = self!.startTransform
                
                self!.dollarSignButton.isUserInteractionEnabled = true
                self!.isPickerViewSelected.toggle()
                print("self!.isPickerViewSelected: \(self!.isPickerViewSelected)")
                
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(systemName: "hand.point.up.left.fill")
                imageAttachment.image = imageAttachment.image?.withTintColor(UIColor(named: "gray Color")!)
                let imageString = NSAttributedString(attachment: imageAttachment)
                
                let mutableAttributedString = NSMutableAttributedString()
                mutableAttributedString.append(imageString)
                
                self!.dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
                
                print("삭제 완료")
                
                self!.loadTripForExpense {
                    print("1111")
                    
                    if let collectionView = self!.superview as? UICollectionView,
                       let indexPath0 = collectionView.indexPath(for: self!) {
                        print("2222")
                        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
                        //print("visibleIndexPaths: \(visibleIndexPaths)")
                        print("3333")
                        for indexPath in visibleIndexPaths {
                            if let cell = collectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
                                
                                if !self!.isPickerViewSelected {
                                    print("cell.dollarSignButton.isUserInteractionEnabled = false")
                                    cell.dollarSignButton.isUserInteractionEnabled = false
                                } else {
                                    print("cell.dollarSignButton.isUserInteractionEnabled = true")
                                    cell.dollarSignButton.isUserInteractionEnabled = true
                                }
                                
                                DispatchQueue.main.async {
                                    collectionView.reloadData()
                                }
                            }
                        }
                    } else {
                        print("4444")
                    }
                }
                
            } else {
                // 해당 scheduleUID를 가진 객체가 존재하지 않음
                print("해당 scheduleUID를 가진 객체가 존재하지 않습니다.")
            }

        }
        
        currencyMenuItems = countryCurrency.enumerated().map { (index, currency) in
            UIAction(title: currency, handler: { [weak self] _ in
                self?.handleCurrencySelection(at: index)
            })
        }
        
        menu = UIMenu(title: "Set Currecncy".localized(), children: [recentAction] + [removeAction] + currencyMenuItems)
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
        
        return menuButton
    }()
    
    
    func handleCurrencySelection(at index: Int) {
        
        DispatchQueue.main.async {
            let selectedCurrency = currency[index]
            currencyTitle = selectedCurrency
            
            self.menuButton.setTitle(currencyTitle, for: .normal)
            
            self.recentAction.title = currencyTitle
            self.updateMenu()
        }
        
    }
    
    func updateMenu() {

        menu = UIMenu(title: "Set Currecncy".localized(), children: [recentAction] + [removeAction] + currencyMenuItems)
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
    }
    
    lazy var expenseTextField: UITextField = {
        let expenseTextField = UITextField()
        
        let labelWidth: CGFloat = self.frame.width - dollarSignButton.bounds.width - menuButton.bounds.width - 35
        let labelHeight: CGFloat = self.frame.height
        
        expenseTextField.font = .systemFont(ofSize: 15, weight: .medium)
        expenseTextField.backgroundColor = .clear // Set the background color
        expenseTextField.textColor = UIColor(named: "reversed Color") // Set the text color
        expenseTextField.textAlignment = .left
        expenseTextField.keyboardType = .numberPad
        expenseTextField.frame = CGRect(
            x: 10 + menuButton.bounds.width + 10,
            y: -5,
            width: labelWidth,
            height: labelHeight
        )
        return expenseTextField
    }()
    
    private func propertyConfigure() {
        //MARK: - searchBar
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 2
        self.layer.shadowOpacity = 0.3
            
        self.addSubview(label)
        
        //MARK: - searchBar
        searchBar.placeholder = "Search Currency"
        searchBar.showsCancelButton = false // or true, depending on your preference
        searchBar.delegate = self
        
        let labelWidth: CGFloat = 90
        let labelHeight: CGFloat = 40
        
        searchBar.frame = CGRect(
            x: 10,
            y: self.frame.height / 2 - labelHeight / 2 - 5,
            width: labelWidth,
            height: labelHeight
        )
        
        //menuButton.addSubview(searchBar)
        //MARK: - dollarSignButton
        
        //dollarSignButton.contentHorizontalAlignment = .center
        dollarSignButton.frame = CGRect(x: 0, y: 2, width: 60, height: self.frame.height-15)
        dollarSignButton.titleLabel?.textAlignment = .center
        dollarSignButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        dollarSignButton.layer.cornerRadius = 15
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "hand.point.up.left.fill")
        imageAttachment.image = imageAttachment.image?.withTintColor(UIColor(named: "gray Color")!)
        let imageString = NSAttributedString(attachment: imageAttachment)

        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(imageString)
        dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
        dollarSignButton.translatesAutoresizingMaskIntoConstraints = true
        
        self.bringSubviewToFront(dollarSignButton)
        
        dollarSignButton.layer.shadowColor = UIColor(named: "gray Color")?.cgColor
        dollarSignButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        dollarSignButton.layer.shadowRadius = 1
        dollarSignButton.layer.shadowOpacity = 0.3
        
        //MARK: - indexImageView
        indexImageView.isHidden = false
        
        //MARK: - expenseView
        expenseView.isHidden = false // Initially hidden
        expenseView.layer.cornerRadius = 15
        expenseView.backgroundColor = .systemGray4
        
        expenseView.translatesAutoresizingMaskIntoConstraints = false
        expenseView.widthAnchor.constraint(equalToConstant: self.frame.width - dollarSignButton.frame.width - 5).isActive = true
        
        expenseView.addSubview(menuButton)
        expenseView.addSubview(expenseTextField)
        
        expenseView.bringSubviewToFront(expenseTextField)
        
        self.addSubview(expenseView)
        self.bringSubviewToFront(expenseView)
        
        //MARK: - expenseTextField
        expenseTextField.delegate = self
        expenseTextField.placeholder = "i.e. 800".localized()
        
        self.backgroundColor = .red
    }
    
    override func awakeFromNib() {
        
        propertyConfigure()
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: indexImageView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: indexImageView.trailingAnchor),
            label.topAnchor.constraint(equalTo: indexImageView.topAnchor),
            label.bottomAnchor.constraint(equalTo: indexImageView.bottomAnchor),
            
            expenseView.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: 2),
            expenseView.topAnchor.constraint(equalTo: self.topAnchor),
            expenseView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            expenseTextField.leadingAnchor.constraint(equalTo: expenseView.leadingAnchor),
            expenseTextField.trailingAnchor.constraint(equalTo: expenseView.trailingAnchor),
            expenseTextField.topAnchor.constraint(equalTo: expenseView.topAnchor),
            expenseTextField.bottomAnchor.constraint(equalTo: expenseView.bottomAnchor),
            
            dollarSignButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -3),
            dollarSignButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            dollarSignButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        //NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardUp), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDown), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardUp(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            let offsetY = self.textFieldYInWindow! - keyboardHeight - 70

            let halfScreenHeight = UIScreen.main.bounds.height/2

                if offsetY < 0 {
                    UIView.animate(withDuration: 0.3) {
                        self.transform = CGAffineTransform(translationX: 0, y: -offsetY)
                    }
                }
            
        }
        
    }

    @objc func keyboardDown() {
        //self.transform = .identity
        DispatchQueue.main.async {
                // 편집이 끝났을 때 collectionView를 원래 위치로 복원
                if let collectionView = self.superview as? UICollectionView {
                    collectionView.transform = .identity
                }
            }
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    @IBAction func dollarSignButtonPressed(_ sender: UIButton) {
        
        if let collectionView = self.superview as? UICollectionView {
            if let indexPath = collectionView.indexPath(for: self) {

                self.indexPath = indexPath
               
            }
        }
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "hand.point.up.left.fill")
        imageAttachment.image = imageAttachment.image?.withTintColor(UIColor(named: "gray Color")!)
        let imageString = NSAttributedString(attachment: imageAttachment)
        let textString = NSAttributedString(string: "Tap\nto save".localized())

        let mutableAttributedString1 = NSMutableAttributedString()
        mutableAttributedString1.append(imageString)
        
        let mutableAttributedString2 = NSMutableAttributedString()
        mutableAttributedString2.append(textString)

        guard let titleLabelText = sender.titleLabel?.text else { return }
        
        DispatchQueue.main.async {
            self.recentAction.title = currencyTitle
            self.updateMenu()
            
            if let collectionView = self.superview as? UICollectionView {
                let visibleIndexPaths = collectionView.indexPathsForVisibleItems
                for indexPath in visibleIndexPaths {
                    if let cell = collectionView.cellForItem(at: indexPath) as? tripCollectionViewCell {
                        
                        if !self.isPickerViewSelected {
                            cell.dollarSignButton.isUserInteractionEnabled = false
                            self.dollarSignButton.setAttributedTitle(mutableAttributedString2, for: .normal)
                            //collectionView.isScrollEnabled = false
                            
                        } else {
                            cell.dollarSignButton.isUserInteractionEnabled = true
                            
                            self.dollarSignButton.setAttributedTitle(mutableAttributedString1, for: .normal)
                            //collectionView.isScrollEnabled = true
                            
                        }
                    }
                    
                    // Enable user interaction for the clicked cell's dollarSignButton
                    sender.isUserInteractionEnabled = true
                }
                
                if !self.isPickerViewSelected {
                    collectionView.isScrollEnabled = false
                } else {
                    collectionView.isScrollEnabled = true
                    //NotificationCenter.default.removeObserver(self)
                    
                }
            }
        }
        
        textFieldMenuConfigure(titleLabelText)
        
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func dateConfigure() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: tripStartDate!) // Remove time portion
        let endDate = calendar.startOfDay(for: tripEndDate!)
        
        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
        let monthsComponents = calendar.dateComponents([.month], from: startDate, to: endDate)
        
        let months = monthsComponents.month
        let days = dayComponents.day
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d (E)"
        
        var currentDate = startDate
        
        timeInterval.append(dateFormatter.string(from: currentDate))
        for _ in 0..<days! {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            timeInterval.append(dateFormatter.string(from: currentDate))
        }
    }
    
    func textFieldMenuConfigure(_ titleLabelText: String) {
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "hand.point.up.left.fill")
        imageAttachment.image = imageAttachment.image?.withTintColor(UIColor(named: "gray Color")!)
        let imageString = NSAttributedString(attachment: imageAttachment)

        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(imageString)
        
        guard let scheduleUID = scheduleUID else {
            return
        }
        
        var money: Double?
        
        if let text0 = menuButton.titleLabel?.text {
            
            if text0 == "Set Currecncy".localized() {
                print("111111")
                
                dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
                
            } else {
                
                if let text1 = expenseTextField.text {
                    if let moneyValue = Double(text1){
                        // 숫자로 변환 가능한 경우
                        money = moneyValue
                        
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                        ]
                        
                        let attributedString = NSMutableAttributedString(string: "\(text0)\n\(text1)", attributes: attributes)
                        
                        let rangeOfSecondLine = ("\(text0)\n\(text1)" as NSString).range(of: text1)
                        
                        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: rangeOfSecondLine)
                        print("22222")
                        dollarSignButton.setAttributedTitle(attributedString, for: .normal)
                        
                    } else { // 숫자로 변환이 불가능한 경우
                        if text1 != "" {
                            expenseTextField.text = ""
                            NotificationCenter.default.post(name: Notification.Name("noNumberAlert"), object: nil)
                            
                        } else {
                            
                            //NotificationCenter.default.post(name: Notification.Name("noNumberAlert"), object: nil)
                            
                            let attributedString: NSMutableAttributedString
                            let rangeOfSecondLine: NSRange
                            
                            if expenseTextField.text == "" {
                                                        
                                dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
                                
                            } else {
                                print("expenseTextField.text != ")
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)
                                ]
                                
                                let attributedString = NSMutableAttributedString(string: "\(text0)\n", attributes: attributes)
                                
                                let rangeOfSecondLine = ("\(text0)\n" as NSString).range(of: "")
                                
                                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: rangeOfSecondLine)

                                dollarSignButton.setAttributedTitle(attributedString, for: .normal)
                            }
                        }
                    }
                } else {
                    print("Error 나타남")
                }
                
            }
        } else {
           
            dollarSignButton.setAttributedTitle(mutableAttributedString, for: .normal)
        }
        
        expenseView.isHidden = false
        expenseTextField.isHidden = false
        
        // 애니메이션 블록
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            if !self.isPickerViewSelected { // PickerView 클릭되지 않음
                
                self.expenseView.transform = self.endTransform
                
            } else { // PickerView 클릭
                
                self.expenseView.transform = self.startTransform
                
                if let menuButtonText = self.menuButton.titleLabel?.text {
                    if menuButtonText != "Set Currecncy".localized() {
                        
                        guard let money = money else {
                            return
                        }
                        
                        let addExpense = TripForExpense(scheduleUID: scheduleUID, tripsStartDate: self.tripStartDate, tripEndDate: self.tripEndDate, money: money, currecncy: menuButtonText)
                        
                        print("addExpense: \(addExpense)")
                        
                        let realm = try! Realm()
                        do {
                            try realm.write {
                                if realm.object(ofType: TripForExpense.self, forPrimaryKey: addExpense.scheduleUID) != nil {
                                    // 이미 존재하는 경우, 업데이트 시도
                                    print("이미 존재하는 경우, 업데이트 시도")
                                    realm.add(addExpense, update: .modified)
                                } else {
                                    // 존재하지 않는 경우, 새로 추가
                                    print("존재하지 않는 경우, 새로 추가")
                                    realm.add(addExpense)
                                }
                            }
                        } catch {
                            // 오류 처리
                        }
                    }
                }

                if let collectionView = self.superview as? UICollectionView,
                   let indexPath = collectionView.indexPath(for: self) {
                    print("진입 완료!!")
                    
                    NotificationCenter.default.post(name: Notification.Name("tripCollectionViewHeaderReload"), object: nil, userInfo: ["indexPath" : indexPath])
                }
                
                self.loadTripForExpense {
                    if let collectionView = self.superview as? UICollectionView{
                        DispatchQueue.main.async {
                            collectionView.reloadData()
                        }
                    }
                }
            }
        }, completion: { _ in
            self.isPickerViewSelected.toggle()
            
        })
    }
}

extension tripCollectionViewCell : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textFieldDidBeginEditing")
        DispatchQueue.main.async {
            
            if let window = self.window?.windowScene?.windows.first {
                let textFieldInWindow = self.convert(textField.frame.origin, to: window)
                
                // 이제 textFieldInWindow의 Y 좌표를 확인할 수 있습니다.
                let textFieldYInWindow = textFieldInWindow.y

                self.textFieldYInWindow = textFieldYInWindow
                
                let halfScreenHeight = UIScreen.main.bounds.height/2
                let offsetY = self.textFieldYInWindow! - halfScreenHeight - 60

                if offsetY > 0 {

                    UIView.animate(
                        withDuration: 0.3,
                        animations:  {
                            //self.transform = CGAffineTransform(translationX: 0, y: -offsetY)
                            if let collectionView = self.superview as? UICollectionView {
                                collectionView.transform = CGAffineTransform(translationX: 0, y: -offsetY)
                            }
                            
                            
                        }
                    )
                }

            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing")
        DispatchQueue.main.async {
            // 편집이 끝났을 때 collectionView를 원래 위치로 복원
            if let collectionView = self.superview as? UICollectionView {
                collectionView.transform = .identity
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 입력된 문자열이 숫자로만 구성되어 있는지 확인
        if string.isEmpty {
            // 빈 칸이 입력되었을 때의 처리
            print("빈 칸 입력됨")
            return true // 빈 칸 허용
        } else if string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
            // 숫자가 아닌 문자가 입력되었을 때의 처리
            print("숫자가 아닌 문자 입력됨")
            NotificationCenter.default.post(name: Notification.Name("noNumberAlert"), object: nil)
            return false // 숫자가 아닌 문자는 허용하지 않음
        } else {
            
            return true // 숫자가 입력된 경우에만 허용
        }
    }

}

extension tripCollectionViewCell : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    }
}
