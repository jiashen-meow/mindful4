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

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let friendAppActivity = Self("Friend App Activity")
    static let foulAppActivity = Self("Foul App Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .totalActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        // Reformat the data into a configuration that can be used to create
        // the report's view.
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        
        // Collect detailed debug information about the data structure
        var dataCount = 0
        var segmentDetails: [String] = []
        var totalActivityDuration: TimeInterval = 0
        var categories: [String] = []
        var applications: [String] = []
        
        // Iterate through the data to collect information
        for await deviceActivityData in data {
            dataCount += 1
            
            var segmentIndex = 0
            for await segment in deviceActivityData.activitySegments {
                let duration = segment.totalActivityDuration
                let formattedDuration = formatter.string(from: duration) ?? "0"
                segmentDetails.append("Data[\(dataCount-1)] Segment[\(segmentIndex)]: \(formattedDuration) (\(duration)s)")
                
                totalActivityDuration += duration
                segmentIndex += 1
                
                for await c in segment.categories {
                    var categoryDuration = 0
                    categories.append((c.category.localizedDisplayName)!)
                    for await ap in c.applications {
                        categoryDuration += Int(ap.totalActivityDuration)
                        applications.append(ap.application.localizedDisplayName ?? "Unknown App")
                        let applicationDuration = formatter.string(from: ap.totalActivityDuration) ?? "0"
                        applications.append("\(applicationDuration)")
                    }
                    categories.append("\(categoryDuration)")
                }
            }
        }
        
        if applications.isEmpty {
            applications.append("")
        }
        
        NSLog("📊 TotalActivityReport: Total activity duration (seconds): %f", totalActivityDuration)
        
        let formattedString = formatter.string(from: totalActivityDuration) ?? "No activity data"
        
        // Comprehensive debug info
        var debugInfo = """
            📊 DEVICE ACTIVITY DEBUG:
            - Data items: \(dataCount)
            - Activity segments: \(segmentDetails.count)
            - Total duration: \(totalActivityDuration)s
            - Formatted: \(formattedString)
            - Selected Categories: \(categories)
            - Selected Apps: \(applications)

            Segment Details:
            """
        
        if segmentDetails.isEmpty {
            debugInfo += "\n- No segments found"
        } else {
            debugInfo += "\n" + segmentDetails.joined(separator: "\n")
        }
        
        return debugInfo
    }
}
