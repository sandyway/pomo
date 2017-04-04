//
//  KTWatchActivityDetailsInterfaceController.swift
//  Cherry
//
//  Created by Kenny Tang on 2/24/15.
//
//

import WatchKit
import Foundation

let kActivityDetailsInterfaceControllerStatusMessageOtherActiveActivity = "Another activity is already in-progress.";
let kActivityDetailsInterfaceControllerStatusMessageBreak = "Taking Break";


class KTWatchActivityDetailsInterfaceController: WKInterfaceController, KTActivityManagerDelegate {

    var activity:KTPomodoroActivityModel?
    var currentBackgroundImageString:String?
    @IBOutlet weak var activityNameLabel:WKInterfaceLabel?
    @IBOutlet weak var plannedPomoLabel:WKInterfaceLabel?
    @IBOutlet weak var remainingPomoLabel:WKInterfaceLabel?
    @IBOutlet weak var timeLabel:WKInterfaceLabel?
    @IBOutlet weak var timerRingInterfaceGroup:WKInterfaceGroup?
    @IBOutlet weak var statusMessageGroup:WKInterfaceGroup?
    @IBOutlet weak var statusMessage:WKInterfaceLabel?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let activity = context as? KTPomodoroActivityModel {
            self.initializeInterface(activity)
            self.activity = activity
            self.registerUserDefaultChanges()
            self.updateInterfaceWithActiveActivity()
            self.statusMessage!.setText("Another activity is already in progress")
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.unregisterUserDefaultChanges()
        KTCoreDataStack.sharedInstance.saveContext()
    }

    // MARK: awakeWithContext helper methods
    fileprivate func initializeInterface(_ activity:KTPomodoroActivityModel) {
        self.currentBackgroundImageString = ""
        self.activityNameLabel!.setText(activity.name)
        self.plannedPomoLabel!.setText("\(activity.expected_pomo)")
        self.remainingPomoLabel!.setText("\(activity.expected_pomo)")
        self.statusMessageGroup!.setHidden(true)
        self.clearAllMenuItems()
    }

    fileprivate func registerUserDefaultChanges() {
        NotificationCenter.default.addObserver(self, selector: Selector("userDefaultsUpdated"), name: UserDefaults.didChangeNotification, object: nil)
    }

    fileprivate func updateInterfaceWithActiveActivity() {
        if (Int(self.activity?.status ?? 0) == Constants.KTPomodoroActivityStatus.inProgress.rawValue) {
            if let activeActivity = KTActivityManager.sharedInstance.activity {
                if (activeActivity != self.activity) {
                    // activity was active but timer stopped. restart timer.
                    if let activeActivity = self.activity {
                        KTActivityManager.sharedInstance.continueActivity(activeActivity)
                    }
                }
            }
            KTActivityManager.sharedInstance.delegate = self
            self.addMenuItem(with: WKMenuItemIcon.block, title: "Interrupt", action: Selector("interruptActivity:"))
            self.addMenuItem(with: WKMenuItemIcon.decline, title: "Stop", action: Selector("stopActivity:"))

        } else {
            if (!KTActivityManager.sharedInstance.hasOtherActiveActivityInSharedState(self.activity!.activityID)) {

                self.addMenuItem(with: WKMenuItemIcon.play, title: "Start", action: Selector("startActivity:"))
                self.addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: Selector("deleteActivity:"))

            } else {
                self.statusMessage?.setText(kActivityDetailsInterfaceControllerStatusMessageOtherActiveActivity)
                self.statusMessageGroup?.setHidden(false)
            }
        }
    }

    // MARK - didDeactivate helper methods
    fileprivate func unregisterUserDefaultChanges() {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
    }

    // MARK - registerUserDefaultChanges helper methods

    @objc func userDefaultsUpdated() {
        // TODO: handle the case when the defaults is updated while an activity is on-going
    }

    // MARK - Action Outlets
    func interruptActivity(_ id:AnyObject) {
        self.stopActivity(id)
        if let activity = self.activity {
            var interruptions = activity.interruptions.intValue
            interruptions += 1
            self.activity?.interruptions = interruptions as NSNumber
        }
    }

    func startActivity(_ id:AnyObject) {
        var error:NSError?
        let manager = KTActivityManager.sharedInstance
        manager.delegate = self
        if let activity = self.activity {
            manager.startActivity(activity, error: &error)

            if (error == nil) {
                self.timeLabel!.setText("\(KTSharedUserDefaults.pomoDuration):00")
                self.clearAllMenuItems()
                self.addMenuItem(with: WKMenuItemIcon.block, title: "Interrupt", action: Selector("interruptActivity:"))
                self.addMenuItem(with: WKMenuItemIcon.decline, title: "Stop", action: Selector("stopActivity:"))
            }
        }
    }

    func stopActivity(_ id:AnyObject) {
        KTActivityManager.sharedInstance.stopActivity()
        self.resetMenuItemsTimeLabel()
        self.resetBackgroundImage()
    }

    func deleteActivity(_ id:AnyObject?) {
        if let activity = self.activity {
            self.timeLabel!.setText("00:00")
            KTActivityManager.sharedInstance.stopActivity()
            KTCoreDataStack.sharedInstance.deleteActivity(activity)
            KTCoreDataStack.sharedInstance.saveContext()
        }
        self.pop()
    }

    // MARK - taskCompleted helper methods
    fileprivate func resetBackgroundImage() {
        self.timerRingInterfaceGroup!.setBackgroundImageNamed("circles_background")
    }

    fileprivate func resetMenuItemsTimeLabel() {
        self.clearAllMenuItems()
        self.addMenuItem(with: WKMenuItemIcon.play, title: "Start", action: Selector("startActivity:"))
        self.addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: Selector("deleteActivity:"))
        self.timeLabel!.setText("00:00")
    }

    fileprivate func shouldAutoDeleteCompletedTasks() -> Bool{
        return KTSharedUserDefaults.shouldAutoDeleteCompletedActivites
    }

    // MARK: KTActivityManagerDelegate method
    func activityManager(_ manager: KTActivityManager?, activityDidPauseForBreak elapsedBreakTime: Int) {

        let displayMinutes = Int(floor(Double(elapsedBreakTime)/60.0))
        let displaySecsString = Int(Double(elapsedBreakTime).truncatingRemainder(dividingBy: 60.0))

        self.timeLabel!.setText("\(displayMinutes):\(displaySecsString)")
        self.statusMessage?.setText(kActivityDetailsInterfaceControllerStatusMessageBreak)
        self.statusMessageGroup?.setHidden(false)

    }

    func activityManager(_ manager: KTActivityManager?, activityDidUpdate model: KTPomodoroActivityModel?) {
        if let activity = model {
            self.updateTimerBackgroundImage(activity)
            self.statusMessageGroup?.setHidden(true)

            let displayMinutes = KTTimerFormatter.formatTimeIntToTwoDigitsString(KTTimerFormatter.formatPomoRemainingMinutes(activity.current_pomo_elapsed_time.intValue))
            let displaySecsString = KTTimerFormatter.formatTimeIntToTwoDigitsString(KTTimerFormatter.formatPomoRemainingSecsInCurrentMinute(activity.current_pomo_elapsed_time.intValue))
            self.timeLabel!.setText("\(displayMinutes):\(displaySecsString)")

            let remainingPomos = activity.expected_pomo.intValue - activity.current_pomo.intValue
            self.remainingPomoLabel!.setText("\(remainingPomos)")


            if Int(activity.status) == Constants.KTPomodoroActivityStatus.completed.rawValue {
                self.activityCompleted()
            }
        }
    }

    // MARK: activityManager:activityDidUpdate helper methods

    fileprivate func activityCompleted() {
        self.resetMenuItemsTimeLabel()
        if (self.shouldAutoDeleteCompletedTasks()) {
            self.deleteActivity(nil)
        }
    }

    fileprivate func updateTimerBackgroundImage(_ activity:KTPomodoroActivityModel) {
        let elapsedSections = activity.current_pomo_elapsed_time.intValue / ((KTSharedUserDefaults.pomoDuration*60)/12)
        var backgroundImageString:String;
        if (elapsedSections < 10) {
            backgroundImageString = "circles_0\(elapsedSections)"
        } else {
            backgroundImageString = "circles_\(elapsedSections)"
        }
        if backgroundImageString != self.currentBackgroundImageString {
            self.currentBackgroundImageString = backgroundImageString
            self.timerRingInterfaceGroup!.setBackgroundImageNamed(backgroundImageString)
        }
    }


}
