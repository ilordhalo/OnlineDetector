//
//  DataManager.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/12.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import UIKit
import Alamofire
import GameplayKit

enum RequestMessageType {
    case error
    case empty
    case success
    case other
    case failure
    init(message: String) {
        switch message {
        case "error":
            self = .error
        case "empty":
            self = .empty
        case "success":
            self = .success
        case "failure":
            self = .failure
        default:
            self = .other
        }
    }
}

final class DataManager {
    static let sharedInstance = DataManager()
    
    // MARK: Types
    
    enum DataManagerState {
        case work
        case wait
        case error
    }
    
    enum ErrorType {
        case noError
        case typeError
        case dataError
        case networkError
        case stateError
        var info: String {
            switch self {
            case .typeError:
                return "数据类型错误"
            case .dataError:
                return "获取的数据错误"
            case .networkError:
                return "网络错误"
            case .stateError:
                return "有其他正在处理的网络请求"
            case .noError:
                return ""
            }
        }
    }
    
    // MARK: Properties
    
    var currentUser: User?
    
    var errorMessage: ErrorType = .noError
    var device: Device!
    
    var identifier: String? = {
        return nil
    }()
    
    let sessionManager : SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return Alamofire.SessionManager(configuration: configuration)
    }()     //dont save cache
    
    
    // MARK: Initialization
    
    private init() {
    }
    
    // MARK: Network
    
    func login(userName: String, password: String, block: ((RequestMessageType) -> Void)? = nil) {
        let url = "http://" + localip + ":11200/?login&" + userName + "&" + password
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            guard let value = response.result.value as? Dictionary<String, Any> else {
                return
            }
            let ans = value["ans"] as! String
            DispatchQueue.main.async {
                if ans == "success" {
                    let data = value["data"] as! Dictionary<String, Any>
                    self.currentUser = User.init(data: data)
                    block?(.success)
                }
                else {
                    block?(.failure)
                }
            }
        }
    }
    
    func register(name: String, userName: String, password: String, company: String?, position: String?, block: ((RequestMessageType) -> Void)? = nil) {
        var url = "http://" + localip + ":11200/?register&" + name + "&" + userName + "&" + password + "&"
        if let company = company {
            url += company
        }
        url += "&"
        if let position = position {
            url += position
        }
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            guard let value = response.result.value as? Dictionary<String, Any> else {
                return
            }
            let ans = value["ans"] as! String
            DispatchQueue.main.async {
                if ans == "success" {
                    block?(.success)
                }
                else {
                    block?(.failure)
                }
            }
        }
    }
    
    func add(block: ((RequestMessageType) -> Void)? = nil) {
        let url = "http://" + localip + ":11200/?add"
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            DispatchQueue.main.async {
                block?(.success)
            }
        }
    }
    
    func getDeviceData(deviceID: String, block: ((RequestMessageType) -> Void)? = nil) {
        let url = "http://" + localip + ":11200/?list&" + deviceID
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            guard let value = response.result.value as? Dictionary<String, Any> else {
                return
            }
            let data = value["data"] as! Dictionary<String, Any>
            DataManager.sharedInstance.device = Device(data: data)
            DispatchQueue.main.async {
                block?(.success)
            }
        }
    }
    
    func deleteDevice(deviceID: String, block: ((RequestMessageType) -> Void)? = nil) {
        let url = "http://" + localip + ":11200/?delete&" + deviceID
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            DispatchQueue.main.async {
                block?(.success)
            }
        }
    }
    
    func editDevice(deviceID: String, newID: String, name: String, target: String, lon: String, lat: String, block: ((RequestMessageType) -> Void)? = nil) {
        var url = "http://" + localip + ":11200/?edit&" + deviceID
        url += "&" + newID
        url += "&" + name
        url += "&" + target
        url += "&" + lon
        url += "&" + lat
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            DispatchQueue.main.async {
                block?(.success)
            }
        }
    }
    
    func getData(deviceID: String, block: ((RequestMessageType) -> Void)? = nil) {
        let url = "http://" + localip + ":11200/?data&" + deviceID
        sessionManager.request(url, parameters: nil).responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    block?(.error)
                }
                return
            }
            guard let value = response.result.value as? Dictionary<String, Any> else {
                return
            }
            self.device.data.removeAllObjects()
            let datas = value["data"] as! NSArray
            for data in datas {
                guard let data = data as? Dictionary<String, Any> else {
                    continue
                }
                let newData = DeviceData.init(data: data)
                self.device.data.add(newData)
            }
            DispatchQueue.main.async {
                block?(.success)
            }
        }
    }
    
    func getDeviceListRequest() {
        /*
        stateMachine.enter(ErrorState.self)
        errorMessage = .networkError
        return
        guard stateMachine.canEnterState(WorkState.self) else {
            errorMessage = .stateError
            return
        }
        stateMachine.enter(WorkState.self)
        
        let url = "http://114.215.124.196/static/fig1.jpg"
        sessionManager.request(url, method:.get).response {
            dataResponse in
            guard let data = dataResponse.data else {
                self.stateMachine.enter(ErrorState.self)
                return
            }
            self.stateMachine.enter(WaitState.self)
        }*/
    }
    
    func getDeviceDataRequest() {
        
    }
    
    func removeDeviceRequest(identifier deviceID: String) {
        
    }
    
    func updateDeviceDataRequest() {
        
    }
    
    func addDeviceDataRequest() {
        
    }
    
}
