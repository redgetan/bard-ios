//
//  BardClient.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import Alamofire

class BardClient {


    static let signUpUrl = "\(Configuration.bardAccountBaseURL)/users"
    static let loginUrl  = "\(Configuration.bardAccountBaseURL)/users/sign_in"
    static let packListUrl  = "\(Configuration.bardAccountBaseURL)/bundles"

    static func getSceneListUrl(pageIndex: Int, search: String? = nil, locale: String) -> String  {
        if let searchText = search {
            return "\(Configuration.bardAccountBaseURL)/scenes?search=\(searchText)&page=\(pageIndex)&locale=\(locale)"
        } else {
            return "\(Configuration.bardAccountBaseURL)/scenes?page=\(pageIndex)&locale=\(locale)"
        }
    }

    static func getSceneWordListUrl(sceneToken: String) -> String  {
        return "\(Configuration.bardAccountBaseURL)/scenes/\(sceneToken)/word_list"
    }

    static func getSceneUrl(sceneToken: String) -> String  {
        return "\(Configuration.bardAccountBaseURL)/scenes/\(sceneToken)"
    }

    static func getPackWordListUrl(packToken: String) -> String {
        return "\(Configuration.bardAccountBaseURL)/bundles/\(packToken)/word_list"
    }

    static func postRepoUrl() -> String {
        return "\(Configuration.bardAccountBaseURL)/repos"
    }

    static func postVideoUploadUrl() -> String {
        return "\(Configuration.bardAccountBaseURL)/upload"
    }


    static func deleteRepoUrl(token: String) -> String {
        return "\(Configuration.bardAccountBaseURL)/repos/\(token)/delete"
    }


    static func login(usernameOrEmail usernameOrEmail: String, password: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {

        let params : [String : String] = [
            "email"    : usernameOrEmail,
            "password" : password
        ]

        bardApiRequest(.POST, url: loginUrl, parameters: params, success: success, failure: failure)
    }

    static func signUp(username username: String, email: String, password: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {

        let params : [String : String] = [
            "username" : username,
            "email"    : email,
            "password" : password
        ]

        bardApiRequest(.POST, url: signUpUrl, parameters: params, success: success, failure: failure)
    }

    static func getPackList(success success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: packListUrl, success: success, failure: failure)
    }

    static func getSceneList(pageIndex: Int, search: String? = nil, locale: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getSceneListUrl(pageIndex, search: search, locale: locale), success: success, failure: failure)
    }

    static func getScene(sceneToken: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getSceneUrl(sceneToken), success: success, failure: failure)
    }

    static func getSceneWordList(sceneToken: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getSceneWordListUrl(sceneToken), success: success, failure: failure)
    }

    static func getPackWordList(packToken: String, progress: ((Int64, Int64, Int64) -> Void)? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) -> Alamofire.Request {
        return bardDownload(getPackWordListUrl(packToken), destinationPath: Storage.getPackFilePath(packToken), progress: progress, success: success, failure: failure)
    }

    static func postVideoUpload(youtubeUrl: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        let params : [String : String] = [
            "youtube_url": youtubeUrl
        ]
        bardApiRequest(.POST, url: postVideoUploadUrl(), parameters: params, success: success, failure: failure)
    }


    static func postRepo(uuid: String, sceneToken: String, wordList: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        let params : [String : String] = [
            "uuid": uuid,
            "scene_token" : sceneToken,
            "word_list" : wordList
        ]
        bardApiRequest(.POST, url: postRepoUrl(), parameters: params, success: success, failure: failure)
    }

    static func deleteRepo(token: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        let params : [String : String] = [
            "token": token
        ]
        bardApiRequest(.POST, url: deleteRepoUrl(token), parameters: params, success: success, failure: failure)
    }

    static func bardApiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {

        var customHeaders = headers ?? [String : String]()
        customHeaders["Accept"] = "application/json"

        if let authenticationToken = UserConfig.getAuthenticationToken() {
            customHeaders["Authorization"] = "Token \(authenticationToken)"
        }

        apiRequest(method, url: url, parameters: parameters, headers: customHeaders, success: success, failure: failure)
    }

    static func bardDownload(url: String, destinationPath: String, progress: ((Int64, Int64, Int64) -> Void)? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) -> Alamofire.Request {
        print("download request: \(url)")

        var customHeaders = [String : String]()
        customHeaders["Accept"] = "application/json"

        if let authenticationToken = UserConfig.getAuthenticationToken() {
            customHeaders["Authorization"] = "Token \(authenticationToken)"
        }

        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
            (temporaryUrl, response)  in
            if response.statusCode == 200 {
                let destinationURL = NSURL(fileURLWithPath: destinationPath)
                if NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
                    try! NSFileManager.defaultManager().removeItemAtURL(destinationURL)
                }
                return destinationURL
            } else {
                return temporaryUrl
            }
        }

        return Alamofire.download(.GET, url, parameters: nil,
                            encoding: .JSON,
                            headers: customHeaders,
                            destination: destination)
                 .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in

                   progress?(bytesRead, totalBytesRead, totalBytesExpectedToRead)
                 }.response { _, response, _, error in

                    print("headers[reponse]:")
                    print(response?.allHeaderFields)
                    print(response?.expectedContentLength)
                    if error != nil {
                        failure?("something went wrong")
                        print("Failed with error: \(error)")
                    } else if !NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
                        failure?("Download failed")
                    } else {

                        if let jsonData = NSData(contentsOfFile: destinationPath)  {
                            do {
                                if let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject] {
                                    if let error = (jsonResult as? [String: String])?["error"] {
                                        failure?(error)
                                    } else {
                                        success?(jsonResult)
                                    }
                                }
                            } catch let error as NSError {
                                failure?("Error. Try again later.")
                            }


                        }
                    }


                 }

    }

    static func apiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        print("\(method) \(url)")

        Alamofire.request(method, url, parameters: parameters, headers: headers)
            .responseJSON { response in

                if let httpError = response.result.error {
                    failure?("Error. Try again later.")
                } else if let JSON = response.result.value {
                    if let error = (JSON as? [String: String])?["error"] {
                        failure?(error)
                    } else {
                        success?(JSON)
                    }
                } else {
                    failure?("something went wrong")
                }
        }
    }
}

