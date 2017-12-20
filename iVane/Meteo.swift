//
//  Meteo.swift
//  vane
//
//  Created by Remy Krysztofiak on 18/05/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit

class Meteo: NSObject {

    var direction: Int
    var speed: Int
    var temp: Int
    var etat: String
    
    init(pDirection: Int, pSpeed:Int, pTemp: Int,pEtat: String) {
        
        self.direction = pDirection
        self.speed = pSpeed
        self.temp = pTemp
        self.etat = pEtat
        
    }
    
    
    func forcast(long: String, lat: String){
        
        let url = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places%20WHERE%20text%3D%22(\(lat)%2C\(long))%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
        
        let request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            
            
            if let data = data {
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                        if let dForecasts = json["query"] as? [String:Any] {
                            var results = dForecasts["results"] as? [String:Any]
                            var channel = results?["channel"] as? [String:Any]
                            var wind = channel?["wind"] as? [String:Any]
                            var directionString = wind?["direction"] as? String
                            self.direction = Int(directionString!)!
                            
                            
                            var mphString = wind?["speed"] as? String
                            var mph = Double(mphString!)
                            self.speed = Int(mph!*1.609)
                            
                            
                            var item = channel?["item"] as? [String:Any]
                            var condition = item?["condition"] as? [String:Any]
                            
                            var tempFahrenheitString = condition?["temp"] as? String
                            var text = condition?["text"] as? String
                            
                            var tempFahrenheit: Int = Int(tempFahrenheitString!)!
                            self.temp = Int((tempFahrenheit-32)*5/9)
                            
                            
                            
                            
                            
                            
                        }
                        
                    }
                }catch {
                    print(error.localizedDescription)
                }
            }
            
            
        }
        
        task.resume()
        
        
        
        
        
    }
    
    
    
    
    
}
