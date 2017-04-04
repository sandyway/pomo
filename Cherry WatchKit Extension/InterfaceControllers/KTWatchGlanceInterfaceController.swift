//
//  KTWatchGlanceInterfaceController.swift
//  Cherry
//
//  Created by Kenny Tang on 2/24/15.
//
//

import WatchKit
import Foundation


class KTWatchGlanceInterfaceController: WKInterfaceController {

    @IBOutlet weak var timerRingGroup:WKInterfaceGroup?
    @IBOutlet weak var timeLabel:WKInterfaceLabel?
    @IBOutlet weak var activityNameLabel:WKInterfaceLabel?
    var currentBackgroundImageString:String?


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.currentBackgroundImageString = "circles_background";
    }

    override func willActivate() {
        super.willActivate()
        self.updateInterfaceWithActiveActivity()
        self.updateUserActivityForHandOff()
    }

    // MARK: willActivate helper methods

    func updateInterfaceWithActiveActivity() {
        if let activity = KTActivityManager.sharedInstance.activeActivityInSharedStorage() {
            self.activityNameLabel!.setText(activity.activityName)

            let displayMinutesString = KTTimerFormatter.formatTimeIntToTwoDigitsString(KTTimerFormatter.formatPomoRemainingMinutes(activity.elapsedSecs))
            let displaySecsString = KTTimerFormatter.formatTimeIntToTwoDigitsString(KTTimerFormatter.formatPomoRemainingSecsInCurrentMinute(activity.elapsedSecs))
            self.timeLabel!.setText("\(displayMinutesString):\(displaySecsString)")

            self.updateTimerBackgroundImage(activity.elapsedSecs)
        }
    }

    func updateUserActivityForHandOff() {
        if let activity = KTActivityManager.sharedInstance.activeActivityInSharedStorage() {
            let userInfo = ["type" : "me.donguo.KTPomodoro.select_activity", "activityID" : activity.activityID]
            self.updateUserActivity("me.donguo.KTPomodoro.active_task", userInfo: userInfo, webpageURL: nil)
        }

    }

    // MARK: updateInterfaceWithActiveActivity helper methods

    func updateTimerBackgroundImage(_ elapsedSecs:Int) {
        let elapsedSections = elapsedSecs/((KTSharedUserDefaults.pomoDuration*60)/12)
        let backgroundImageString = "circles_\(elapsedSections)"
        print("backgroundImageString: \(backgroundImageString)")
        if (backgroundImageString != self.currentBackgroundImageString!) {
            self.currentBackgroundImageString = backgroundImageString
            self.timerRingGroup!.setBackgroundImageNamed(backgroundImageString)
        }
    }


}
