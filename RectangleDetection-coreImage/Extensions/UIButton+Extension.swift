//
//  UIButton+Extension.swift
//  RectangleDetection-coreImage
//
//  Created by Shine on 2019/2/12.
//  Copyright © 2019  All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class camButton : UIButton{
    
    @IBInspectable var borderColor : UIColor {
        get{
            return UIColor(cgColor: layer.borderColor!)
        }
        
        set{
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var borderWidth : CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue > 0 ? newValue : 0
        }
    }
    
}
