//
//  KTActivityManager.swift
//  Cherry
//
//  Created by Kenny Tang on 2/22/15.
//
//
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


protocol KTActivityManagerDelegate {
    func activityManager(_ manager:KTActivityManager?, activityDidUpdate model:KTPomodoroActivityModel?)

    func activityManager(_ manager:KTActivityManager?, activityDidPauseForBreak elapsedBreakTime:Int)

}

class KTActivityManager {

    // MARK: - Properties

    var activity:KTPomodoroActivityModel?
    var activityTimer:Timer?
    var breakTimer:Timer?
    var currentPomo:Int?
    var breakElapsed:Int?

    var delegate:KTActivityManagerDelegate?


    // MARK: - Public

    class var sharedInstance: KTActivityManager {
        struct Static {
            static let instance: KTActivityManager = KTActivityManager()
        }
        return Static.instance
    }

    func startActivity(_ activity:KTPomodoroActivityModel, error:NSErrorPointer) {

        if (self.hasOtherActiveActivityInSharedState(activity.activityID)) {
            error?.pointee =  NSError(domain:"me.donguo.net",
                code: Constants.KTPomodoroStartActivityError.otherActivityActive.rawValue,
                userInfo: nil)
            return
        }

        // initialize internal variables
        self.intializeInternalState(activity)

        // start timer
        self.startActivityTimer()
    }

    func continueActivity(_ activity:KTPomodoroActivityModel) {
        self.activity = activity
        self.currentPomo = activity.current_pomo.intValue
        self.updateSharedActiveActivityStateFromModel(activity)
        self.startActivityTimer()
    }

    func stopActivity() {
        self.activity?.status = Constants.KTPomodoroActivityStatus.stopped.rawValue as NSNumber
        if let activity = self.activity {
            self.updateSharedActiveActivityStateFromModel(activity)
        }

        // save to disk
        KTCoreDataStack.sharedInstance.saveContext()

        self.resetManagerInternalState()
    }


    // MARK: - Private
    // MARK: startActivity: helper methods

    func resetManagerInternalState() {
        self.activity = nil
        self.currentPomo = 0
        self.breakElapsed = 0
        self.invalidateTimers()
    }

    func startActivityTimer () {
        self.invalidateTimers()

        self.activityTimer = Timer(timeInterval: 1, target: self, selector: Selector("activityTimerFired"), userInfo: nil, repeats: true)

        self.scheduleTimerInRunLoop(self.activityTimer!)

    }

    func intializeInternalState(_ activity:KTPomodoroActivityModel) {
        self.currentPomo = 1;
        self.breakElapsed = 0;

        activity.current_pomo = 0;
        activity.current_pomo_elapsed_time = 0
        activity.status = Constants.KTPomodoroActivityStatus.inProgress.rawValue as NSNumber
        self.activity = activity;

        self.updateSharedActiveActivityStateFromModel(activity)

    }

    func hasOtherActiveActivityInSharedState(_ ID:String) -> Bool {
        if let activity = self.activeActivityInSharedStorage() as KTActiveActivityState? {
            return activity.activityID != ID
        }

        return false
    }

    func activeActivityInSharedStorage() -> KTActiveActivityState? {
        if let activityData = KTSharedUserDefaults.sharedUserDefaults.object(forKey: "ActiveActivity") as? Data {

            if let activity = NSKeyedUnarchiver.unarchiveObject(with: activityData) as? KTActiveActivityState{
                return activity
            }
        }
        return nil
    }

    func updateSharedActiveActivityStateFromModel(_ activeActivity:KTPomodoroActivityModel) {

        var updatedActiveActivity:KTActiveActivityState

        if let sharedActivity = self.activeActivityInSharedStorage(){
            if (sharedActivity.activityID == activeActivity.activityID) {
                // update existing object
                updatedActiveActivity = sharedActivity
                updatedActiveActivity.currentPomo = activeActivity.current_pomo.intValue
                updatedActiveActivity.status = activeActivity.status.intValue
                updatedActiveActivity.elapsedSecs = activeActivity.current_pomo_elapsed_time.intValue
            } else {
                updatedActiveActivity = self.createActiveActivityFromModel(activeActivity)
            }
        } else {
            //creaate new object the first time
            updatedActiveActivity = self.createActiveActivityFromModel(activeActivity)
        }

        if (updatedActiveActivity.status == Constants.KTPomodoroActivityStatus.stopped.rawValue) {

            KTSharedUserDefaults.sharedUserDefaults.removeObject(forKey: "ActiveActivity")

        } else {
            let encodedActivity:Data = NSKeyedArchiver.archivedData(withRootObject: updatedActiveActivity);
            KTSharedUserDefaults.sharedUserDefaults.set(encodedActivity, forKey: "ActiveActivity")
        }
        KTSharedUserDefaults.sharedUserDefaults.synchronize()
    }

    func createActiveActivityFromModel(_ activeActivity:KTPomodoroActivityModel) -> KTActiveActivityState {
        return KTActiveActivityState(id: activeActivity.activityID,
            name: activeActivity.name,
            status: activeActivity.status.intValue,
            currentPomo: activeActivity.current_pomo.intValue,
            elapsed: activeActivity.current_pomo_elapsed_time.intValue)
    }

    func invalidateTimers() {
        self.activityTimer?.invalidate()
        self.breakTimer?.invalidate()
    }

    func scheduleTimerInRunLoop(_ timer:Timer) {
        RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
    }

    // MARK - timers helper methods

    @objc func activityTimerFired() {
        // increment current pomo elapsed time
        self.activity?.current_pomo = self.currentPomo! as NSNumber

        var currentPomoElapsed = 0
        if let elapsed = self.activity?.current_pomo_elapsed_time.intValue {
            currentPomoElapsed = elapsed + 1
            self.activity?.current_pomo_elapsed_time = currentPomoElapsed as NSNumber
        }

        self.delegate?.activityManager(self, activityDidUpdate: self.activity)

        if let activity = self.activity {
            self.updateSharedActiveActivityStateFromModel(activity)
        }

        if (currentPomoElapsed == KTSharedUserDefaults.pomoDuration*60) {
            // reached end of pomo
            self.handlePomoEnded()
        }
    }

    // Swift Gotchas
    @objc func breakTimerFired() {
        self.breakElapsed! += 1
        if (self.breakElapsed < KTSharedUserDefaults.breakDuration*60) {
            self.delegate?.activityManager(self, activityDidPauseForBreak: self.breakElapsed!)
        } else {
            self.invalidateTimers()
            self.breakElapsed = 0
            self.startNextPomo()
        }
    }

    // MARK: breakTimerFired: helper methods
    func startNextPomo() {
        print("starting next pomo")

        self.activity?.current_pomo = self.currentPomo! as NSNumber;
        self.activity?.current_pomo_elapsed_time = 0;
        // restart the timer
        self.activityTimer = Timer(timeInterval: 1, target: self, selector: Selector("activityTimerFired"), userInfo: nil, repeats: true)

        self.scheduleTimerInRunLoop(self.activityTimer!)
    }

    // MARK: activityTimerFired: helper methods
    func handlePomoEnded() {
        if (self.activityHasMorePomo(self.activity)) {
            self.currentPomo! += 1
            self.activity?.current_pomo = self.currentPomo! as NSNumber
            self.pauseActivityStartBreak()
        } else {
            self.completeActivityOnLastPomo()
        }
        
    }

    // MARK: handlePomoEnded helper methods
    func completeActivityOnLastPomo() {
        self.activity?.status = Constants.KTPomodoroActivityStatus.completed.rawValue as NSNumber
        self.activity?.actual_pomo = self.currentPomo! as NSNumber

        // save to disk
        KTCoreDataStack.sharedInstance.saveContext()

        self.delegate?.activityManager(self, activityDidUpdate: self.activity)

        self.resetManagerInternalState()
    }


    func pauseActivityStartBreak() {
        self.activityTimer?.invalidate()
        self.startBreakTimer()
    }

    func startBreakTimer() {
        print("starting break")
        self.breakTimer?.invalidate()
        self.breakTimer = Timer(timeInterval: 1, target: self, selector: Selector("breakTimerFired"), userInfo: nil, repeats: true)
        self.scheduleTimerInRunLoop(self.breakTimer!)
    }

    func activityHasMorePomo(_ activity:KTPomodoroActivityModel?) -> Bool{
        if let activity = activity {
            let expectedPomo = activity.expected_pomo.intValue
            if let currentPomo = self.currentPomo {
                return expectedPomo > currentPomo
            }
        }
        return false
    }
}
