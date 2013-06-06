//
//  CachedObject+Logic.m
//  RequestCacher
//
//  Created by Gorgan Alin on 3/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "CachedObject+Logic.h"

@implementation CachedObject (Logic)

+(CachedObject*)objectWithEncodedData:(NSData*)encodedData
                           matchingId:(NSString*)matchingId
                                group:(NSString*)group
                              section:(NSString*)section
                           andContext:(NSManagedObjectContext*)context{
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"CachedObject"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(group=%@) AND (matchingId=%@)",
                              group, matchingId];
    if (section != nil){
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(group=%@) AND (matchingId=%@) AND (section=%@)",
                                  group, matchingId, section];
    }
    
    NSError *error = nil;
    NSArray* matches = [context executeFetchRequest:fetchRequest error:&error];
    CachedObject *cachedObject = nil;
    
    if (matches.count == 0){
        cachedObject = [NSEntityDescription insertNewObjectForEntityForName:@"CachedObject"
                                                                inManagedObjectContext:context];
        cachedObject.matchingId = matchingId;
        cachedObject.encodedData = encodedData;
        cachedObject.dateAdded = [NSDate date];
        cachedObject.section = section;
        cachedObject.group = group;
    }
    else if (matches.count == 1){
        cachedObject = [matches objectAtIndex:0];
        
        /// in case the data has changed
        cachedObject.encodedData = encodedData;
    }
    else if (matches.count > 1){
        return cachedObject;
    }
    
    return cachedObject;
    
}
@end
