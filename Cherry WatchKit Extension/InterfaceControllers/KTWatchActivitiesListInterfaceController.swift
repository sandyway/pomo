//
//  KTWatchActivitiesListInterfaceController.swift
//  Cherry
//
//  Created by Kenny Tang on 2/24/15.
//
//

import WatchKit
import Foundation


class KTWatchActivitiesListInterfaceController: WKInterfaceController {

    var activitiesList:[KTPomodoroActivityModel]!
    @IBOutlet weak var table: WKInterfaceTable!


    // MARK: overrides
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.setUpTable()
    }

    override func handleUserActivity(_ userInfo: [AnyHashable: Any]!) {
        if let userInfo = userInfo {
            if let activityType = userInfo["type"] as? String{
                if (activityType == "me.donguo.KTPomodoro.select_activity") {
                    self.handleUserActivitySelectActivity(userInfo)
                }
            }
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        if (segueIdentifier == "activityDetailsSegue") {
            return self.activitiesList[rowIndex]
        }
        return nil
    }

    // MARK: handleUserActivity helper methods

    fileprivate func handleUserActivitySelectActivity(_ userInfo:[AnyHashable: Any]) {
        if let selectedActivityID = userInfo["activityID"] as? String {
            for activity in self.activitiesList {
                if (activity.activityID == selectedActivityID) {
                    self.pushController(withName: "KTWatchActivityInterfaceController", context: activity)
                    break
                }
            }
        }
    }

    fileprivate func setUpTable() {

        var activitiesCount = 0
        if let activitiesList = KTCoreDataStack.sharedInstance.allActivities() as [KTPomodoroActivityModel]?{
            activitiesCount = activitiesList.count

            // FIXME: there seems to be a bug with beta5. When a table is rebuilt, the cells' labels don't get set properly
            // Workaround now is to avoid tearing down the original table, but this depends on the assumption that the number of rows has changed.
            if (self.activitiesList?.count != activitiesList.count) {
                self.clearTableRows()

                self.createTableFromActivitiesList(activitiesList)

                self.table.insertRows(at: IndexSet(integersIn: NSMakeRange(activitiesCount, 1).toRange() ?? 0..<0), withRowType: "KTWatchAddActivityRowInterfaceController")

            } else {
                // just update rows
                self.updateTableFromActivitiesList(activitiesList)

            }

            self.activitiesList = activitiesList
      }
    }

    // MARK: setUpTable helper methods

    fileprivate func clearTableRows() {
        self.table.removeRows(at: IndexSet(integersIn: NSMakeRange(0, self.table.numberOfRows).toRange()!))

    }

    fileprivate func updateTableFromActivitiesList(_ activitiesList:[KTPomodoroActivityModel]) {
        var i = 0
        for activity in activitiesList {
            if let rowInterfaceController = self.table.rowController(at: i) as? KTWatchActivitiesRowInterfaceController{

                // ordering of row might have changed. set the status value and visibility accordingly
                if (Int(activity.status) == Constants.KTPomodoroActivityStatus.inProgress.rawValue) {
                    rowInterfaceController.activityStatusLabel?.setText("In Progress")
                    rowInterfaceController.activityStatusLabel?.setHidden(false)
                } else {
                    rowInterfaceController.activityStatusLabel?.setHidden(true)
                }
            }
            i += 1
        }

    }

    fileprivate func createTableFromActivitiesList(_ activitiesList:[KTPomodoroActivityModel]) {

        // insert the rows first
        self.table.insertRows(at: IndexSet(integersIn: NSMakeRange(0, activitiesList.count).toRange()!), withRowType: "KTWatchActivitiesRowInterfaceController")

        // populate the data of each row
        var cellAlpha:CGFloat = 1.0
        var i = 0
        for activity in activitiesList {

            if let rowInterfaceController = self.table.rowController(at: i) as? KTWatchActivitiesRowInterfaceController{

                rowInterfaceController.activityNameLabel!.setText(activity.name)
                if (activity.status == Constants.KTPomodoroActivityStatus.inProgress.rawValue as NSNumber) {
                    rowInterfaceController.activityStatusLabel?.setText("In Progress")
                    rowInterfaceController.activityStatusLabel?.setHidden(false)
                }
                // UI: make the rows reduce opacity by row
                rowInterfaceController.activityRowGroup?.setAlpha(cellAlpha)

                // only show status label on top most activity
                if (i > 0) {
                    rowInterfaceController.activityStatusLabel?.setHidden(true)
                }

                // TODO: do something more efficient like using an asset?
                rowInterfaceController.activityRowGroup?.setCornerRadius(cellAlpha)

                // reduce opacity
                if (cellAlpha > 0.2) {
                    cellAlpha -= 0.2
                }
            }
            i += 1
        }
    }

}
