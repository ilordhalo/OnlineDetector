 //
//  DataTableViewController.swift
//  DeviceManager-Web
//
//  Created by 张 家豪 on 2017/6/12.
//  Copyright © 2017年 张 家豪. All rights reserved.
//

import Foundation
import Charts

// MARK: axisFormatDelegate
extension UIViewController: IAxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}

class DataTableViewController: UITableViewController {
    // MARK: Preperties
    var dataManager: DataManager = DataManager.sharedInstance
    
    var chartView: LineChartView!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        chartView = LineChartView.init(frame: self.view.frame)
        chartView.backgroundColor = UIColor.white
        chartView.chartDescription?.text = "单位："
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl?.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        
        axisFormatDelegate = self
    }
    
    // MARK: UIViewController Life Cycle
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation.isPortrait {
            chartView.frame = self.view.frame
            self.tableView.addSubview(chartView)
        }
    }
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation.isLandscape {
            self.navigationController?.navigationBar.isHidden = true
            self.tabBarController?.tabBar.isHidden = true
        }
        else {
            chartView.removeFromSuperview()
            self.navigationController?.navigationBar.isHidden = false
            self.tabBarController?.tabBar.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        InDeviceDataView = true
        refreshData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        InDeviceDataView = false
    }
    
    // MARK: UITabelViewControllerDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    /*
     override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
     let title = dataManager.device.target + "浓度"
     return [title]
     }
     */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = dataManager.device.target + "浓度"
        return title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifer = "DeviceDataTableViewCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifer)
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.value1, reuseIdentifier: cellIdentifer)
        }
        guard let newCell = cell else {
            fatalError("no cell")
        }
        let data = DataManager.sharedInstance.device.data.object(at: indexPath.row) as! DeviceData
        newCell.isUserInteractionEnabled = false
        newCell.textLabel?.text = String(data.value1)
        newCell.detailTextLabel?.text = String(describing: data.date)
        print(indexPath.row)
        return newCell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(dataManager.device.data.count)
        return dataManager.device.data.count
    }

    // MARK: My Function
    
    func updateView() {
        
        let data = NSMutableArray()
        let date = NSMutableArray()
        for deviceData in dataManager.device.data {
            let dDate = (deviceData as! DeviceData).copy()
            data.add(dDate.value1)
            date.add(Double(dDate.date.timeIntervalSince1970))
        }
        let ys = Array(0..<data.count).map { x in
            return data.object(at: x)
        }
        let xs = Array(0..<date.count).map { x in
            return date.object(at: x)
        }
        let yse = ys.enumerated().map { x, y in return ChartDataEntry(x: xs[x] as! Double, y: y as! Double) }
        let chartData = LineChartData()
        let ds = LineChartDataSet(values: yse, label: dataManager.device.target + "浓度")
        ds.colors = [NSUIColor.blue]
        chartData.addDataSet(ds)
        chartView.data = chartData
        
        let xaxis = chartView.xAxis
        xaxis.valueFormatter = axisFormatDelegate
        
        print(self.dataManager.device.data)
    }
    
    func refreshData() {
        dataManager.getData(deviceID: dataManager.device.code, block: {
            message in
            switch message {
            case .error:
                AlertMessage(message: "网络错误", viewController: self)
            case .success:
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                //print(self.dataManager.device.data)
                self.updateView()
            default: break
            }
        })
    }
    
}
