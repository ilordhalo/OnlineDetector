//
//  Device.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/12.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import Foundation

extension Date {
    init(withString str: String) {
        self.init()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self = dateFormatter.date(from: str)!
    }
}

struct GPSData {
    var x: Double
    var y: Double
    
    init(x: Double, y:Double) {
        self.x = x
        self.y = y
    }
    init(data: String) {
        let gps = data.characters.split(separator: ",").map(String.init)
        self.x = 0
        self.y = 0
        if gps.count > 1 {
            self.x = Double(gps[0])!
            self.y = Double(gps[1])!
        }
    }
    func toString() -> String {
        return String(self.x) + "," + String(self.y)
    }
}

struct DeviceData {
    var date: Date
    var value1: Double
    var value2: Double
    var value3: Double
    var sdate: String
    
    init() {
        self.date = Date.init(timeIntervalSinceNow: 0)
        self.value1 = 0
        self.value2 = 0
        self.value3 = 0
        self.sdate = ""
    }
    init(data: Dictionary<String, Any>) {
        self.sdate = data["time"] as! String
        self.date = Date(withString: sdate)
        self.value1 = data["parameter01"] as! Double
        self.value2 = data["parameter02"] as! Double
        self.value3 = data["parameter03"] as! Double
    }
    
    func copy() -> DeviceData {
        var newData = DeviceData()
        newData.date = self.date
        newData.sdate = self.sdate
        newData.value1 = self.value1
        newData.value2 = self.value2
        newData.value3 = self.value3
        return newData
    }
}

struct Device {
    // MARK: Properties
    var code: String
    
    var name: String
    
    var target: String
    
    var GPS: GPSData
    
    var battery: Double
    
    var lastDate: Date
    
    var data: NSMutableArray
    
    init() {
        self.code = ""
        self.name = ""
        self.target = ""
        self.GPS = GPSData(x: 0,y: 0)
        self.battery = 0
        self.lastDate = Date()
        self.data = NSMutableArray()
    }
    init(data: Dictionary<String, Any>) {
        self.code = data["equipmentID"] as! String
        self.name = data["equipmentName"] as! String
        self.target = data["location"] as! String
        self.GPS = GPSData(x: data["lon"] as! Double, y: data["lat"] as! Double)
        self.battery = 1
        self.lastDate = Date()
        self.data = NSMutableArray()
    }
}
