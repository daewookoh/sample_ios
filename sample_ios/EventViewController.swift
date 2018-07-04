//
//  EventViewController.swift
//  dreamteams_ios
//
//  Created by godowondev on 2018. 5. 18..
//  Copyright © 2018년 dreamteams. All rights reserved.
//

import Foundation

import UIKit

class EventViewController: UIViewController {

    @IBOutlet weak var eventImageView: UIImageView!
    let common = Common()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let click = UITapGestureRecognizer(target: self, action: #selector(imageClick))
        eventImageView.addGestureRecognizer(click)
        eventImageView.isUserInteractionEnabled = true

    }
    
    @objc func imageClick() {
        let link_url = common.getUD("event_link_url")
        let type = common.getUD("event_open_type")
        
        if(type=="in"){
            moveToMainView()
        }else if(type=="out"){
            let url = URL(string:link_url!)
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url!)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func moveToErrorView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "errorView")as! ErrorViewController
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func checkNetwork(){
        if(CheckNetwork.isConnected()==false)
        {
            self.moveToErrorView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setNavController()
        checkNetwork()
        if let imgData = UserDefaults.standard.object(forKey: "event_image") as? NSData
        {
            if let image = UIImage(data: imgData as Data)
            {
                self.eventImageView.image = image
            }
        }
    }
    
    @IBAction func notTodayBtnClicked(_ sender: Any) {
        let today = getToday()
        common.setUD("event_reject_date",today)
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func closeBtnClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
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

    func getToday() -> String{
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter.string(from: date)
    }
    
    func moveToMainView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "mainView")as! MainViewController
        next.sUrl = self.common.getUD("event_link_url")!
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
}
