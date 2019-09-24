//
//  mainViewController.swift
//  RectangleDetection-coreImage
//
//  Created by Shine on 2019/9/24.
//  Copyright © 2019 BrilleShine. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBAction func OpenCameraAction(_ sender: UIButton) {

         let storyboard = UIStoryboard(name: "DTAIControllerStoryBoard", bundle:   nil)
             let vc : DTAIViewController =   storyboard.instantiateViewController(withIdentifier: "DTAIViewController") as! DTAIViewController


             //是否啟用四邊形偵測
             vc.activeRectangleDetect = true

        self.present(vc, animated: true)
    }

    @IBAction func OpenAlbumAction(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                  return
              }

              let albumVC = UIImagePickerController()
              albumVC.sourceType = .photoLibrary
        self.present(albumVC, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
