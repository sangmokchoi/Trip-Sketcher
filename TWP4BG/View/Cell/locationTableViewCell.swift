//
//  locationTableViewCell.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/20.
//

import UIKit
import MapKit

class locationTableViewCell: UITableViewCell {

    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    
    var mapItems: [MKMapItem]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
