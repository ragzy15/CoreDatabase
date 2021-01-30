//
//  PersistentHistoryFetcher.swift
//  CoreDataKit
//
//  Created by Raghav Ahuja on 13/10/20.
//

import CoreData

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct PersistentHistoryFetcher {

    enum Error: Swift.Error {
        /// In case that the fetched history transactions couldn't be converted into the expected type.
        case historyTransactionConvertionFailed
    }

    let context: NSManagedObjectContext
    let fromDate: Date

    func fetch() throws -> [NSPersistentHistoryTransaction] {
        let fetchRequest = createFetchRequest()

        guard let historyResult = try context.execute(fetchRequest) as? NSPersistentHistoryResult,
              let history = historyResult.result as? [NSPersistentHistoryTransaction] else {
            throw Error.historyTransactionConvertionFailed
        }

        return history
    }

    func createFetchRequest() -> NSPersistentHistoryChangeRequest {
        let historyFetchRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: fromDate)

        if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
            var predicates: [NSPredicate] = []

            if let transactionAuthor = context.transactionAuthor {
                /// Only look at transactions created by other targets.
                predicates.append(NSPredicate(format: "%K != %@", #keyPath(NSPersistentHistoryTransaction.author), transactionAuthor))
            }
            if let contextName = context.name {
                /// Only look at transactions not from our current context.
                predicates.append(NSPredicate(format: "%K != %@", #keyPath(NSPersistentHistoryTransaction.contextName), contextName))
            }

            fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
            historyFetchRequest.fetchRequest = fetchRequest
        }

        return historyFetchRequest
    }
}
