//
//
//  Created by Shine on 2018/10/01.
//  Copyright © 2018  All rights reserved.
//

import Foundation
import CoreML
import UIKit

@objc public enum DTAIPictureMode : Int {
    case Credicials   , Normal , Custom
}

public class DTAITools: NSObject {
    
   static var orientation : UIInterfaceOrientationMask = .landscape
    
    // MARK: 取得mlModel
    @available(iOS 11.0, *)
    @objc public static func initMLModel(ModelName : String) -> MLModel? {
        
        do{
            let url = Bundle.main.url(forResource: ModelName, withExtension: "mlmodelc")
            
            print(url!.absoluteURL)
            let model : MLModel =  try  MLModel(contentsOf:   url!)
            return model
        }catch{
            print("cannot find the model")
            return nil
        }
    }
    
    @objc public static func getInitRotation() ->UIInterfaceOrientationMask{
        return orientation
    }    
    
    
    @objc public static func initAICameraController(
        IdentifyName : String ,
        Model : MLModel? ,
        maxPicture : Int ,
        mode : DTAIPictureMode ,
        callBack : @escaping ((_ images : [UIImage])->())
        ) -> UIViewController
    {
       return self.initAICameraController(IdentifyName: IdentifyName, Model: Model, maxPicture: maxPicture, mode: mode, activeRectangle: false, callBack: callBack)
    }
    
   
    @objc public static func initAICameraController(
        IdentifyName : String ,
        Model : MLModel? ,
        maxPicture : Int ,
        mode : DTAIPictureMode ,
        activeRectangle : Bool = false ,
        callBack : @escaping ((_ images : [UIImage])->())
        ) -> UIViewController
    {
        
        let storyboard = UIStoryboard(name: "DTAIControllerStoryBoard", bundle:   Bundle(for: self ))
        let vc : DTAIViewController =   storyboard.instantiateViewController(withIdentifier: "DTAIViewController") as! DTAIViewController
        setVcParameter(vc, IdentifyName: IdentifyName, Model: Model, maxPicture: maxPicture, mode: mode, callBack: callBack)
        
        //是否啟用四邊形偵測
        vc.activeRectangleDetect = activeRectangle
        
        //讓旋轉變成自由
        DTAITools.orientation = .all
        
        return vc
        
    }

    @objc public static func setVcParameter (_ vc: DTAIViewController, IdentifyName : String , Model : MLModel? , maxPicture : Int , mode : DTAIPictureMode ,  callBack : @escaping ((_ images : [UIImage])->())) {
        vc.maxPictures = maxPicture
        vc.model = Model
        vc.indentifyName = IdentifyName
        vc.pictureMode = mode
        vc.callBackFunc = callBack
    }
}

