//
//  CoreData.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 1/12/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@interface CoreData : NSObject

+ (NSManagedObjectModel*)model;
+ (NSManagedObjectContext*)context;
+ (NSPersistentStoreCoordinator*)coordinator;

// Initialize the moc that will be used by the application
+ (void)configure;

// Save all unsaved changes to the managed object context thus underlying data store
+ (void)save;

// Load an array of managed object contexts that match the predicates
+ (NSArray*)get:(NSString*)type where:(NSPredicate*)where sort:(NSArray*)sort error:(NSError**)error;

// Creates a new managed object of the specified type in the managed object context, will not be saved until the context has been synchronized
+ (NSManagedObject*)create:(NSString*)type;

// Delete a managed object from the context
+ (void)remove:(NSManagedObject*)object;

//Nuclear Option
+ (void)deleteAll;

@end
