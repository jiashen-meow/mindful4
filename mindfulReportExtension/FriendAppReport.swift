//
//  TotalActivityReport.swift
//  mindfulReportExtension
//
//  Created by Jia Shen on 9/20/25.
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import os.log
internal import ManagedSettings


struct friendAppReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .friendAppActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (FriendAppReport) -> FriendAppReportView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> FriendAppReport {
        var list: [AppDeviceActivity] = []
        
        // Reformat the data into a configuration that can be used to create
        // the report's view.
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
         
        // Iterate through the data to collect information
        for await deviceActivityData in data {
            for await segment in deviceActivityData.activitySegments {
                for await c in segment.categories {
                    for await ap in c.applications {
                        if ap.application.localizedDisplayName != nil {
                            let appName = ap.application.localizedDisplayName ?? "nil"
                            let bundle = ap.application.bundleIdentifier ?? "nil"
                            let duration = ap.totalActivityDuration
                            let formatedDuration = formatter.string(from: duration) ?? "0"
                            let durationInterval = ap.totalActivityDuration
                            let category = c.category.localizedDisplayName!
                            let token = ap.application.token!
                            let numberOfPickups = ap.numberOfPickups
                            let notifs = ap.numberOfNotifications
                        
                            let app = AppDeviceActivity(id: bundle, token: token, displayName: appName, duration: formatedDuration, durationInterval: durationInterval, numberOfPickups: numberOfPickups, category: category, numberOfNotifs: notifs)
                            list.append(app)
                        }

                    }
                }
            }
        }
        // Return nil if no app data was found, otherwise return the first app
        return FriendAppReport(friendApp: list.isEmpty ? nil : list[0])
    }
}
