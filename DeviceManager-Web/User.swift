//
//  User.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/7/3.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import Foundation

struct User {
    var power: String
    var name: String
    var email: String
    var company: String
    var position: String
    
    init() {
        self.power = ""
        self.name = ""
        self.email = ""
        self.company = ""
        self.position = ""
    }
    init(data: Dictionary<String, Any>) {
        self.power = data["power"] as! String
        self.name = data["name"] as! String
        self.email = data["email"] as! String
        self.company = data["company"] as! String
        self.position = data["position"] as! String
    }
}
