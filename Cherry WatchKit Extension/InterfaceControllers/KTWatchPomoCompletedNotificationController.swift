//
//  KTWatchPomoCompletedNotificationController.swift
//  Cherry
//
//  Created by Kenny Tang on 2/24/15.
//
//

import WatchKit
import Foundation


class KTWatchPomoCompletedNotificationController: WKUserNotificationInterfaceController {

    @IBOutlet weak var alertLabel:WKInterfaceLabel?
    @IBOutlet weak var remainingPomosLabel:WKInterfaceLabel?


    override func didReceive(_ localNotification: UILocalNotification, withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {
        // TODO: can't really test this from the simulator yet...

        // This method is called when a local notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.custom)
    }

    override func didReceiveRemoteNotification(_ remoteNotification: [AnyHashable: Any], withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {

        if let apsDictionary = remoteNotification["aps"] as? [AnyHashable: Any] {
            if let alertString = apsDictionary["alert"] as? String {
                self.alertLabel!.setText(alertString)
            }
        }

        if let remainingPomos = remoteNotification["payload"] as? Int {
            self.remainingPomosLabel!.setText("\(remainingPomos)")
        }
        completionHandler(.custom)
    }
}
