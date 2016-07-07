//
//  WeatherCell.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 05/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit

class WeatherCell: UITableViewCell {

    @IBOutlet var place: UILabel!
    
    @IBOutlet var temperature: UILabel!
    @IBOutlet var weatherIcon: UIImageView!
    @IBOutlet var precipitation: UILabel!
    
    @IBOutlet var windSpeed: UILabel!    
    @IBOutlet var windDirection: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
