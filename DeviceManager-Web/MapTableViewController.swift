//
//  MapTableViewController.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/12.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

//
//  DeviceMapTableViewController.swift
//  DeviceManager-Demo
//
//  Created by 张 家豪 on 2017/3/28.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import UIKit

class MapTableViewController: UITableViewController,BMKMapViewDelegate, BMKGeoCodeSearchDelegate,BMKLocationServiceDelegate {
    // MARK: Properties
    @IBOutlet weak var mapView: BMKMapView!
    
    var geocodeSearch: BMKGeoCodeSearch!
    var locationService: BMKLocationService!
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl?.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        
        geocodeSearch = BMKGeoCodeSearch()
        
        mapView.zoomLevel = 14
        
        locationService = BMKLocationService()
        locationService.allowsBackgroundLocationUpdates = false
        
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationService.delegate = self
        
        mapView.viewWillAppear()
        mapView.delegate = self
        geocodeSearch.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationService.delegate = nil
        
        mapView.viewWillDisappear()
        mapView.delegate = nil
        geocodeSearch.delegate = nil
    }
    
    // MARK: - BMKGeoCodeSearchDelegate
    
    /**
     *返回反地理编码搜索结果
     *@param searcher 搜索对象
     *@param result 搜索结果
     *@param error 错误号，@see BMKSearchErrorCode
     */
    func onGetReverseGeoCodeResult(_ searcher: BMKGeoCodeSearch!, result: BMKReverseGeoCodeResult!, errorCode error: BMKSearchErrorCode) {
        print("onGetReverseGeoCodeResult error: \(error)")
        
        mapView.removeAnnotations(mapView.annotations)
        if error == BMK_SEARCH_NO_ERROR {
            let item = BMKPointAnnotation()
            item.coordinate = result.location
            mapView.addAnnotation(item)
            mapView.centerCoordinate = result.location
            
            /*let alertView = UIAlertController(title: "反向地理编码", message: result.address, preferredStyle: .alert)
             let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
             alertView.addAction(okAction)
             self.present(alertView, animated: true, completion: nil)*/
            self.title = result.address
        }
    }
    
    
    // MARK: - BMKMapViewDelegate
    
    /**
     *根据anntation生成对应的View
     *@param mapView 地图View
     *@param annotation 指定的标注
     *@return 生成的标注View
     */
    func mapView(_ mapView: BMKMapView!, viewFor annotation: BMKAnnotation!) -> BMKAnnotationView! {
        let AnnotationViewID = "renameMark"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: AnnotationViewID) as! BMKPinAnnotationView?
        if annotationView == nil {
            annotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: AnnotationViewID)
            // 设置颜色
            annotationView!.pinColor = UInt(BMKPinAnnotationColorRed)
            // 从天上掉下的动画
            annotationView!.animatesDrop = true
            // 设置是否可以拖拽
            annotationView!.isDraggable = false
        }
        annotationView?.annotation = annotation
        
        self.refreshControl?.endRefreshing()
        
        return annotationView
    }
    
    // MARK: My Function
    
    func updateView() {
        let lat = DataManager.sharedInstance.device.GPS.x
        let lon = DataManager.sharedInstance.device.GPS.y
        let reverseGeocodeSearchOption = BMKReverseGeoCodeOption()
        reverseGeocodeSearchOption.reverseGeoPoint = CLLocationCoordinate2DMake(lat, lon)
        let flag = geocodeSearch.reverseGeoCode(reverseGeocodeSearchOption)
        if flag {
            print("反geo 检索发送成功")
        } else {
            print("反geo 检索发送失败")
        }
    }
    func refreshData() {
        updateView()
        //self.refreshControl?.endRefreshing()
    }
}
