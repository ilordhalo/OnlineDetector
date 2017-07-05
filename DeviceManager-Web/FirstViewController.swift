//
//  FirstViewController.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/9.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import UIKit
import WebKit

let localip = "120.92.50.210"
class FirstViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "webViewApp")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        webView.uiDelegate = self
        view = webView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string: "http://"+localip+":11200/?login")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        createTestData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        webView.evaluateJavaScript("test1()", completionHandler: nil)
        webView.evaluateJavaScript("test3(1,2)") { (any,error) -> Void in
            print(any)
        }
    }
    
    @IBAction func refresh(_ sender: UIBarButtonItem) {
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
        if method == "login" {
            let un: String = dict["un"]!
            let pw: String = dict["pw"]!
            DataManager.sharedInstance.login(userName: un, password: pw, block: { message in
                switch message {
                case .error:
                    AlertMessage(message: "网络错误", viewController: self)
                case .failure:
                    AlertMessage(message: "账号或密码错误", viewController: self)
                case .success:
                    self.refreshData()
                default: break
                }
            })
            
        }
        else if method == "register" {
            let viewController = ILWebViewController()
            viewController.param = "register"
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        else if method == "logout" {
            DataManager.sharedInstance.currentUser = nil
            refreshData()
        }
        else if method == "show" {
            let viewController = ILWebViewController()
            viewController.param = "list"
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func refreshData() {
        webView.stopLoading()
       
        if DataManager.sharedInstance.currentUser != nil {
            let myURL = URL(string: "http://"+localip+":11200/?user")
            let myRequest = URLRequest(url: myURL!)
            webView.load(myRequest)
            DispatchQueue.global(qos: .userInitiated).async {
                while self.webView.isLoading {
                }
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("insert_data('"+(DataManager.sharedInstance.currentUser?.name)!+"')", completionHandler: nil)
                }
            }
        }
        else {
            let myURL = URL(string: "http://"+localip+":11200/?login")
            let myRequest = URLRequest(url: myURL!)
            webView.load(myRequest)
        }
    }
    
    func createTestData() {
        var device = Device()
        device.name = "二氧化硫检测设备"
        device.code = "20170331"
        device.GPS = GPSData(x: 30.695, y: 104.15)
        device.battery = 0.7
        device.lastDate = Date.init(timeIntervalSinceNow: 1)
        device.target = "二氧化硫"
        let data = NSMutableArray()
        device.data = data
        //dataManager.deviceList = NSMutableArray()
        DataManager.sharedInstance.device = device
    }

}

