//
//  MainViewController.swift
//  dreamteams_ios
//
//  Created by godowondev on 2018. 5. 13..
//  Copyright © 2018년 dreamteams. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore
import MessageUI
import Social
import FBSDKShareKit


@objc protocol JSInterface : JSExport {
    func contentShare(_ object: AnyObject)
}

class MainViewController: UIViewController, NaverThirdPartyLoginConnectionDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, XMLParserDelegate, JSInterface, MFMessageComposeViewControllerDelegate {

    
    
    // ios 11이하 버젼에서는 스토리보드를 이용한 WKWebView를 사용할수 없으므로 아래와 같이 수동처리
    //@IBOutlet weak var webView: WKWebView!
    var webView: WKWebView!
    var sUrl:String = ""
    let common = Common()
    let apiHelper = APIHelper()
    
    // 네이버 로그인
    var foundCharacters = "";
    var email = ""
    var id = ""
    var gender = ""
    var name = ""
    
    // 로그인전
    // 로그인 토큰이 없는 경우, 로그인 화면을 오픈한다.
    func oauth20ConnectionDidOpenInAppBrowser(forOAuth request: URLRequest!) {
        // Open Naver SignIn View Controller
        let naverSignInViewController = NLoginThirdPartyOAuth20InAppBrowserViewController(request: request)!
        present(naverSignInViewController, animated: true, completion: nil)
    }
    
    // 로그인후
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        getNaverDataFromURL()
    }
    
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        getNaverDataFromURL()
    }
    
    func oauth20ConnectionDidFinishDeleteToken() {
        // Do Nothing
    }
    
    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        // Do Nothing
    }
    
    func getNaverDataFromURL() {
        
        // Naver SignIn Success
        
        let loginConn = NaverThirdPartyLoginConnection.getSharedInstance()
        let tokenType = loginConn?.tokenType
        let accessToken = loginConn?.accessToken
        
        // Get User Profile
        if let url = URL(string: "https://apis.naver.com/nidlogin/nid/getUserProfile.xml") {
            if tokenType != nil && accessToken != nil {
                let authorization = "\(tokenType!) \(accessToken!)"
                var request = URLRequest(url: url)
                
                request.setValue(authorization, forHTTPHeaderField: "Authorization")
                let dataTask = URLSession.shared.dataTask(with: request) {(data, response, error) in
                    if let str = String(data: data!, encoding: .utf8) {
                        
                        var parser = XMLParser()
                        parser = XMLParser(data: data!)
                        parser.delegate = self
                        parser.parse()
                        
                        print("\n"+self.id+"\n"+self.gender+"\n"+self.name+"\n"+self.email+"\n")
                        
                        print(str)
                        
                        let url = self.common.sns_callback_url +
                            "?login_type=naver" +
                            "&success_yn=Y" +
                            "&id=" + self.id +
                            "&gender=" + self.gender +
                            "&name=" + self.name +
                            "&email=" + self.email
                        self.loadPage(url: url)
                        
                        // Naver Sign Out
                        //loginConn?.resetToken()
                    }
                }
                dataTask.resume()
            }
        }
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "id" { foundCharacters = "" }
        else if elementName == "gender" { foundCharacters = "" }
        else if elementName == "name" { foundCharacters = "" }
        else if elementName == "email" { foundCharacters = "" }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "id" { id = foundCharacters }
        else if elementName == "gender" { gender = foundCharacters }
        else if elementName == "name" { name = foundCharacters }
        else if elementName == "email" { email = foundCharacters }
    }
    // 네이버 로그인 끝
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if(sUrl=="" && sUrl.isEmpty)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.checkEvent()
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        
        UserDefaults.standard.register(defaults: ["UserAgent": common.user_agent])
        
        // ios 11이하 버젼에서는 스토리보드를 이용한 WKWebView를 사용할수 없으므로 아래와 같이 수동처리
        let contentController = WKUserContentController()
        contentController.add(self, name: common.js_name)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self as WKUIDelegate
        webView.navigationDelegate = self as! WKNavigationDelegate
        
        view = webView
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if(message.name==common.js_name){
            if let message = message.body as? String {
                
                print(message)
                
                if message == "NAVERLOGIN" {
                    print("NAVERLOGIN")
                    let naverConnection = NaverThirdPartyLoginConnection.getSharedInstance()
                    naverConnection?.delegate = self
                    naverConnection?.requestThirdPartyLogin()
                }
                else if message == "KAKAOLOGIN" {
                    print("KAKAOLOGIN")
                    let session: KOSession = KOSession.shared();
                    if session.isOpen() {
                        session.close()
                    }
                    session.presentingViewController = self
                    session.open(completionHandler: { (error) -> Void in
                        if error != nil{
                            print(error?.localizedDescription)
                        }else if session.isOpen() == true{
                            KOSessionTask.meTask(completionHandler: { (profile , error) -> Void in
                                if profile != nil{
                                    DispatchQueue.main.async {
                                        let kakao: KOUser = profile as! KOUser
                                        print(String(describing: kakao.id))
                                        
                                        self.name = (kakao.properties!["nickname"] as? String)!
                                        self.email = kakao.email!
                                        self.id = kakao.id.stringValue
                                        
                                        /*
                                        if let value = kakao.properties!["profile_image"] as? String {
                                            print("profile image = \(value)")
                                        }
                                        if let value = kakao.properties!["thumbnail_image"] as? String {
                                            print("thumbnail image = \(value)")
                                        }
                                        */
                                        
                                        let url = self.common.sns_callback_url +
                                            "?login_type=kakao" +
                                            "&success_yn=Y" +
                                            "&id=" + self.id +
                                            "&email=" + self.email +
                                            "&name=" + self.name
                                        
                                        print(url)
                                        
                                        self.loadPage(url: url)
                                    }
                                }

                            })
                        }else{
                            print("isNotOpen")
                        }
                    })
                } else {
                    let data = Data(message.utf8)
                    let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                    
                    let share_type = json["share_type"] as? String
                    
                    let link_url = json["link_url"] as? String
                    let title = json["title"] as? String
                    let img_url = json["img_url"] as? String
                    let content = json["content"] as? String
                    
                    if(share_type == "MMS")
                    {
                        if (MFMessageComposeViewController.canSendText()) {
                            let controller = MFMessageComposeViewController()
                            controller.body = title! + "\n\n" + content! + "\n\n" +  link_url!
                            controller.recipients = [""]
                            controller.messageComposeDelegate = self
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                    else if(share_type == "KAKAO")
                    {
                        // Feed 타입 템플릿 오브젝트 생성
                        let template = KMTFeedTemplate { (feedTemplateBuilder) in
                            
                            // 컨텐츠
                            feedTemplateBuilder.content = KMTContentObject(builderBlock: { (contentBuilder) in
                                contentBuilder.title = title!
                                contentBuilder.desc = content!
                                contentBuilder.imageURL = URL(string: img_url!)!
                                contentBuilder.imageWidth = 400
                                contentBuilder.imageHeight = 400
                                contentBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                                    linkBuilder.mobileWebURL = URL(string: link_url!)
                                })
                            })
                            /*
                            // 소셜
                            feedTemplateBuilder.social = KMTSocialObject(builderBlock: { (socialBuilder) in
                                socialBuilder.likeCount = 286
                                socialBuilder.commnentCount = 45
                                socialBuilder.sharedCount = 845
                            })
                            
                            // 버튼
                            feedTemplateBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                                buttonBuilder.title = "웹으로 보기"
                                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                                    linkBuilder.mobileWebURL = URL(string: "https://developers.kakao.com")
                                })
                            }))
                            feedTemplateBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                                buttonBuilder.title = "앱으로 보기"
                                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                                    linkBuilder.iosExecutionParams = "param1=value1&param2=value2"
                                    linkBuilder.androidExecutionParams = "param1=value1&param2=value2"
                                })
                            }))
                            */
                        }
                        
                        // 카카오링크 실행
                        KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
                            
                            // 성공
                            print("warning message: \(String(describing: warningMsg))")
                            print("argument message: \(String(describing: argumentMsg))")
                            
                        }, failure: { (error) in
                            
                            // 실패
                            self.alert(title: "ERROR", msg:error.localizedDescription)
                            print("error \(error)")
                            
                        })
 
                    }
                    else if(share_type == "KAKAOSTORY")
                    {
                        if !SnsLinkHelper.canOpenStoryLink() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id486244601")
                            return
                        }
                        let bundle = Bundle.main
                        var postMessage: String!
                        if let bundleId = bundle.bundleIdentifier, let appVersion: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                            let appName: String = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                            postMessage = SnsLinkHelper.makeStoryLink(title! + " " + link_url!, appBundleId: bundleId, appVersion: appVersion, appName: appName, scrapInfo: nil)
                        }
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                    }
                    else if share_type == "LINE" {
                        if !SnsLinkHelper.canOpenLINE() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id443904275")
                            return
                        }
                        let postMessage = SnsLinkHelper.makeLINELink(title! + " " + link_url!)
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                        
                    }
                    else if share_type == "BAND" {
                        if !SnsLinkHelper.canOpenBAND() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id542613198")
                            return
                        }
                        let postMessage = SnsLinkHelper.makeBANDLink(title! + " " + link_url!, link_url!)
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                    }
                    else if share_type == "FACEBOOK" {

                        // import FBSDKShareKit 을 이용할경우
                        let cont = FBSDKShareLinkContent()
                        //cont.contentTitle = title!  // 작동안함
                        //cont.contentDescription = content! // 작동안함
                        cont.contentURL = URL(string: link_url!)
                        
                        let dialog = FBSDKShareDialog()
                        dialog.fromViewController = self
                        dialog.mode = FBSDKShareDialogMode.native
                        if !dialog.canShow() {
                            dialog.mode = FBSDKShareDialogMode.automatic
                        }
                        dialog.shareContent = cont
                        dialog.show()
 
/*
                        // import Social 을 이용할경우
                        let facebookShare = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                        if let facebookShare = facebookShare{
                            facebookShare.setInitialText(title!) // 작동안함
                            //facebookShare.add(UIImage(named: "iOSDevCenters.jpg")!)
                            facebookShare.add(URL(string: link_url!))
                            self.present(facebookShare, animated: true, completion: nil)
                        }
 */
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavController()
        checkNetwork()
        
        
        var url = URL(string: common.default_url)
        if(!sUrl.isEmpty){
            url = URL(string: sUrl)
        }
        
        let request = URLRequest(url: url!)
        
        webView.load(request)
    }
    
    func loadPage(url:String) {
        let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkNetwork(){
        if(CheckNetwork.isConnected()==false)
        {
            self.moveToErrorView()
        }
    }
    
    func checkEvent(){
        if let event_yn = self.common.getUD("event_yn") {
            if(event_yn == "Y")
            {
                openEventView()
            }
        }
    }
    
    func openEventView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "eventView")as! EventViewController
        self.navigationController?.pushViewController(next, animated: false)
    }
    
    func moveToErrorView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "errorView")as! ErrorViewController
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func alert(title : String?, msg : String,
               style: UIAlertControllerStyle = .alert,
               dontRemindKey : String? = nil) {
        if dontRemindKey != nil,
            UserDefaults.standard.bool(forKey: dontRemindKey!) == true {
            return
        }
        
        let ac = UIAlertController.init(title: title,
                                        message: msg, preferredStyle: style)
        ac.addAction(UIAlertAction.init(title: "OK",
                                        style: .default, handler: nil))
        
        if dontRemindKey != nil {
            ac.addAction(UIAlertAction.init(title: "Don't Remind",
                                            style: .default, handler: { (aa) in
                                                UserDefaults.standard.set(true, forKey: dontRemindKey!)
                                                UserDefaults.standard.synchronize()
            }))
        }
        DispatchQueue.main.async {
            self.present(ac, animated: true, completion: nil)
        }
    }
    
    func setNavController(){
        //상단바 숨기기
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //페이지변환시 fade효과
        let transition: CATransition = CATransition()
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        self.navigationController!.view.layer.add(transition, forKey: nil)
    }
    
    
    func contentShare(_ object: AnyObject) {
        print("~contentShare: \(object)")
        
        if let data = object.data(using: String.Encoding.utf8.rawValue) {
            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
            
            let share_type = json["share_type"] as? String
            let link_url = json["link_url"] as? String
            let title = json["title"] as? String
            let img_url = json["img_url"] as? String
            let content = json["content"] as? String
            /*
             if share_type == "FACEBOOK" {
             
             self.activityIndicator.startAnimating()
             DispatchQueue.main.async(execute: {() -> Void in
             self.activityIndicator.stopAnimating()
             self.facebookShareLink(link_url)
             })
             
             //self.activityIndicator.startAnimating()
             //if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
             //    self.activityIndicator.stopAnimating()
             //    let post = SLComposeViewController(forServiceType: SLServiceTypeFacebook)!
             //    post.setInitialText("\(title) \(link_url)")
             //    self.present(post, animated: true, completion: nil)
             //}
             
             } else if share_type == "KAKAO" {
             let template = KMTFeedTemplate { (feedTemplateBuilder) in
             feedTemplateBuilder.content = KMTContentObject(builderBlock: { (contentBuilder) in
             contentBuilder.title = title
             contentBuilder.desc = content
             contentBuilder.imageURL = URL(string: img_url)!
             contentBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
             linkBuilder.mobileWebURL = URL(string: link_url)
             })
             })
             }
             // 카카오링크 실행
             KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
             // 성공
             print("warning message: \(String(describing: warningMsg))")
             print("argument message: \(String(describing: argumentMsg))")
             }, failure: { (error) in
             // 실패
             print("error \(error)")
             })
             } else if share_type == "KAKAOSTORY" {
             if !StoryLinkHelper.canOpenStoryLink() {
             StoryLinkHelper.openiTunes("itms://itunes.apple.com/app/id486244601")
             return
             }
             let bundle = Bundle.main
             var postMessage: String!
             if let bundleId = bundle.bundleIdentifier, let appVersion: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
             let appName: String = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
             postMessage = StoryLinkHelper.makeStoryLink("\(title) \(link_url)", appBundleId: bundleId, appVersion: appVersion, appName: appName, scrapInfo: nil)
             }
             if let urlString = postMessage {
             _ = StoryLinkHelper.openSNSLink(urlString)
             }
             
             } else if share_type == "LINE" {
             if !StoryLinkHelper.canOpenLINE() {
             StoryLinkHelper.openiTunes("itms://itunes.apple.com/app/id443904275")
             return
             }
             let postMessage = StoryLinkHelper.makeLINELink("\(title) \(link_url)")
             if let urlString = postMessage {
             _ = StoryLinkHelper.openSNSLink(urlString)
             }
             
             } else if share_type == "BAND" {
             if !StoryLinkHelper.canOpenBAND() {
             StoryLinkHelper.openiTunes("itms://itunes.apple.com/app/id542613198")
             return
             }
             let postMessage = StoryLinkHelper.makeBANDLink("\(title) \(link_url)", Godowon.Domains.BaseUrl)
             if let urlString = postMessage {
             _ = StoryLinkHelper.openSNSLink(urlString)
             }
             }
             */
        }
    }
}

extension MainViewController {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: common.app_name, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            completionHandler()
        }
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: common.app_name, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

