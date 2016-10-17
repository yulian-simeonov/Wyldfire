//
//  CoreData.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 1/12/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

static NSManagedObjectModel* _model;
static NSManagedObjectContext* _context;
static NSPersistentStoreCoordinator* _coordinator;

@implementation CoreData

+ (NSPersistentStoreCoordinator *)coordinator
{
    return _coordinator;
}

+ (NSManagedObjectContext *)context
{
    return _context;
}

+ (NSManagedObjectModel*)model
{
    return _model;
}

+ (void)configure
{
    _model = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
    NSURL *url = [NSURL fileURLWithPath:[[WFCore documentsDirectory] stringByAppendingPathComponent:@"Wyldfire.sqlite"]];
    NSError *error;
    if (![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        Error(@"%@", error);
    }
    
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_context setPersistentStoreCoordinator:_coordinator];
}

+ (void)remove:(NSManagedObject*)object
{
    @synchronized(self) {
        [self.context deleteObject:object];
        [self save];
    }
}

+ (void)save
{
    @synchronized(self) {
        NSError *error;
        if (![self.context save:&error]) {
            Error(@"%@", error);
        }
    }
}

+ (NSArray*)get:(NSString*)type where:(NSPredicate*)where sort:(NSArray*)sort error:(NSError**)error
{
    @synchronized(self) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:type inManagedObjectContext:_context]];
        if (where) [fetchRequest setPredicate:where];
        if (sort) [fetchRequest setSortDescriptors:sort];
        NSArray *results = [_context executeFetchRequest:fetchRequest error:error];
        return results;
    }
}

+ (NSManagedObject*)create:(NSString*)type
{
    @synchronized(self) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:type inManagedObjectContext:_context];
        return object;
    }
}

+ (void)deleteAll
{
    [self deleteAllObjects:@"DBAccount"];
    [self deleteAllObjects:@"Message"];
}

+ (void) deleteAllObjects: (NSString *) entityDescription  {
    @synchronized(self) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        NSError *error;
        NSArray *items = [_context executeFetchRequest:fetchRequest error:&error];
        
        for (NSManagedObject *managedObject in items) {
            [_context deleteObject:managedObject];
        }
        if (![_context save:&error]) {
            NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
        }
    }
}

@end
