//
//  DetailViewController.swift
//  BLEHelperExample
//
//  Created by HarveyHu on 3/21/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//

import UIKit
import BLEHelper
import CoreBluetooth

class DetailViewController: UIViewController, BLEDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    var detailItem: CBPeripheral?

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem, label = self.detailDescriptionLabel {
            label.text = "Status before connected:\n" + detail.description
            prettyLog(detail.description)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        BLE.sharedInstance.delegate = self
        if let uuid = detailItem?.identifier.UUIDString {
            BLE.sharedInstance.connect(uuid) { [weak self](success) -> (Void) in
                if success {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self?.configureView()
                    })
                    
                } else {
                    prettyLog("connect failure")
                }
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        BLE.sharedInstance.disconnect(self.detailItem?.identifier.UUIDString )
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //BLEDelegate
    func didReceivedData(dataString: String) {
        prettyLog("got data from peripheral: \(dataString)")
    }
}

