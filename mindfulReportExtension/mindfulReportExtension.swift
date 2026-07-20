//
//  mindfulReportExtension.swift
//  mindfulReportExtension
//
//  Created by Jia Shen on 9/20/25.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct mindfulReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        
        friendAppReport { friendAppReport in
            FriendAppReportView(friendAppReport: friendAppReport)
        }
        
        foulAppReport { foulAppReport in
            FoulAppReportView(foulAppReport: foulAppReport)
        }
    }
}
