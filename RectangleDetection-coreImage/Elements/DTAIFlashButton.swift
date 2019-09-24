//
//  mainViewController.swift
//  RectangleDetection-coreImage
//
//  Created by Shine on 2018/11/27.
//  Copyright © 2018年  All rights reserved.
//

import UIKit

class DTAIFlashButton: UIButton {

    var isOn = false
    
    override func awakeFromNib() {
        self.setImage(UIImage(named: "flashOff"), for: .normal)
        self.addTarget(self, action: #selector(DTAIFlashButton.buttonClicked(_:)), for: .touchUpInside)
    }

    @objc func buttonClicked(_ sender: UIButton) {
        self.isOn = !self.isOn
        if isOn
        {
            self.setImage(UIImage(named: "flashOn"), for: .normal)
        }
        else
        {            
            self.setImage(UIImage(named: "flashOff"), for: .normal)
        }
    }
}
