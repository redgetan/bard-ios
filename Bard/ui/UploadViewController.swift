//
//  UploadViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2017-03-23.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import UIKit
import SwiftyDrop

class UploadViewController: UIViewController {
    
    @IBOutlet weak var uploadTextField: UITextField!
    @IBOutlet weak var progressResultView: UIView!
    @IBOutlet weak var uploadFormView: UIView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showHideUploadViews()
    }
    
    func showHideUploadViews() {
        let isUploading = UserConfig.getIsUploading()
        if (isUploading != nil && isUploading!) {
            uploadFormView.hidden = true
            progressResultView.hidden = false
        } else {
            uploadFormView.hidden = false
            progressResultView.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func onUploadBtnClick(sender: UIButton) {
        // queue upload
        let youtubeUrl = uploadTextField.text!
        
        BardClient.postVideoUpload(youtubeUrl, success: { value in
              let dict = (value as! [String:AnyObject])
              if let errorMessage = dict["error"] as? String {
                Drop.down(errorMessage, state: .Error, duration: 3)
              } else if let successMessage = dict["result"] as? String {
                if let uploadSceneToken = dict["sceneToken"] as? String {
                    UserConfig.setCurrentUpload(uploadSceneToken)
                    UserConfig.setIsUploading(true)
                    self.showHideUploadViews()
                }
                Drop.down(successMessage, state: .Success, duration: 3)
              }
              
            
            }, failure: { errorMessage in
                Drop.down(errorMessage, state: .Error, duration: 3)
            
        })
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
    }
    
    
    
}
