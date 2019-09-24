//
//  mainViewController.swift
//  RectangleDetection-coreImage
//
//  Created by Shine on 2018/11/21.
//  Copyright © 2018  All rights reserved.
//

import UIKit

class DTAICameraSlider: UISlider {

    
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.origin.x, y: bounds.size.height/2)
        
        
        let customBounds = CGRect(origin: point, size: CGSize(width: bounds.size.width, height: 4.0))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }

}
