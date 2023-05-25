import Foundation
import CoreData

protocol PersistenceManagerProtocol {
    var managedObjectContext: NSManagedObjectContext { get }
    var backgroundTaskManagedContext: NSManagedObjectContext { get }
    
    func getAll<T: NSManagedObject>(context: NSManagedObjectContext,
                                    type: T.Type,
                                    sortDescriptors: [NSSortDescriptor]?) -> [T]?
    func getModel<T: NSManagedObject>(context: NSManagedObjectContext, id: String, type: T.Type) -> T?
    func save(context: NSManagedObjectContext)
    func saveMainContext()
}
