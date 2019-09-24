//
//  RectangleDetection-coreImage
//
//  Created by Shine on 2019/1/30.
//  Copyright © 2019  All rights reserved.
//

import Foundation
import UIKit
extension CGPoint {
    
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
    
    func scaleToSize(to size:DTAICorpScale) ->CGPoint
    {
        
        let tansfer = CGAffineTransform(scaleX: size.scaleX!, y: size.scaleY!)
        
        return self.applying(tansfer)
    }
    
    //MARK : 轉換到笛卡爾座標系統
    func cartesianForPoint(extent:CGSize) -> CGPoint {
        return CGPoint(x: self.x,y: extent.height - self.y)
    }
}
