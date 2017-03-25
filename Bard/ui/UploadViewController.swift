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
//        FIRDatabase.setLoggingEnabled(true)
        
        hideKeyboardOnTouch()
        enterUploadMode()

        let tap = UITapGestureRecognizer(target: self, action: #selector(UploadViewController.onRecentUploadClick))
        recentFinishedUploadLabel.userInteractionEnabled = true
        recentFinishedUploadLabel.addGestureRecognizer(tap)
        
        let isUploading = UserConfig.getIsUploading()
        if (isUploading != nil && isUploading!) {
            observeProgress(UserConfig.getCurrentUploadSceneToken()!)
        }
    }
    
    @IBAction func hideProgressView(sender: UIButton) {
        enterUploadMode()
    }
    
    func onRecentUploadClick(sender:UITapGestureRecognizer) {
        print("sceneToken clicked: " + self.recentUploadedSceneToken)
        
        let isUploading = UserConfig.getIsUploading()
        if (isUploading != nil && isUploading!) {
            enterProgressResultMode()
        } else {
            // if already finished uploading (show editor)
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            
            let viewController = storyBoard.instantiateViewControllerWithIdentifier("BardEditorViewController") as! BardEditorViewController
            viewController.scene = Scene.forToken(self.recentUploadedSceneToken)
            self.presentViewController(viewController, animated:true, completion:nil)

        }
    }
    
    // http://stackoverflow.com/a/38283424/803865
    func hideKeyboardOnTouch()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UploadViewController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
   
    func enterProgressResultMode() {
        uploadFormView.hidden = true
        progressResultView.hidden = false
        
        self.progressSceneLabel.text = "Processing \(UserConfig.getCurrentUploadSceneName()!) . You will be notified by email once it completes processing. Progress will also be shown below."
    }
    
    func enterUploadMode() {
        uploadFormView.hidden = false
        progressResultView.hidden = true
        
        // show recent successful upload if not nil
        
        if let recentUploadedSceneName = UserConfig.getCurrentUploadSceneName() {
            self.recentUploadedSceneToken = UserConfig.getCurrentUploadSceneToken()
            let recentUploadLabel = "\(recentUploadedSceneName)"
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: recentUploadLabel)
            attributeString.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: NSMakeRange(0, attributeString.length))
            recentFinishedUploadLabel.attributedText = attributeString
        }
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func onUploadBtnClick(sender: UIButton) {
        if !UserConfig.isLogined() {
            Helper.showAskUserToLogin(self, message: "You must Login to upload")
            return
        }
        
        // queue upload
        let youtubeUrl = uploadTextField.text!
        
        BardClient.postVideoUpload(youtubeUrl, success: { value in
              let dict = (value as! [String:AnyObject])
              if let errorMessage = dict["error"] as? String {
                Drop.down(errorMessage, state: .Error, duration: 3)
              } else if let successMessage = dict["result"] as? String {
                let obj = dict["scene"] as! NSDictionary
                let sceneToken = obj["token"] as! String
                if let _ = Scene.forToken(sceneToken) {
                   // already exist
                } else {
                    let scene = Scene.createWithTokenAndName(obj)!
                    UserConfig.setCurrentUploadSceneName(scene.name)
                    UserConfig.setCurrentUploadSceneToken(scene.token)
                    UserConfig.setIsUploading(true)
                    self.enterProgressResultMode()
                    self.observeProgress(scene.token)
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
    
    
    
    func observeProgress(sceneToken: String) {
        let progressRef = self.firebaseRef.child("scenes/\(sceneToken)/progress")
        
        progressRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            let progressDict = snapshot.value as? [String : AnyObject] ?? [:]
            if let percentComplete = progressDict["percentComplete"] as? Int {
                self.progressPercentLabel.text = "\(percentComplete) %"
            } else {
                self.progressPercentLabel.text = "In queue"
            }
            if let isProcessed = progressDict["isProcessed"] as? Bool {
                if isProcessed == true {
                    UserConfig.setIsUploading(false)
                    progressRef.removeAllObservers()
                    self.enterUploadMode()
                }
            }
            
        })
    
    }
    
    
    
}
