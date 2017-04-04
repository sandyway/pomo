//
//  KTCoreDataStack.swift
//  Cherry
//
//  Created by Kenny Tang on 2/23/15.

//
//

import Foundation
import CoreData

open class KTCoreDataStack {

    fileprivate struct KTCoreDataStackConstants {
        static let appGroupID = "group.me.donguo.KTPomodoro"
        static let shouldUseAppGroupsForStorage = false
    }

    open class var sharedInstance:KTCoreDataStack {
        struct Singleton {
            static let instance = KTCoreDataStack()
        }
        return Singleton.instance
    }

    // MARK - helper methods
    open func createActivity(_ name:String, desc:String, pomos:Int) -> KTPomodoroActivityModel? {

        var newActivity = NSEntityDescription.insertNewObject(forEntityName: "KTPomodoroActivityModel", into: self.managedObjectContext!) as! KTPomodoroActivityModel;
        newActivity.name = name
        newActivity.desc = desc
        newActivity.status = Constants.KTPomodoroActivityStatus.stopped.rawValue as NSNumber
        newActivity.expected_pomo = pomos as NSNumber
        newActivity.actual_pomo = 0
        newActivity.created_time = Date()
        newActivity.activityID = UUID().uuidString
        return newActivity
    }

    open func deleteActivity(_ activity:KTPomodoroActivityModel) {
        self.managedObjectContext?.delete(activity)
        self.saveContext()
    }

    open func allActivities() -> [KTPomodoroActivityModel]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "KTPomodoroActivityModel")
        request.sortDescriptors = [
            NSSortDescriptor(key: "created_time", ascending: false),
            NSSortDescriptor(key: "status", ascending: true)
        ]
        do {
            return try self.managedObjectContext?.fetch(request) as! [KTPomodoroActivityModel]?
        } catch  {
            return nil
        }
    }

    // MARK - Core Data methods

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cogitoergosum.Test2" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as! URL
        }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "KTPomodoroActivityModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
        }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var containerURL:URL?;
        if (KTCoreDataStackConstants.shouldUseAppGroupsForStorage) {
            containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: KTCoreDataStackConstants.appGroupID)?.appendingPathComponent("Cherry.sqlite")

        } else {
            containerURL = self.applicationDocumentsDirectory.appendingPathComponent("Cherry.sqlite")
        }

        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            if try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: containerURL, options: nil) == nil {
                coordinator = nil
                // Report any error we got.
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
                dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
                dict[NSUnderlyingErrorKey] = error
                error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                // Replace this with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }catch {
        
        }
        

        return coordinator
        }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()

    // MARK: - Core Data Saving support

    open func saveContext () {
        if let moc = self.managedObjectContext {
            do {
                if moc.hasChanges {
                    try moc.save()
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                }
            } catch  {
//                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }


}

