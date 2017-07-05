//
//  ILWebViewController.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/25.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ILWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    var param = ""
    var url: URL! {
        return URL(string: "http://"+localip+":11200/?" + param)
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "webViewApp")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        webView.scrollView.refreshControl = refreshController
        webView.uiDelegate = self
        if param == "register" {
            webView.scrollView.isScrollEnabled = false
        }
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
        let alertView = UIAlertController(title: "页面提示", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default, handler: nil)
        alertView.addAction(okAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    // MARK: WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let dict = message.body as! Dictionary<String,String>
        let method: String = dict["method"]!
        if method == "detail" {
            let id: String = dict["id"]!
            DataManager.sharedInstance.device.code = id
            let viewController = ILWebViewController()
            viewController.param = "device"
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        if method == "add" {
            DataManager.sharedInstance.add(block: {
                message in
                switch message {
                case .error:
                    AlertMessage(message: "网络错误", viewController: self)
                case .success:
                    let myRequest = URLRequest(url: self.url)
                    self.webView.load(myRequest)
                default: break
                }
            })
        }
        if method == "map" {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "MapTableViewController") as! MapTableViewController
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        if method == "data" {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "DataTableViewController") as! DataTableViewController
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        if method == "edit" {
            
            let viewController = ILWebViewController()
            viewController.param = "edit"
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        if method == "delete" {
            let id = dict["id"] as! String
            DataManager.sharedInstance.deleteDevice(deviceID: id, block: {
                message in
                self.refreshData()
            })
        }
        if method == "register_ok" {
            let un: String = dict["un"]!
            let pw: String = dict["pw"]!
            let name: String = dict["name"]!
            let com: String? = dict["com"]
            let pos: String? = dict["pos"]
            DataManager.sharedInstance.register(name: name, userName: un, password: pw, company: com, position: pos, block: {
                message in
                switch message {
                case .error:
                    AlertMessage(message: "网络错误", viewController: self)
                case .failure:
                    AlertMessage(message: "用户名已存在", viewController: self)
                case .success:
                    AlertMessage(message: "注册成功", viewController: self)
                default: break
                }
            })
        }
        if method == "edit_ok" {
            let code: String = dict["code"]!
            let name: String = dict["name"]!
            let target: String = dict["target"]!
            let lon: String = dict["lon"]!
            let lat: String = dict["lat"]!
            let id = DataManager.sharedInstance.device.code
            DataManager.sharedInstance.editDevice(deviceID: id, newID: code, name: name, target: target, lon: lon , lat: lat, block: {
                message in
                switch message {
                case .error:
                    AlertMessage(message: "网络错误", viewController: self)
                case .success:
                    DataManager.sharedInstance.device.code = code
                    self.navigationController?.popViewController(animated: true)
                default: break
                }
            })
        }
    }
    
    // refreshData 每次View显示前刷新页面内容
    func refreshData() {
        let myRequest = URLRequest(url: url)
        webView.load(myRequest)
        DispatchQueue.global(qos: .userInitiated).async {
            while self.webView.isLoading {
                Thread.sleep(forTimeInterval: 0.5)
            }
            DispatchQueue.main.async {
                self.webView.scrollView.refreshControl!.endRefreshing()
                self.refreshView()
            }
        }
    }
    
    // refreshView 在确保页面加载完成后，执行相应的js代码
    func refreshView() {
        if param == "device" {
            let deviceID = DataManager.sharedInstance.device.code
            DataManager.sharedInstance.getDeviceData(deviceID: deviceID, block: {
                message in
                if message == .success {
                    guard let device = DataManager.sharedInstance.device else {
                        return
                    }
                    var jsstr = "insert_data('" + device.name + "','"
                    jsstr += device.code + "','"
                    jsstr += device.target + "','"
                    jsstr += device.GPS.toString() + "','"
                    jsstr += String(device.battery) + "');"
                    self.webView.evaluateJavaScript(jsstr, completionHandler: nil)
                }
            })
        }
        if param == "edit" {
            guard let device = DataManager.sharedInstance.device else {
                return
            }
            var jsstr = "insert_data('" + device.code + "','"
            jsstr += device.name + "','"
            jsstr += device.target + "','"
            jsstr += String(device.GPS.x) + "','"
            jsstr += String(device.GPS.y) + "');"
            self.webView.evaluateJavaScript(jsstr, completionHandler: nil)
        }
    }
}
