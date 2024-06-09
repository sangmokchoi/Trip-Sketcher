//
//  EntryTripViewController.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import UIKit
import StoreKit
import SafariServices

var loadingViewLabelText = ""

class IAPViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleTextView: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var explationLabel: UILabel!
    @IBOutlet weak var subscriptionButton: UIButton!
    @IBOutlet weak var nonConsumableButton: UIButton!
    
    @IBOutlet weak var subscriptionGuideButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    private var products = [SKProduct]()
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .portrait // 뷰 컨트롤러를 세로 방향 고정으로 설정
//    }
//    
//    override var shouldAutorotate: Bool {
//        return false // 회전을 막음
//    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
    }
     override var shouldAutorotate: Bool {
            return true
    }
    
    var purchasedPoint : [Int] = []
    var purchasedTime : [Date] = []
    var restoredTransactions: [SKPaymentTransaction] = []
    
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    lazy var PurchasedtableView: UITableView = {
        let PurchasedtableView = UITableView(frame:CGRect(
                x: (UIScreen.main.bounds.width - (UIScreen.main.bounds.width - 30)) / 2,
                y: 200,
                width: UIScreen.main.bounds.width - 30,
                height: UIScreen.main.bounds.height / 2 + 40))
        PurchasedtableView.backgroundColor = .darkGray
        PurchasedtableView.alpha = 1.0
        PurchasedtableView.bounces = false
        PurchasedtableView.isHidden = true
        return PurchasedtableView
    }()
    
    lazy var loadingView: UIView = {
        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        loadingView.backgroundColor = UIColor(named: "gray Color")?.withAlphaComponent(0.6)
        loadingView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)

        return loadingView
    }()
    
    lazy var loadingViewLabel: UILabel = {
        let loadingViewLabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        loadingViewLabel.font = .systemFont(ofSize: 15, weight: .light)
        loadingViewLabel.textColor = .white//UIColor(named: "AccentTintColor")
        loadingViewLabel.tintColor = .white
        loadingViewLabel.textAlignment = .center
        loadingViewLabel.numberOfLines = 2

        return loadingViewLabel
    }()
    
    lazy var Xbutton: UIButton = {
        let Xbutton = UIButton(frame: CGRect(x: PurchasedtableView.bounds.width - 50, y: PurchasedtableView.bounds.minY, width: 50, height: 50))
        
        let XbuttonImage = UIImage(systemName: "xmark.circle.fill")?.withTintColor(.black, renderingMode: .alwaysTemplate)
            
        Xbutton.setImage(XbuttonImage, for: .normal)
        Xbutton.tintColor = UIColor(named: "reversed Color")
        Xbutton.setTitleColor(.white, for: .normal)
        Xbutton.addTarget(self, action: #selector(XbuttonTapped(_:)), for: .touchUpInside)

        return Xbutton
    }()
    
    @objc func XbuttonTapped(_ sender: UIButton) {
        print("Button Tapped!")
        DispatchQueue.main.async {
            
            self.PurchasedtableView.isHidden = true
            
            self.subscriptionButton.isUserInteractionEnabled = true
            self.nonConsumableButton.isUserInteractionEnabled = true
            self.restoreButton.isUserInteractionEnabled = true

            self.Xbutton.removeFromSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        //UINavigationController.setNeedsUpdateOfSupportedInterfaceOrientations(self)
        
        configure()
        titleConfigure()
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopLoadingView), name: NSNotification.Name(rawValue: "IAPVCloadingIsDone"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startLoadingView), name: NSNotification.Name(rawValue: "IAPVCloadingIsStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(titleConfigure), name: NSNotification.Name(rawValue: "titleConfigure"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RestoreProcessIsDone), name: NSNotification.Name(rawValue: "RestoreProcessIsDone"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchased), name: NSNotification.Name(rawValue: "purchased"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failed), name: NSNotification.Name(rawValue: "failed"), object: nil)

        MyProducts.iapService.getProducts { [weak self] success, products in
            print("load products: \(products ?? [])")
            
            guard let ss = self else { return }
            if success, let products = products {
                DispatchQueue.main.async {
                    ss.products = products

                    // 여기가 완료된 다음에 버튼이 클릭되어야만 구매가 정상 작동함
                    NotificationCenter.default.post(name: Notification.Name("IAPVCloadingIsDone"), object: nil)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(handlePurchaseNoti(_:)),
              name: .iapServicePurchaseNotification,
              object: nil
        )

    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {

        appDelegate.shouldSupportAllOrientation = false

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("IAP viewWillDisappear")
        
        appDelegate.shouldSupportAllOrientation = true
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("loadIAPDataForCheck"), object: nil)
        }
            
    }

    
    @objc func titleConfigure() {
        DispatchQueue.main.async {
            
            if iapDatas != [] {
                
                for iapData in iapDatas {
                    
                    if iapData.type == "Non-Consumable" { // 비소모성 구매
                        // 비소모성 구매를 완료했으므로, triplist 2개 이상 사용 가능
                        // performSegue 허용
                        DispatchQueue.main.async {
                            self.titleLabel.text = "\("US 4.99$ / Unlimited Access".localized())"+" \("Purchased".localized())"
                        }
                        print("titleConfigure")
                        //"US 0.99$ / Monthly Subscription" = "US 0.99$ / 월 구독"; // subscriptionButton
                        break
                    } else { // 구독
                        // Date(timeIntervalSince1970: iapData.expiresDate)
                        if iapData.expiresDate! > Date() {
                            // 구독 정보 중 아직 구독 만료일이 도래하지 않은 값이 있으므로, triplist 2개 이상 사용 가능
                            // performSegue 허용
                            DispatchQueue.main.async {
                                self.titleLabel.text = "\("US 0.99$ / Monthly Subscription".localized())"+" \("Purchased".localized())"
                            }
                            break
                            
                        } else {
                            // 구독 정보 중 구독 만료 됨
                            DispatchQueue.main.async {
                                self.titleLabel.text = "Add and manage your itinerary unlimitedly\nwith a monthly subscription\nor one-time purchase".localized()
                            }
                        }
                        
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    self.titleLabel.text = "Add and manage your itinerary unlimitedly\nwith a monthly subscription\nor one-time purchase".localized()
                }
            }
        }
        
    }
    
    private func configure() {
        
        startLoadingView()
        
        subscriptionButton.setTitle("US 0.99$ / Monthly Subscription".localized(), for: .normal)
        nonConsumableButton.setTitle("US 4.99$ / Unlimited Access".localized(), for: .normal)
        //imageView.backgroundColor = .blue
        //imageView.layer.cornerRadius = 20
        
        subscriptionButton.layer.shadowColor = UIColor.black.cgColor
        subscriptionButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        subscriptionButton.layer.shadowRadius = 2
        subscriptionButton.layer.shadowOpacity = 0.5
        
        nonConsumableButton.layer.shadowColor = UIColor.black.cgColor
        nonConsumableButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        nonConsumableButton.layer.shadowRadius = 2
        nonConsumableButton.layer.shadowOpacity = 0.5
        
        explationLabel.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
        explationLabel.layer.shadowColor = UIColor.black.cgColor
        explationLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        explationLabel.layer.shadowRadius = 2
        explationLabel.layer.shadowOpacity = 0.5
        
        PurchasedtableView.delegate = self
        PurchasedtableView.dataSource = self
        PurchasedtableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        PurchasedtableView.addSubview(self.Xbutton)
        
        view.addSubview(self.PurchasedtableView)
        view.bringSubviewToFront(self.PurchasedtableView)
        
        NSLayoutConstraint.activate([
            PurchasedtableView.topAnchor.constraint(equalTo: subtitleTextView.bottomAnchor),
            PurchasedtableView.bottomAnchor.constraint(equalTo: nonConsumableButton.bottomAnchor),
            
            Xbutton.trailingAnchor.constraint(equalTo: PurchasedtableView.trailingAnchor, constant: -5),
            Xbutton.topAnchor.constraint(equalTo: PurchasedtableView.topAnchor, constant: 0)
        ])
        
        // 구독 또는 아이템을 구매했을 때에는 해당 아이템의 이름으로 text가 바뀌어야 함
        
            
        //titleLabel.text = "Pro Version Upgrade"
        //subtitleLabel.text = "Add and manage your itinerary unlimitedly\nwith a monthly subscription\nor one-time purchase".localized()
        subscriptionGuideButton.titleLabel?.numberOfLines = 2
        subscriptionGuideButton.titleLabel?.lineBreakMode = .byWordWrapping
        subscriptionGuideButton.setTitle("How to cancel\na subscription".localized(), for: .normal)
        
        restoreButton.setTitle("Restore".localized(), for: .normal)
        
        explationLabel.text = " - If you make a purchase decision, the payment will be processed through your Apple iTunes account\n - If you do not cancel at least 24 hours before the end of the current subscription period, it will automatically renew for the next month\n - Within 24 hours of the end of the current subscription period, the service fee will be charged to your iTunes account, and the renewal fee will be confirmed\n - After purchase, you can manage and cancel your subscription in your iTunes account settings".localized()
        
        let attributedString = NSMutableAttributedString(string: " - "+"Privacy Policy".localized() + "\n - " + "Terms of Use".localized())

        // 클릭 가능한 버튼의 속성 설정
        let buttonRange1 = (attributedString.string as NSString).range(of: "Privacy Policy".localized())
        let buttonRange2 = (attributedString.string as NSString).range(of: "Terms of Use".localized())
        
        let buttonAttributes1: [NSAttributedString.Key: Any] = [
            .link: URL(string: "https://sites.google.com/view/tripsketcher-privacypolicy-en/%ED%99%88".localized())!, // 버튼 클릭 시 호출되는 URL 설정
            .backgroundColor: UIColor.clear,
            .foregroundColor: UIColor.systemBlue,
            .strokeColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.thick // 버튼의 밑줄 스타일 설정
        ]
        let buttonAttributes2: [NSAttributedString.Key: Any] = [
            .link: URL(string: "https://sites.google.com/view/tripsketcher-terms-en/%ED%99%88".localized())!, // 버튼 클릭 시 호출되는 URL 설정
            .backgroundColor: UIColor.clear,
            .foregroundColor: UIColor.systemBlue,
            .strikethroughColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.thick // 버튼의 밑줄 스타일 설정
        ]
        attributedString.addAttributes(buttonAttributes1, range: buttonRange1)
        attributedString.addAttributes(buttonAttributes2, range: buttonRange2)

        subtitleTextView.attributedText = attributedString

        // UITextView의 delegate를 설정하여 버튼 클릭 이벤트를 처리합니다.
        subtitleTextView.delegate = self
    }
    
    @IBAction func subscriptionButtonPressed(_ sender: UIButton) {
        // Trip Sketcher Subscription
        let filteredProducts = products.filter { $0.productIdentifier == MyProducts.productID1 }

        if let product = filteredProducts.first {

            MyProducts.iapService.buyProduct(product)

        } else {
            alert(title: "Error".localized(), message: "Try again later".localized(), actionTitle: "OK".localized())
        }
    }
    
    @IBAction func nonConsumableButtonPressed(_ sender: UIButton) { // Trip Sketcher Non-Consumable
        
        let filteredProducts = products.filter { $0.productIdentifier == MyProducts.productID2 }

        if let product = filteredProducts.first {
                
            MyProducts.iapService.buyProduct(product)

        } else {
            alert(title: "Error".localized(), message: "Try again later".localized(), actionTitle: "OK".localized())
        }
    }
    
    @IBAction func subscriptionGuideButtonPressed(_ sender: UIButton) {
        if let url = URL(string: "https://support.apple.com/en-us/HT202039".localized()) {
            let URL = url
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            let safariVC = SFSafariViewController(url: URL, configuration: config)
            safariVC.transitioningDelegate = self
            safariVC.modalPresentationStyle = .pageSheet
            
            present(safariVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func restoreButtonPressed(_ sender: UIButton) {
        
        DispatchQueue.main.async {

            self.startLoadingView()
            self.subscriptionButton.isUserInteractionEnabled = false
            self.nonConsumableButton.isUserInteractionEnabled = false
            self.restoreButton.isUserInteractionEnabled = false
            
            MyProducts.iapService.restorePurchases() {
                self.loadIAPData() {
                    print("self.loadIAPDat 종료")
                }
            }
        }
    }
    
    @objc func RestoreProcessIsDone() {
        alert(title: "Notification".localized(), message: "Restore process is Done".localized(), actionTitle: "OK".localized())
    }
    
}

extension IAPViewController : UITextViewDelegate {
    
}

extension IAPViewController {

    @objc func startLoadingView() {
        DispatchQueue.main.async {
            
            self.loadingView.addSubview(self.loadingIndicator)
            self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                self.loadingIndicator.centerXAnchor.constraint(equalTo: self.loadingView.centerXAnchor),
                self.loadingIndicator.centerYAnchor.constraint(equalTo: self.loadingView.centerYAnchor)
            ])
            
            self.loadingViewLabel.text = loadingViewLabelText
            
            self.loadingView.addSubview(self.loadingViewLabel)
            self.view.bringSubviewToFront(self.loadingViewLabel)
            self.loadingViewLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                self.loadingViewLabel.centerXAnchor.constraint(equalTo: self.loadingView.centerXAnchor),
                self.loadingViewLabel.centerYAnchor.constraint(equalTo: self.loadingView.centerYAnchor, constant: -50),
                self.loadingViewLabel.widthAnchor.constraint(equalToConstant: 250),
                self.loadingViewLabel.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            self.loadingIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
            self.view.addSubview(self.loadingView)
        }
        
    }

    
    @objc func stopLoadingView() {
        DispatchQueue.main.async {
            // Hide loading indicator
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.removeFromSuperview()
            self.loadingViewLabel.removeFromSuperview()
            
            loadingViewLabelText = "Processing\nPlease wait a moment".localized()
            
            // Enable user interaction
            self.subscriptionButton.isUserInteractionEnabled = true
            self.nonConsumableButton.isUserInteractionEnabled = true
            self.restoreButton.isUserInteractionEnabled = true
            self.view.isUserInteractionEnabled = true
            self.loadingView.removeFromSuperview()
        }
    }
    
    @objc func purchased() {
        DispatchQueue.main.async {
            self.alert(title: "Notification".localized(), message: "Purchase completed".localized(), actionTitle: "OK".localized())
        }
    }
    
    @objc func failed() {
        DispatchQueue.main.async {
            self.alert(title: "Notification".localized(), message: "Purchase failed".localized(), actionTitle: "OK".localized())
        }
    }
    
    
    @objc private func handlePurchaseNoti(_ notification: Notification) {
        print("handlePurchaseNoti 진입")
        print("notification : \(notification)")
      guard  let productID = notification.object as? String,
        let index = self.products.firstIndex(where: { $0.productIdentifier == productID })
      else { return }
        print("handlePurchaseNoti productID: \(productID)")
        print("handlePurchaseNoti index: \(index)")

    }
    
}

extension IAPViewController : UITableViewDelegate, UITableViewDataSource {
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let placeholderLabel = UILabel(frame: CGRect(x: 0, y: 0 + 15, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        placeholderLabel.text = "구매내역이 없습니다"
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .white
        
        if self.purchasedPoint.count == 0 {
            DispatchQueue.main.async {
                tableView.backgroundView = placeholderLabel
            }
        } else {
            DispatchQueue.main.async {
                tableView.backgroundView = nil
            }
        }
        return self.purchasedPoint.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.textColor = UIColor.white
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        cell.detailTextLabel?.text = "Purchased Time: \(dateFormatter.string(from: purchasedTime[indexPath.row]))"
        cell.detailTextLabel?.textColor = UIColor.white
        
        cell.backgroundColor = UIColor.gray
        cell.selectionStyle = .none
        
        if self.purchasedPoint.count != 0 {
                cell.textLabel?.text = "Purchased Point: \(purchasedPoint[indexPath.row])"
                cell.detailTextLabel?.text = "Purchased Time: \(dateFormatter.string(from: purchasedTime[indexPath.row]))"
            } else {
                cell.textLabel?.text = "Please wait a moment".localized()
                cell.detailTextLabel?.text = nil
            }
        
        cell.textLabel?.textColor = UIColor(named: "reversed Color")
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return print("indexPath.row: \(indexPath.row)")
    }
}

extension IAPViewController : UIViewControllerTransitioningDelegate {
    
}
