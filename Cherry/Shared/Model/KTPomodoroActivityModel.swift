//
//  KTPomodoroActivityModel.swift
//  Cherry
//
//  Created by Kenny Tang on 2/22/15.
//
//

import Foundation
import CoreData

// Fix for unit test error "swift core data dynamic_Cast Class Unconditional"
// http://stackoverflow.com/a/25106423

@objc(KTPomodoroActivityModel)

open class KTPomodoroActivityModel: NSManagedObject {

    @NSManaged open var activityID: String
    @NSManaged open var actual_pomo: NSNumber
    @NSManaged open var created_time: Date
    @NSManaged open var current_pomo: NSNumber
    @NSManaged open var current_pomo_elapsed_time: NSNumber
    @NSManaged open var desc: String
    @NSManaged open var expected_pomo: NSNumber
    @NSManaged open var interruptions: NSNumber
    @NSManaged open var name: String
    @NSManaged open var status: NSNumber

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?){
        super.init(entity: entity, insertInto:context)
    }

}


