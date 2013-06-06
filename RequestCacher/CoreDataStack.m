//
//  CoreDataStack.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/10/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "CoreDataStack.h"
#import <CoreData/CoreData.h>
#import "FileStore.h"

@interface CoreDataStack ()

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSMutableDictionary* threadMOCs;

@end

@implementation CoreDataStack

@synthesize managedObjectModel=_managedObjectModel;
@synthesize persistentStoreCoordinator=_persistentStoreCoordinator;
@synthesize threadMOCs = _threadMOCs;


-(NSNumber*) threadHash{
     return [NSNumber numberWithInt:[[NSThread currentThread] hash]];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Singleton instance
#pragma ------------------------------------------------------------------------------------------------------
///Returns a shared instance to this class
+(CoreDataStack*)sharedStackManager{
    static CoreDataStack* sharedStack = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStack = [[self alloc] init];
    });
    
    return sharedStack;
}


#pragma ------------------------------------------------------------------------------------------------------
#pragma Application documents directory
#pragma ------------------------------------------------------------------------------------------------------

// Returns the name of the store, based on the app's name
-(NSString*)storeName{
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    appName = [appName stringByAppendingString:@".Store"];
    
    return appName;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Core data stack methods
#pragma ------------------------------------------------------------------------------------------------------

//// This method should be called before a thread queue.
//// We don't each thread, from an async queue, to try set-up the stack
-(void)setUp{
    /// create the persistent store coordinator.
    /// this is thread safe and we have only one, shared for all threads to use
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self persistentStoreCoordinator];
    });
}


/// save changes to the managed object context associated with the calling thread
- (void)saveCurrentContextChanges
{
    NSLock *arrayLock = [[NSLock alloc] init];
    [arrayLock lock];
    
    NSManagedObjectContext* managedObjectContext = [self getManagedObjectContextWithThreadID:[self threadHash]];
    [self saveChangesToContext:managedObjectContext];
    
    [arrayLock unlock];
}

-(void)saveChangesToContext:(NSManagedObjectContext*)managedObjectContext{
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

//
//Returns the managed object context
//If the context doesn't already exist, it is created and bound to the persistent store coordinator.
//There's a single store coordinator for all managed object contexts.
//Though, we can have multiple managed object contexts, for each calling thread, following the thread confinement pattern.
- (NSManagedObjectContext *) managedObjectContext
{
    /// This can be called from different threads, create a lock for the MOC array
    NSLock *arrayLock = [[NSLock alloc] init];
    [arrayLock lock];
    
    NSManagedObjectContext *moc = [self getManagedObjectContextWithThreadID:[self threadHash]];
    
    if (moc != nil) {
        return moc;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [moc setPersistentStoreCoordinator: coordinator];
        
        ///add the managed object context for the current calling thread
        
        [self.threadMOCs setObject:moc forKey:[self threadHash]];
    }
    
    /// unlock the MOC array
    [arrayLock unlock];
    
    return moc;

}

///
/// For thread safety, returns the managed object context associated with the calling thread, if any
- (NSManagedObjectContext*) getManagedObjectContextWithThreadID:(NSNumber*) threadID {
    if (!self.threadMOCs){
        self.threadMOCs=[NSMutableDictionary dictionaryWithCapacity:16];
    }
    
    NSManagedObjectContext* threadMOC = nil;
    if ([self.threadMOCs objectForKey:threadID]==nil) {
        threadMOC = [self.threadMOCs objectForKey:threadID];
    }
    
    return threadMOC;
}

//
// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CacheModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


//
//Returns the persistent store coordinator for the application.
//If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[FileStore applicationDocumentsDirectory] URLByAppendingPathComponent:[self storeName]];
    NSLog(@"storeURL %@", storeURL.absoluteString);
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES],
                                                                        NSMigratePersistentStoresAutomaticallyOption,
                                                                        [NSNumber numberWithBool:YES],
                                                                        NSInferMappingModelAutomaticallyOption,
                                                                        nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    NSError *error;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        
        NSLog(@"error creating store coordinator %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

@end
