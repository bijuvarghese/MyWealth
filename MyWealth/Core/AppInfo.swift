//
//  AppInfo.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/21/26.
//

import Foundation

enum AppInfo {
    
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var fullVersion: String {
        "v\(version) (\(build))"
    }
}
