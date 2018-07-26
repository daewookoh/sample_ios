//
//  APIHelper.swift
//  Godowon

//import Foundation
import UIKit


protocol APIHelperDelegate {
    func changeImage(imageData : NSData)
}

class APIHelper {
    
    var delegate: APIHelperDelegate?
    
    func getDeviceID() -> String {
        return UIDevice.current.identifierForVendor!.uuidString
    }
    
    func connectHttpAsync(resourceURL: String) {
        let common = Common()
        // 세션 생성, 환경설정
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "\(resourceURL)") else {
            print("URL is nil")
            return
        }
        
        // Request
        let request = URLRequest(url: url)
        
        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            // getting Data Error
            guard error == nil else {
                print("Error occur: \(String(describing: error))")
                return
            }
        
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                // 통신에 성공한 경우 data에 Data 객체가 전달됩니다.
                
                // 받아오는 데이터가 json 형태일 경우,
                // json을 serialize하여 json 데이터를 swift 데이터 타입으로 변환
                // json serialize란 json 데이터를 String 형태로 변환하여 Swift에서 사용할 수 있도록 하는 것을 말합니다.
                guard (try? JSONSerialization.jsonObject(with: data, options: [])) != nil else {
                    print(resourceURL)
                    print("No Json Result")
                    return
                }
                
                // 원하는 작업
                if let strData = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    let str = String(strData)
                    print(str)
                    
                    let jsonResult = self.jsonEncode(text: str)
                    
                    let result_code = jsonResult?["result_code"] as? String
                    print(result_code)
                    
                    let result_msg = jsonResult?["result_msg"] as? String
                    print(result_msg)
                    
                    common.setUD("event_yn", "N")
                    let event_reject_date = common.getUD("event_reject_date")
                    let today = common.getToday()
                    
                    if(result_code=="0000" && result_msg == "EVENT_DATA_SUCCESS" && event_reject_date != today)
                    {
                        common.setUD("event_yn", "Y")
                        
                        if let img_url = jsonResult?["img_url"] as? String{
                            self.downloadImage(img_url: img_url, type: "event_image")
                        }
                        
                        if let link_url = jsonResult?["link_url"] as? String{
                            common.setUD("event_link_url", link_url)
                        }
                        
                        if let open_type = jsonResult?["open_type"] as? String{
                            common.setUD("event_open_type", open_type)
                        }
                        
                        if let title = jsonResult?["title"] as? String{
                            common.setUD("event_title", title)
                        }
                        
                    }
                    
                    if(result_code=="0000" && result_msg == "INTRO_IMAGE_SUCCESS")
                    {
                        if let img_url = jsonResult?["img_url"] as? String{
                            self.downloadImage(img_url: img_url, type: "intro_image")
                        }
                    }
                }

            }
        }
        dataTask.resume()
    }
    
    func jsonEncode(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options:[]) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func downloadImage(img_url : String, type: String){
        let common = Common()
        let url:NSURL = NSURL(string : img_url)!
        let imageData = NSData(contentsOf: url as URL)
        let event_image = UIImage(data: imageData! as Data)
        let jpeg_image = UIImageJPEGRepresentation(event_image!, 1)
        common.setUDimage(type, jpeg_image)
    }
    
}
