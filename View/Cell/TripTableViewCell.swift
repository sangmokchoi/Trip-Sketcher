//
//  TripTableViewCell.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import UIKit

class TripTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tripListTitleLabel: UILabel!
    @IBOutlet weak var tripListSubTitleLabel: UILabel!
    
    @IBOutlet weak var tripListPlaceLabel: UILabel!
    @IBOutlet weak var tripListDateLabel: UILabel!
    @IBOutlet weak var tagColorImageView: UIImageView!
    
    @IBOutlet weak var setButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .light)
        let image = UIImage(systemName: "square.and.arrow.up", withConfiguration: imageConfig)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func setButtonPressed(_ sender: UIButton) {
        print("hello")
        
    }
    
}
