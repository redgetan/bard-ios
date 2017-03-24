//
//  UploadViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2017-03-23.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import UIKit
import SwiftyDrop
import Firebase


class UploadViewController: UIViewController {
    
    @IBOutlet weak var recentFinishedUploadLabel: UILabel!
    @IBOutlet weak var progressSceneLabel: UILabel!
    @IBOutlet weak var uploadTextField: UITextField!
    @IBOutlet weak var progressPercentLabel: UILabel!
    @IBOutlet weak var progressResultView: UIView!
    @IBOutlet weak var uploadFormView: UIView!
    private var firebaseRef: FIRDatabaseReference!
    private var recentUploadedSceneToken: String!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        firebaseRef = FIRDatabase.database().reference()
        FIRDatabase.setLoggingEnabled(true)
        
        showHideUploadViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UploadViewController.onRecentUploadClick))

        recentFinishedUploadLabel.addGestureRecognizer(tap)
        
        let isUploading = UserConfig.getIsUploading()
        if (isUploading != nil && isUploading!) {
            displayProgress(UserConfig.getCurrentUploadSceneToken()!)
        }
    }
    
    func onRecentUploadClick(sender:UITapGestureRecognizer) {
        print("sceneToken clicked: " + self.recentUploadedSceneToken)
    }
    
    func showHideUploadViews() {
        let isUploading = UserConfig.getIsUploading()
        if (isUploading != nil && isUploading!) {
            uploadFormView.hidden = true
            progressResultView.hidden = false
            
            self.progressSceneLabel.text = "Processing \(UserConfig.getCurrentUploadSceneName())"
        } else {
            uploadFormView.hidden = false
            progressResultView.hidden = true
            
            // show recent successful upload if not nil
            let isUploading = UserConfig.getIsUploading()
            if (isUploading != nil && isUploading == false) {
                let recentUploadedSceneName = UserConfig.getCurrentUploadSceneName()
                self.recentUploadedSceneToken = UserConfig.getCurrentUploadSceneToken()
                recentFinishedUploadLabel.text = recentUploadedSceneName
            }
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
                    let uploadSceneName = dict["sceneName"] as! String
                    UserConfig.setCurrentUploadSceneName(uploadSceneName)
                    UserConfig.setCurrentUploadSceneToken(uploadSceneToken)
                    UserConfig.setIsUploading(true)
                    self.showHideUploadViews()
                    self.displayProgress(uploadSceneToken)
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
    
    
    
    func displayProgress(sceneToken: String) {
        let progressRef = self.firebaseRef.child("scenes/\(sceneToken)/progress")
        
        progressRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            let progressDict = snapshot.value as? [String : AnyObject] ?? [:]
            if let percentComplete = progressDict["percentComplete"] as? String {
                self.progressPercentLabel.text = "\(percentComplete) %"
            }
            if let _ = progressDict["isProcessed"] as? Bool {
                UserConfig.setIsUploading(false)
                progressRef.removeAllObservers()
                self.showHideUploadViews()
            }
            
        })
    
    }
    
    
    
}
