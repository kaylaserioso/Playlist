import Foundation
import CoreData

class PersistenceManager: PersistenceManagerProtocol {
    private let modelName: String

    private lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    lazy var managedObjectContext: NSManagedObjectContext = self.storeContainer.viewContext
    
    lazy var backgroundTaskManagedContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        return context
    }()
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    func getAll<T: NSManagedObject>(context: NSManagedObjectContext,
                                    type: T.Type,
                                    sortDescriptors: [NSSortDescriptor]? = nil) -> [T]? {
        let allFetch: NSFetchRequest<T> = NSFetchRequest(entityName: String(describing: T.self))
        allFetch.sortDescriptors = sortDescriptors
        do {
            let results = try context.fetch(allFetch)
            return results
        } catch {
            return []
        }
    }
    
    func getModel<T: NSManagedObject>(context: NSManagedObjectContext, id: String, type: T.Type) -> T? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            return nil
        }
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
    /**
        Use for saving using `managedObjectContext` that is directly connected to the persistent coordinator
     */
    func saveMainContext() {
        save(context: managedObjectContext)
    }
}
