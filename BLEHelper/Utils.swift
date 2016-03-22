//
//  Utils.swift
//  BLEHelper
//
//  Created by HarveyHu on 2/27/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//

import Foundation

func prettyLog(message: String = "", file:String = #file, function:String = #function, line:Int = #line) {
    
    print("\((file as NSString).lastPathComponent)(\(line)) \(function) \(message)")
}