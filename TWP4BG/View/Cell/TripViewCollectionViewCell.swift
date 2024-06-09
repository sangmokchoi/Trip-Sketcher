//
//  TripViewCollectionViewCell.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/09.
//

import UIKit

class TripViewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var circleImageView: UIImageView!
    @IBOutlet weak var tripDateLabel: UILabel!
    @IBOutlet weak var selectionBarImageView: UIView!
    
    var clickCount: Int = 0 {
        didSet {
            if clickCount == 0 {
                DispatchQueue.main.async {
                    self.clipsToBounds = false
                   
                    self.tripDateLabel.backgroundColor = UIColor.clear
                    self.tripDateLabel.font = .systemFont(ofSize: 17, weight: .light)
                    self.selectionBarImageView.backgroundColor = .lightGray
                    
                    var frame = self.selectionBarImageView.frame
                                    frame.size.height = 1
                    self.selectionBarImageView.frame = frame
                    self.isSelected = false
                    
                }
            } else {
                DispatchQueue.main.async {
//                    self.tripDateLabel.backgroundColor = UIColor(hex: "E3582D")?.withAlphaComponent(0.6)
                    
                    self.tripDateLabel.font = .systemFont(ofSize: 17, weight: .medium)
                    var frame = self.selectionBarImageView.frame
                                    frame.size.height = 5
                    self.selectionBarImageView.backgroundColor = UIColor(named: "reversed Color")
                    self.selectionBarImageView.frame = frame
                    self.isSelected = true
                }
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if !isSelected {
                self.clickCount = 0
            } else {
                self.clickCount = 1
            }
        }
    }
    
    override func awakeFromNib() {
//        let dateString = tripDateLabel.text
//        print("dateString: \(dateString)")
//        let color = returnColor(dateString!)
//        print("color: \(color)")
//        circleImageView.tintColor = colorSelection(color)
    }
}
