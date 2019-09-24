

import Vision

@available(iOS 11.0, *)
extension VNRectangleObservation {
    
    //Mark : 計算兩點之間距離 並且比較 , 請改變容許值areaRating , 以點半徑20話畫圓圈 , 必須四個點都在容許直之內
    private func caculateTwoPointDistance(pointFirst : CGPoint , pointSecond: CGPoint , allowableValue : CGFloat) -> Bool{
        
        let deltaX = pointFirst.x - pointSecond.x
        let deltaY = pointFirst.y - pointSecond.y
        
        let distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
              
        return distance <= allowableValue
    }
    
    //計算所有四個點是否在容許值之內
    func comapreTowObservationInRange(target : VNRectangleObservation , toSize : CGSize , allowableValue : CGFloat) -> Bool
    {
        
        let ObservationAry = ["topLeft", "topRight","bottomLeft","bottomRight"]
        
        
        for key in ObservationAry
        {
            let point1 = self.value(forKey: key) as! CGPoint
            let point2 = target.value(forKey: key) as! CGPoint
            
            guard  caculateTwoPointDistance(pointFirst: point1.scaled(to: toSize), pointSecond: point2.scaled(to: toSize), allowableValue: allowableValue) else
                
            {
                return false
            }
        }
        
        return true
        
    }
    
}
