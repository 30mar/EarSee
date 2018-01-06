//
//  RoundedShadowView.swift
//  See
//
//  Created by Macbook on 12/21/17.
//  Copyright © 2017 Macbookodev. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }
}
