//
//  mainViewController.swift
//  RectangleDetection-coreImage
//
//  Created by Shine on 2018/11/15.
//  Copyright © 2018  All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

open class DTAIViewController: UIViewController ,UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate , AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @IBOutlet weak var snapShotCover: UIView!
    @IBOutlet weak var preViewView: UIView!
    @IBOutlet weak var UIControlPanelView: UIView!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var idAreaOuterUIView: UIView!
    @IBOutlet weak var idAreaUIView: UIView!
    @IBOutlet weak var zoomViewLeft: NSLayoutConstraint!
    @IBOutlet weak var ScaleView: UIView!
    @IBOutlet weak var WaterFlowLb: UILabel!
    @IBOutlet weak var flashLight: DTAIFlashButton!
    @IBOutlet weak var minusLb: UILabel!
    @IBOutlet weak var identifyLabel: UILabel!
    

    
    var callBackFunc : (( _ images : [UIImage])->())?
    var maxPictures : Int = 0
    var indentifyName : String? = ""
    var pictureMode : DTAIPictureMode?
    var classifiRequests :[AnyObject] = []
    var retengleRequests :[AnyObject] = []
    var session : AVCaptureSession?
    var previewLayer : AVCaptureVideoPreviewLayer!
    var cameraCaptureOutPut : AVCapturePhotoOutput?
    let captureQueue = DispatchQueue(label: "BackGroundCapture")
    let minConfidence : VNConfidence = 0.3
    var currentDevice :AVCaptureDeviceInput?
    var pictures : [UIImage] = []
    //var model : MLModel!
    var model : MLModel?
    var originalOrientationValue : UIDeviceOrientation?
    var activeRectangleDetect : Bool = false
    
    
    var pathLayer: CALayer?
    
    fileprivate var isPictureCapturing : Bool = false
    
    fileprivate var isActive: Bool = false
    
    override open var shouldAutorotate: Bool
    {
        return true
    }
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return .all
        
    }
    
    override open func viewDidLoad() {
        
        super.viewDidLoad()

        //init Video Session
        initVideoSession()
        
        guard let device = currentDevice?.device else {
            flashLight.isHidden = true
            return
        }
        
        flashLight.isHidden = !device.hasFlash
        
    }
    
    
    override open func viewDidAppear(_ animated: Bool) {
        
        try! currentDevice?.device.lockForConfiguration()
        currentDevice?.device.focusMode = .continuousAutoFocus
        
        currentDevice?.device.exposureMode = .continuousAutoExposure;
        
        currentDevice?.device.unlockForConfiguration()
        if !isActive
        {
            session!.startRunning()
        }
        
        super.viewDidAppear(animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {


        super.viewWillDisappear(animated)

        isActive = false
        //移除所有輸入
        self.previewLayer .removeFromSuperlayer()

        for aVinput in self.session!.inputs
        {
            self.session! .removeInput(aVinput)
        }

        for aVoutput in self.session!.outputs
        {
            self.session!.removeOutput(aVoutput)
        }

        self.session!.stopRunning()

        self.session = nil
        self.previewLayer = nil
        self.classifiRequests = []
        self.retengleRequests = []
        self.cameraCaptureOutPut = nil
        self.currentDevice = nil
        self.preViewView = nil
    }
    
    
    deinit {
        print("Camera view will go the end")
    }
    
    @IBAction func detectSwitchAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        activeRectangleDetect = sender.isSelected
        print(sender.isSelected)
    }
    // MARK: 改變縮放大小
    @IBAction func changeSlider(_ sender: UISlider) {
        
        guard let device = currentDevice?.device else { return }
        
        do {
            
            try device.lockForConfiguration()
            
            device.videoZoomFactor = CGFloat(sender.value)
            
            device.unlockForConfiguration()
            
        } catch {
            print("放大縮小相機失敗 :  \(error)")
        }
    }
    
    @IBAction func turnOnOffFlash(_ sender: DTAIFlashButton) {
        /*
         guard let device = currentDevice?.device else { return }
         
         if device.hasTorch {
         do {
         try device.lockForConfiguration()
         
         device.torchMode = sender.isOn ? .off : .on //判斷完才會去切換isOn
         
         device.unlockForConfiguration()
         } catch {
         print("Torch could not be used")
         }
         } else {
         print("Torch is not available")
         }*/
        
    }
    //設定連拍
    @objc public var isBurstMode : Bool = true
    
    @IBAction func takePictureAction(_ sender: UIButton) {
        
        
        
        guard pictures.count <  maxPictures  else
        {
            let alert = UIAlertController(title: "注意", message: "照片數量已超過此項目可拍照上限，請退出刪除後再進行拍照！", preferredStyle: .alert)
            
            let actionButton = UIAlertAction(title: "確定", style: .cancel) { (alert) in
                
                
            }
            alert.addAction(actionButton)
            
            self.present(alert, animated: false, completion: nil)
            
            return
        }
        
        if isPictureCapturing || coverIsOn
        {
            return
        }
        
        isPictureCapturing = true
        
        let setting = AVCapturePhotoSettings()
        
        setting.isAutoStillImageStabilizationEnabled = true
        setting.isHighResolutionPhotoEnabled = false
        
        guard let device = currentDevice?.device else
        {
            return
        }
        
        if device.hasFlash
        {
            
            
            if flashLight.isOn
            {
                setting.flashMode = .on
            }
            else
            {
                setting.flashMode = .off
            }
            
        }
        coverIsOn = true
        
        self.snapShotCover.alpha = 1
        self.view.bringSubviewToFront( self.snapShotCover)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.snapShotCover.alpha = 0
        }, completion: { (Bool) in
            self.view.sendSubviewToBack(self.snapShotCover)
            self.coverIsOn = false
        })
        
        
        
        
        cameraCaptureOutPut?.capturePhoto(with: setting, delegate: self)
        
        
        
    }
    var coverIsOn : Bool = false
    @IBAction func cancelAction(_ sender: UIButton) {
        DTAITools.orientation = .landscape
        
        
        self.callBackFunc?(self.pictures)
        self.dismiss(animated: true)
    }
    
    
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.previewLayer.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self.previewLayer?.frame.size = self.preViewView.frame.size
        }, completion: nil)
        
        
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    
    func tansformAVOritationToCGOrientation( avoritentation : AVCaptureVideoOrientation) -> CGImagePropertyOrientation{
        
        switch avoritentation {
        case .portrait:
            return CGImagePropertyOrientation.rightMirrored
        case .portraitUpsideDown:
            return CGImagePropertyOrientation.leftMirrored
        case .landscapeRight:
            return CGImagePropertyOrientation.downMirrored
        case .landscapeLeft:
            return CGImagePropertyOrientation.upMirrored
        default:
            return CGImagePropertyOrientation.downMirrored
        }
        
    }
    
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return .landscapeRight
        }
    }

    func initVideoSession(){
        
        self.view.layoutIfNeeded()
        
        session = AVCaptureSession()

        guard let session = session else
        {
            return
        }
        
        session.sessionPreset = .photo
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchToZoom(_:)))
        UIControlPanelView.addGestureRecognizer(pinchGesture)
        let gesture = UITapGestureRecognizer(target: self, action: #selector( self.handleTap(_:) ))
        
        UIControlPanelView.addGestureRecognizer(gesture)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) ,
            
            let inputDevice = try? AVCaptureDeviceInput(device: captureDevice)
            else {
                assertionFailure("Fail to have video capture device.")
                return
        }
        
        var bestFormat : AVCaptureDevice.Format? = nil
        var bestFrameRateRage : AVFrameRateRange? = nil
        for format in  captureDevice.formats
        {
            
            for range in format.videoSupportedFrameRateRanges
            {
                
                guard let _ = bestFrameRateRage else
                {
                    bestFrameRateRage = range
                    bestFormat = format
                    continue
                }
                
                if range.maxFrameRate > bestFrameRateRage!.maxFrameRate
                {
                    bestFormat = format
                    bestFrameRateRage = range
                }
            }
        }
        
        try! captureDevice.lockForConfiguration()
        captureDevice.activeFormat = bestFormat!
        captureDevice.activeVideoMinFrameDuration = bestFrameRateRage!.minFrameDuration
        captureDevice.activeVideoMaxFrameDuration = bestFrameRateRage!.minFrameDuration
        captureDevice.unlockForConfiguration()
        
        currentDevice = inputDevice
        
        session.addInput(inputDevice)
        
        cameraCaptureOutPut = AVCapturePhotoOutput()
        
        session.addOutput(cameraCaptureOutPut!)
        
        //一開始先用current Device oritation
        let currentOritation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)!)
        let videoOutput = AVCaptureVideoDataOutput()
                  videoOutput.setSampleBufferDelegate(self ,queue: captureQueue)//background thread
                  videoOutput.alwaysDiscardsLateVideoFrames = true
                  //videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                  videoOutput.connection(with: .video)?.videoOrientation = currentOritation

                  session.addOutput(videoOutput)

        if model != nil
        {



            let PreDictModel = model as! MLModel

            //here is vision
            guard let visionModel = try? VNCoreMLModel(for:PreDictModel) else {
                assertionFailure("無法使用CoreML + Vision")
                session.startRunning()
                isActive = true
                return
            }
            let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleRequestResult)
            classificationRequest.imageCropAndScaleOption = .centerCrop

            classifiRequests.append(classificationRequest)
        }

        //加入四邊形偵測
        if activeRectangleDetect
        {
            let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: handleDetectedRectangles)

            //一次只用一個物件
            rectDetectRequest.maximumObservations = 1
            rectDetectRequest.quadratureTolerance = 20.0
            retengleRequests.append(rectDetectRequest)
        }
        
        //模型包裝成request can many
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
        self.previewLayer.videoGravity = .resizeAspectFill
        
        let mainFrameHeight = UIScreen.main.bounds.size.height
        let mainFrameWidth = UIScreen.main.bounds.size.width
        if UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
        {
            
            self.previewLayer.frame = CGRect(x: 0, y: 0, width: min(mainFrameHeight, mainFrameWidth), height: max(mainFrameHeight, mainFrameWidth))
        }
        else
        {
            self.previewLayer.frame = CGRect(x: 0, y: 0, width: max(mainFrameHeight, mainFrameWidth), height: min(mainFrameHeight, mainFrameWidth))
        }
        
        self.previewLayer.connection?.videoOrientation = currentOritation
        self.preViewView.layer.addSublayer(self.previewLayer)
        
        DispatchQueue.global().async {
            self.session!.startRunning()
            DispatchQueue.main.async {
                //root layer to session
                
            }
        }
        
        
        
        isActive = true
    }

    fileprivate func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            print("Error : \(nsError)")
            return
        }
        //改變畫面對焦面匡
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else
            {
                return
            }
            
            //沒有偵測到東西 就把舊有的畫面移除
            guard let results = request?.results as? [VNRectangleObservation] ,  results.count > 0 else {
                if let pathLayer = self.pathLayer
                {
                    pathLayer.removeFromSuperlayer()
                    self.pathLayer = nil
                    self.corpPoints = nil
                }
                return
            }
            
            let mainFrameWidth = UIScreen.main.bounds.size.width
            let mainFrameHeight = UIScreen.main.bounds.size.height
            
            let targetSize = CGSize(width: mainFrameWidth, height: mainFrameHeight)
            //畫出四邊形
            
            //有偵測到東西
            for observation in results
            {
                
                //當今天currentObsece有值 代表一定已經有偵測到一個四方形 並且畫在畫面上了
                //因此如果今天有第一點 才會開始進行比較 沒有的話就直接畫圖
                if self.pathLayer != nil , let firstObservation = self.currentObserve as? VNRectangleObservation
                {
                    
                    //比較新抓的值與原本的基準值 是否四點都在allowableValue的畫圓半徑20 pixel以內
                    //如果是的話 就不在進行重新畫四邊形 避免畫面一直重複地在重新產生新的view
                    guard !firstObservation.comapreTowObservationInRange(target: observation, toSize: targetSize , allowableValue: 25)
                        else {
                            return
                    }
                }
                
                //一開始不會進入上方的if let區塊 會把第一個進入的四方行當基準觀察點
                //observation 為第一個進入的觀察點
                self.currentObserve = observation
                
                
                
                // 移除先前的path , 如果有已經有四邊形畫面則進行移除
                if let pathLayer = self.pathLayer
                {
                    pathLayer.removeFromSuperlayer()
                    self.pathLayer = nil
                }
                //self.pathLayer.sublayers = nil
                
                let drawingLayer = CALayer()
                drawingLayer.bounds = CGRect(x: 0, y: 0, width: mainFrameWidth, height: mainFrameHeight)
                drawingLayer.anchorPoint = CGPoint.zero
                drawingLayer.position = CGPoint(x: 0, y: 0)
                drawingLayer.opacity = 0.5
                self.pathLayer = drawingLayer
                self.view.layer.addSublayer(self.pathLayer!)
                
                //取出畫面的距離 此時pathLayer一定有值
                
                //開始畫四邊形
                let rectangleShape = CAShapeLayer()
                // rectangleShape.opacity = 0.8
                rectangleShape.lineWidth = 4
                //rectangleShape.lineJoin = CAShapeLayerLineJoin.round
                
                rectangleShape.strokeColor =   UIColor(red: 0/255, green: 61/225, blue: 61/225, alpha: 1).cgColor
                // rectangleShape.strokeColor =  UIColor.darkGray.cgColor
                rectangleShape.fillColor = nil
                
                let rectanglePath = UIBezierPath()
                rectanglePath.move(to: observation.topLeft.scaled(to: targetSize))
                rectanglePath.addLine(to: observation.topRight.scaled(to: targetSize))
                rectanglePath.addLine(to: observation.bottomRight.scaled(to: targetSize))
                rectanglePath.addLine(to: observation.bottomLeft.scaled(to: targetSize))
                rectanglePath.close()
                
                
                //取出原本的中心點
                let originalPath = rectanglePath.cgPath
                
                let orginMid = CGPoint(x: originalPath.boundingBox.midX, y: originalPath.boundingBox.midY)
                
                let tansfer = CGAffineTransform(scaleX: 1.04, y: 1.04)
                
                var t = CGAffineTransform.identity
                t = t.translatedBy(x: orginMid.x, y: orginMid.y)
                t = tansfer.concatenating(t)
                t = t.translatedBy(x: -orginMid.x, y: -orginMid.y)
                rectanglePath.apply(t)
                
                let tansfer2 = CGAffineTransform(scaleX: 1.02, y: 1.02)
                
                var t2 = CGAffineTransform.identity
                t2 = t2.translatedBy(x: orginMid.x, y: orginMid.y)
                t2 = tansfer2.concatenating(t2)
                t2 = t2.translatedBy(x: -orginMid.x, y: -orginMid.y)
                
                
                self.corpPoints = DTAICorpPoints()
                self.corpPoints!.topLeft = observation.bottomLeft.scaled(to: targetSize).applying(t2)
                self.corpPoints!.topRight = observation.bottomRight.scaled(to: targetSize).applying(t2)
                self.corpPoints!.bottomRight = observation.topRight.scaled(to: targetSize).applying(t2)
                self.corpPoints!.bottomLeft = observation.topLeft.scaled(to: targetSize).applying(t2)
                
                //CGAffineTransform(translationX: <#T##CGFloat#>, y: <#T##CGFloat#>)
                
                //let newPath =   originalPath.copy(using: &newzoom)
                
                rectangleShape.path = rectanglePath.cgPath
                
                self.cropPath = rectanglePath.cgPath
                
                guard let pathlayer = self.pathLayer else
                {
                    return
                }
                pathlayer.addSublayer(rectangleShape)
                
            }
        }
    }
    
    
    //handle each model doing
    @available(iOS 11.0, *)
    func handleRequestResult(request : VNRequest , error : Error?){
        if let error = error{
            print("Error : \(error)")
            return
        }
        
        guard let array = request.results as? [VNCoreMLFeatureValueObservation] else{
            
            print("this model is not a array")
            return
        }
        
        
        
        let resultStr =   array.compactMap { (ary)  in
            
            guard let mulAry = ary.featureValue.multiArrayValue else {
                return ""
            }
            
            let correctNum : NSNumber = mulAry[1]
            
            if(correctNum.doubleValue > 0.85){
                
                return "Y"
            }
            else{
                return "N"
            }
            
            
        }.joined()
        
        DispatchQueue.main.async {
            
            let safeColor =  UIColor(red: 100.0/255.0, green: 190.0/255.0, blue: 0.0, alpha: 1.0)
            self.UIControlPanelView.layer.borderWidth = 3
            //            if  resultStr == "Y"
            //            {
            //
            //                self.identifyLabel.text = "這可能是一張正確的\(self.indentifyName!)"
            //                self.identifyLabel.textColor = safeColor
            //
            //            }
            //            else{
            //
            //                self.identifyLabel.text = "此照片可能不是\(self.indentifyName!)，請再次確認"
            //                self.identifyLabel.textColor = UIColor.red
            //
            //            }
            
        }
    }
    
    
    @objc func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        
        guard let device = currentDevice?.device else { return }
        
        if sender.state == .changed {
            
            let pinchVelocityDividerFactor: CGFloat = 35
            do {
                
                try device.lockForConfiguration()
                
                let desiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, 4))
                zoomSlider.value = Float(device.videoZoomFactor)
                device.unlockForConfiguration()
                
            } catch {
                print(error)
            }
        }
    }
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){      
        if (sender.state == .ended) {
            let thisFocusPoint = sender.location(in: view)
            
            let focus_x = thisFocusPoint.x / view.frame.size.width
            let focus_y = thisFocusPoint.y / view.frame.size.height
            
            
            
            do {
                
                let isautoFocus =   currentDevice?.device.isFocusModeSupported(.continuousAutoFocus)
                let isSupported =  currentDevice?.device.isFocusPointOfInterestSupported
                
                if(isautoFocus! && isSupported!){
                    try currentDevice?.device.lockForConfiguration()
                    currentDevice?.device.focusMode = .continuousAutoFocus
                    currentDevice?.device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                }
                
                if ((currentDevice?.device.isExposureModeSupported(.continuousAutoExposure))! && (currentDevice?.device.isExposurePointOfInterestSupported)!) {
                    currentDevice?.device.exposureMode = .continuousAutoExposure;
                    currentDevice?.device.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y);
                }
                
                currentDevice?.device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    //MARK: AVCapturePhotoCaptureDelegate
    @available(iOS 10.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        guard let imageData =
            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
        }
        
        processPictures(imageData: imageData)
        
    }
    
    
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        processPictures(imageData: imageData)
        
    }
    
    public func processPictures( imageData : Data){
        
        guard let newImage =  UIImage(data: imageData) else
        {
            return
        }
        
        var imageRotation : UIImage.Orientation
        let  orientation  =  UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
        switch orientation {
        case .landscapeLeft:
            imageRotation = UIImage.Orientation.down
        case .landscapeRight:
            imageRotation = UIImage.Orientation.up
        case .portraitUpsideDown:
            imageRotation = UIImage.Orientation.left
        default:
            imageRotation = UIImage.Orientation.right
        }
        
        var finalImage = UIImage(cgImage: newImage.cgImage!, scale: 1.0, orientation: imageRotation)
        let FrameHeight = UIScreen.main.bounds.size.height
        let FrameWidth = UIScreen.main.bounds.size.width
        
        let scaleX = finalImage.size.width / FrameWidth
        let scaleY = finalImage.size.height / FrameHeight
        
        var corpScale  = DTAICorpScale()
        corpScale.scaleX = scaleX
        corpScale.scaleY = scaleY
        
        if self.pictureMode == .Credicials
        {
            /* crop start */
            let imageWidth = finalImage.size.width
            let imageHeight = finalImage.size.height
            
            let originalOuterWidth = idAreaOuterUIView.bounds.size.width
            let originalOuterHeight = idAreaOuterUIView.bounds.size.height
            let originalIDWidth = idAreaUIView.bounds.size.width
            let originalIDHeight = idAreaUIView.bounds.size.height
            
            let widthScale = imageWidth / originalOuterWidth
            let heightScale = imageHeight / originalOuterHeight
            
            let width = Double(originalIDWidth * widthScale)
            let height = Double(originalIDHeight * heightScale)
            
            let origin = CGPoint(x: (Double(imageWidth) - width)/2, y: (Double(imageHeight) - height)/2)
            
            let size = CGSize(width: width, height: height)
            
            let textCGPoint = CGPoint(x: ((originalOuterWidth - originalIDWidth)/2 + 15) * widthScale , y: ((originalOuterHeight - originalIDHeight)/2 + 60) * heightScale)
            
            
            let WaterFlowSize =  self.WaterFlowLb.font.pointSize * widthScale
            
            finalImage = finalImage.addText(drawText: "只供國泰人壽辦理房貸使用", atPoint: textCGPoint, FontSize: WaterFlowSize)
            
            finalImage = finalImage.crop(rect: CGRect(origin: origin, size: size))
            /* crop end */
        }
        
        //進行裁切
        
        if activeRectangleDetect ,  let corpPoint = self.corpPoints
        {
            let viewSize = finalImage.size
            
            let parameters = [
                "inputTopLeft" :  CIVector(cgPoint: corpPoint.topLeft!.scaleToSize(to: corpScale).cartesianForPoint(extent: viewSize)),
                "inputTopRight" : CIVector(cgPoint:corpPoint.topRight!.scaleToSize(to: corpScale).cartesianForPoint(extent: viewSize)),
                "inputBottomRight" : CIVector(cgPoint:corpPoint.bottomRight!.scaleToSize(to: corpScale).cartesianForPoint(extent: viewSize)),
                "inputBottomLeft" : CIVector(cgPoint:corpPoint.bottomLeft!.scaleToSize(to: corpScale).cartesianForPoint(extent: viewSize))
            ]
            
            var ciimage =  CIImage(image: finalImage)
            
            print("check oritation \(imageRotation.rawValue)")
            if #available(iOS 11.0, *) {
                
                ciimage =  ciimage?.oriented( CGImagePropertyOrientation(imageRotation))
                
                let rectified = ciimage!.applyingFilter("CIPerspectiveCorrection", parameters: parameters)
                
                UIGraphicsBeginImageContext(CGSize(width: rectified.extent.size.width, height: rectified.extent.size.height))
                
                UIImage(ciImage:rectified).draw(in: CGRect(x: 0, y: 0, width: rectified.extent.size.width, height: rectified.extent.size.height))
                
                guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else
                    
                {
                    print("no images")
                    UIGraphicsEndImageContext()
                    return
                }
                
                finalImage = newImage
                UIGraphicsEndImageContext()
                
                
            }
        }
        
        
        pictures.append(finalImage)
        isPictureCapturing = false
    }
    
    //MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    @available(iOS 10.0, *)
    public func photoToFile(image : UIImage){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let destinationPath = documentsPath.appendingPathComponent("filename.jpg")
        
        
        try! image.jpegData(compressionQuality: 1.0)?.write(to:   URL(fileURLWithPath: destinationPath))
    }
    
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if #available(iOS 11.0, *) {
            
            
            
            //change buffer to pixcel buffer
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{
                return
            }
            
            let ciimage : CIImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            let context:CIContext = CIContext.init(options: nil)
            let cgImage:CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
            
            let image:UIImage = UIImage(cgImage: cgImage)
            
            //捕捉的相片不轉向
            
            //進行前處理
            let processImage =  image.imagePreprocess()
            
            
            //data 資料也不轉 讓他預設
            //connection.videoOrientation = .landscapeRight
            
            var options = [VNImageOption : Any]()
            
            
            if let intrinscData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil){
                options = [ .cameraIntrinsics : intrinscData]
            }
            
            
            
            guard let preocessCGImage = processImage?.cgImage else
            {
                return
            }
            
            //預設的handler也不進行轉向 讓他自己判別 使用預設值
            
            
            //let sqeHandler = VNSequenceRequestHandler()
            
            let handler = VNImageRequestHandler(cgImage: preocessCGImage, options: options)
            //let handler = VNImageRequestHandler(cgImage: preocessCGImage, orientation: .upMirrored, options: options)
            // let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: options)
            
            let classifiRequestAry = classifiRequests as! [VNRequest]
            try? handler.perform(classifiRequestAry)//vision for multi model
            if activeRectangleDetect
            {
                
                let retangleRequestAry = retengleRequests as! [VNRequest]
                
                
                guard let preview = self.previewLayer , let AVConnection = preview.connection else
                {
                    return
                }
                let imageOrient =  tansformAVOritationToCGOrientation(avoritentation: AVConnection.videoOrientation)
                
                //ciimage =  ciimage.oriented(imageOrient)
                
                let requestHandle = VNImageRequestHandler(ciImage:ciimage, orientation: imageOrient)
                
                try? requestHandle.perform(retangleRequestAry)//vision for multi model
                
            }

            else
            {
                DispatchQueue.main.async { [weak self] in
                    
                    guard let `self` = self else
                    {
                        return
                    }
                    
                    //非自動偵測模式 有邊框要進行移除
                    if let pathLayer = self.pathLayer
                    {
                        pathLayer.removeFromSuperlayer()
                        self.pathLayer = nil
                        self.corpPoints = nil
                    }
                    
                }

            }
        }
    }
    
    var currentObserve :  AnyObject? = nil
    
    var cropPath : CGPath? = nil
    
    var corpPoints : DTAICorpPoints? = nil
    
    
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

struct DTAICorpPoints {
    var topLeft : CGPoint?
    var topRight : CGPoint?
    var bottomRight : CGPoint?
    var bottomLeft : CGPoint?
}

struct DTAICorpScale {
    var scaleX : CGFloat?
    var scaleY : CGFloat?
}
