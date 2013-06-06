//
//  CDObjectStore.m
//  RequestCacher
//
//  Created by Gorgan Alin on 3/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "CDObjectStore.h"
#import "CachedObject+Logic.h"
#import "CoreDataStack.h"

@interface CDObjectStore()

@property (nonatomic, strong) NSManagedObjectContext* currentContext;

@end

@implementation CDObjectStore

@synthesize currentContext;

-(id)init{
    if (self = [super init]){
        /// Set-up core data, it uses dispatch_once, so no matter if it's allready set up
        [[CoreDataStack sharedStackManager] setUp];
        self.currentContext = [[CoreDataStack sharedStackManager] managedObjectContext];
    }
    
    return self;
}

-(void)addObject:(id<NSCoding>)object
      matchingId:(NSString*)matchingId
         section:(NSString*)section
           group:(NSString*)group{
    
    [CachedObject objectWithEncodedData:[self encodeObject:object]
                             matchingId:matchingId
                                  group:group
                                section:section
                             andContext:currentContext];
}


-(NSData*)encodeObject:(id<NSCoding>)object{
    return [NSKeyedArchiver archivedDataWithRootObject:object];;
}

-(id)decodeData:(NSData*)encodedData{
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
}

-(void)saveChanges{
    NSError *error = nil;
    if (![self.currentContext save:&error]){
        NSLog(@"Error saving changes: %@", error.debugDescription);
    }
        
}

+(NSDecodingFetchedResultsController*)fetchResultsControllerForGroup:(NSString*)group
                                                        andBatchSize:(NSInteger)batchRequestSize{
    //// Initialize the core data stack
    /// Uses dispatch once
    [[CoreDataStack sharedStackManager] setUp];
    
    NSManagedObjectContext* currentContext = [[CoreDataStack sharedStackManager] managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CachedObject"
                                                         inManagedObjectContext:currentContext];
    [request setEntity:entityDescription];
    request.fetchBatchSize = batchRequestSize;
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Filter for results for this table view controller alone
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group = %@", group];
    [request setPredicate:predicate];
    
    NSString *cacheName = [group stringByAppendingString:@"_cache"];
    
    return [[NSDecodingFetchedResultsController alloc] initWithFetchRequest:request
                                                           managedObjectContext:currentContext
                                                             sectionNameKeyPath:@"section"
                                                                      cacheName:cacheName];
}


@end
