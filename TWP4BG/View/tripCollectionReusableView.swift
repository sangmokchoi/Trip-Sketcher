//
//  tripCollectionReusableView.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/23.
//

import UIKit

class tripCollectionHeaderView: UICollectionReusableView {
    
    static let identifier = "tripCollectionHeaderView"
    var expenseLabelText: String = ""
    
    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: self.frame.width - 20, height: self.frame.height))
        label.text = "".uppercased()
        label.textAlignment = .left
        label.textColor = UIColor(named: "reversed Color")
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    lazy var expenseTextView: UITextView = {
        let width: CGFloat = 150
        let height: CGFloat = 180
        
        let expenseTextView = UITextView(frame: CGRect(x: self.frame.width - width - 10, y: 10, width: width, height: 0))
        
        expenseTextView.text = "".uppercased()
        expenseTextView.textAlignment = .right
        expenseTextView.backgroundColor = .clear
        expenseTextView.textColor = UIColor(named: "reversed Color")
        expenseTextView.showsVerticalScrollIndicator = true
        expenseTextView.isEditable = false
        expenseTextView.isScrollEnabled = true
        expenseTextView.bounces = true
        
        expenseTextView.font = .systemFont(ofSize: 12, weight: .light)

        return expenseTextView
    }()
    
    func configure() {
        
        //print("configure 진입")
        
//        expenseTextView.removeFromSuperview()
//        label.removeFromSuperview()
        
        backgroundColor = .clear
        expenseTextView.delegate = self
        
        addSubview(label)
        addSubview(expenseTextView)
        //expenseTextView.alignTextVerticallyInContainer()
        //expenseTextViewConfigure()
        
        let width: CGFloat = 150
        let sizeThatFits = expenseTextView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        
        expenseTextView.frame.size.height = sizeThatFits.height
        expenseTextView.contentSize = sizeThatFits
        
        expenseTextView.text = expenseLabelText
        
        sendSubviewToBack(label)
        sendSubviewToBack(expenseTextView)
        
    }
    
    func expenseTextViewConfigure() {
        DispatchQueue.main.async {
            //self.expenseTextView.removeFromSuperview()
            self.expenseTextView.text = ""
            
            let width: CGFloat = 150
            let sizeThatFits = self.expenseTextView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            
            self.expenseTextView.frame.size.height = sizeThatFits.height
            self.expenseTextView.contentSize = sizeThatFits
            
            self.expenseTextView.text = self.expenseLabelText
            
            self.addSubview(self.expenseTextView)
        }
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()

    }
}

extension tripCollectionHeaderView : UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {

        let size = CGSize(width: self.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        textView.constraints.forEach { (constraint) in

            if estimatedSize.height <= self.frame.height {

            }
            else {
                if constraint.firstAttribute == .height {
                    constraint.constant = estimatedSize.height
                }
            }
        }
    }
}


extension UITextView {
    
    func alignTextVerticallyInContainer() {
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale)
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        self.contentInset.top = topCorrect
    }
}
