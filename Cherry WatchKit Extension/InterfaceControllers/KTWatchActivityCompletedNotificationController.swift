//
//  KTWatchActivityCompletedNotificationController.swift
//  Cherry
//
//  Created by Kenny Tang on 2/24/15.
//
//

import WatchKit
import Foundation


class KTWatchActivityCompletedNotificationController: WKUserNotificationInterfaceController {

    @IBOutlet weak var alertLabel:WKInterfaceLabel?
    @IBOutlet weak var plannedPomosLabel:WKInterfaceLabel?
    @IBOutlet weak var actualPomosLabel:WKInterfaceLabel?


    override func didReceiveRemoteNotification(_ remoteNotification: [AnyHashable: Any], withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {

        if let apsDictionary = remoteNotification["aps"] as? [AnyHashable: Any] {
            if let alertString = apsDictionary["alert"] as? String {
                self.alertLabel!.setText(alertString)
            }
        }

        if let notificationDictionary = remoteNotification["payoad"] as? [AnyHashable: Any] {
            if let plannedPomos = notificationDictionary["planned_pomos"] as? Int {
                self.plannedPomosLabel!.setText("\(plannedPomos)")
            }
            if let actualPomos = notificationDictionary["actual_pomos"] as? Int {
                self.actualPomosLabel!.setText("\(actualPomos)")
            }
        }
        completionHandler(.custom)
    }


}
