//
//  AppDelegate.swift
//  sample_ios
//
//  Created by godowondev on 2018. 5. 24..
//  Copyright © 2018년 dreamteams. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let common = Common()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Naver SignIn
        let loginConn = NaverThirdPartyLoginConnection.getSharedInstance()
        
        // 네이버앱으로 로그인 (네이버앱 미설치시, 앱 내 사파리 연결)
        loginConn?.isNaverAppOauthEnable = true
        loginConn?.isInAppOauthEnable = true
        
        // 헤더에서 설정한 앱 설정값 할당
        loginConn?.serviceUrlScheme = common.naver_url_scheme
        loginConn?.consumerKey = common.naver_client_id
        loginConn?.consumerSecret = common.naver_client_secret
        loginConn?.appName = common.naver_app_name
        
        // 화면 가로 회전 차단하기
        loginConn?.setOnlyPortraitSupportInIphone(true)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print(url)
        
        //카카오 로그인
        if KOSession.isKakaoAccountLoginCallback(url) {
            return KOSession.handleOpen(url)
        }
        
        //네이버 로그인
        var naverSignInResult = false
        
        if url.scheme == common.naver_url_scheme {
            if url.host == kCheckResultPage {
                let loginConn = NaverThirdPartyLoginConnection.getSharedInstance()
                let resultType = loginConn?.receiveAccessToken(url)
                
                if resultType == SUCCESS {
                    print("Naver login success")
                    naverSignInResult = true
                } else {
                    print("ERROR : Naver Sign In Failed")
                }
            }
            return naverSignInResult
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //카카오 로그인
        KOSession.handleDidBecomeActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}
