//
//  KTActiveActivityState.swift
//  Cherry
//
//  Created by Kenny Tang on 2/22/15.
//
//
import UIKit

class KTActiveActivityState: NSObject, NSCoding {

    var activityID:String = ""
    var activityName:String = ""
    var status:Int = 0
    var currentPomo:Int = 0
    var elapsedSecs:Int = 0

    init(id: String, name:String, status:Int, currentPomo:Int, elapsed:Int) {
        self.activityID = id
        self.activityName = name
        self.status = status
        self.currentPomo = currentPomo
        self.elapsedSecs = elapsed
    }

    required init(coder aDecoder: NSCoder) {
        activityID = aDecoder.decodeObject(forKey: "activityID") as! String
        activityName = aDecoder.decodeObject(forKey: "activityName") as! String
        status = aDecoder.decodeObject(forKey: "status") as? Int ?? 0
        currentPomo = aDecoder.decodeObject(forKey: "currentPomo") as? Int ?? 0
        elapsedSecs = aDecoder.decodeObject(forKey: "elapsedSecs") as? Int ?? 0
    }

     func encode(with aCoder: NSCoder) {
        aCoder.encode(activityID, forKey: "activityID")
        aCoder.encode(activityName, forKey: "activityName")
        aCoder.encode(status, forKey: "status")
        aCoder.encode(currentPomo, forKey: "currentPomo")
        aCoder.encode(elapsedSecs, forKey: "elapsedSecs")
    }

}
