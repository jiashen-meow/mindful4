//
//  TotalActivityView.swift
//  mindfulReportExtension
//
//  Created by Jia Shen on 9/20/25.
//

import SwiftUI
import DeviceActivity
internal import ManagedSettings
import FamilyControls

struct AppDeviceActivity: Identifiable {
    var id: String
    var token: ApplicationToken
    var displayName: String
    var duration: String
    var durationInterval: TimeInterval
    var numberOfPickups: Int
    var category: String
    var numberOfNotifs: Int
}

struct FriendAppReport {
    let friendApp: AppDeviceActivity?
}

struct FoulAppReport {
    let foulApp: AppDeviceActivity?
}

struct FriendAppReportView: View {
    var friendAppReport: FriendAppReport
    
    var body: some View {
        VStack(alignment: .center) {
            CardView(app: friendAppReport.friendApp)
        }
    }
}

struct FoulAppReportView: View {
    var foulAppReport: FoulAppReport
    
    var body: some View {
        VStack(alignment: .center) {
            FoulCardView(app: foulAppReport.foulApp)
        }
    }
}

struct CardView: View {
    let app: AppDeviceActivity?
    
    var body: some View {
        VStack {
            if app != nil {
                Label(app!.token)
                    .labelStyle(.iconOnly)
                    .frame(width:50, height:50)
                    .scaleEffect(3)
                Text(app!.displayName)
                Text(app!.duration)
            } else {
                Text("did you take care of your friend app today at all?")
            }
        }
    }
}

struct FoulCardView: View {
    let app: AppDeviceActivity?
    
    var body: some View {
        VStack {
            if app != nil {
                Label(app!.token)
                    .labelStyle(.iconOnly)
                    .frame(width:50, height:50)
                    .scaleEffect(3)
                Text(app!.displayName)
                Text(app!.duration)
            } else {
                Text("nice! your enemy is weak!")
            }
        }
    }
}
