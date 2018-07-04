//
//  IntroViewController.swift
//  dreamteams_ios
//
//  Created by godowondev on 2018. 5. 13..
//  Copyright © 2018년 dreamteams. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    @IBOutlet weak var introImageView: UIImageView!
    let common = Common()
    let apiHelper = APIHelper()
    var new_image:Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let imgData = UserDefaults.standard.object(forKey: "intro_image") as? NSData
        {
            if let image = UIImage(data: imgData as Data)
            {
                self.introImageView.image = image
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.moveToMainView()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavController()
        checkNetwork()
        common.sendDeviceInfo()
        
        //apiHelper.delegate = self
        apiHelper.connectHttpAsync(resourceURL: common.api_url + "?action=getIntroImage&device_type=iOS")
        apiHelper.connectHttpAsync(resourceURL: common.api_url + "?action=getEventData&device_type=iOS")

    }
    
    func changeImage(uiImage:UIImage){
        self.introImageView.image = uiImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkNetwork(){
        if(CheckNetwork.isConnected()==false)
        {
            moveToErrorView()
        }
    }
    
    func moveToMainView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "mainView")as! MainViewController
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func moveToErrorView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "errorView")as! ErrorViewController
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
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
}
/*
extension IntroViewController: APIHelperDelegate {
    func changeImage(imageData:NSData) {
        self.introImageView.image = UIImage(data: imageData 과s Data)
        //self.introImageView.reloadInputViews()
    }
}
*/
