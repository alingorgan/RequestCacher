//
//  Request+Cache.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/30/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "Request+Cache.h"
#import "FileStore.h"
#import "CoreDataStack.h"

@implementation Request (Cache)

/// cache maximum size
#define CACHE_SIZE_LIMIT_BYTES 50000000

/// amount of extra cache data(bytes) to delete
/// so we have some free space bellow the limit
#define CACHE_BATCH_DELETE_BYTES 10000000

#pragma ------------------------------------------------------------------------------------------------------
#pragma Returns the cached request if there is any record of it in the database
#pragma ------------------------------------------------------------------------------------------------------
+(Request*)requestWithURL:(NSString*)requestURL
               andContext:(NSManagedObjectContext*)context{
    
    Request* request = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Request"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"url = %@", requestURL];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:fetchRequest error:&error];
    
    if (!matches || matches.count > 1){
        /// this should never happen
        /// the document shouldn't contain duplicates
        NSLog(@"Found duplicate records in the DB");
    }
    else if (matches.count == 0){
        /// the image was not found, it may need to be downloaded
        request = nil;
    }
    else{
        /// the image already exists in the database
        /// return it
        request = [matches lastObject];
        
        /// check if we reached the timeout
        if (-[request.date timeIntervalSinceNow] > [request.timeout floatValue] &&
            [request.timeout floatValue] > 0){
            
            /// remove any trace of the file or record
            [FileStore deleteFileWithPath:request.responseFilePath];
            [context deleteObject:request];
            
            /// save changes to the db
            [[CoreDataStack sharedStackManager] saveChangesToContext:context];
            
            request = nil;
            NSLog(@"timeout from cache");
        }
        NSLog(@"from cache %@", request.url);
    }
    
    return request;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma This creates a new cached request from the downloaded data and adds it to the database
#pragma ------------------------------------------------------------------------------------------------------
+(Request*)requestWithData:(NSData*)requestData
                requestURL:(NSString*)requestURL
                   timeout:(NSTimeInterval)timeout
                andContext:(NSManagedObjectContext*)context{
    
    NSString* filePath = [FileStore pathForNewFileUsingData:requestData andFileType:KStoreCacheNormalFile];
    
    if (filePath == nil){
        NSLog(@"Couldn't create the data file");
        return nil;
    }
    
    Request* request = nil;
    request = [NSEntityDescription insertNewObjectForEntityForName:@"Request"
                                            inManagedObjectContext:context];
    
    request.url = requestURL;
    request.responseFilePath = filePath;
    request.date = [NSDate date];
    request.timeout = [NSNumber numberWithFloat:timeout];
    
    NSLog(@"added request to cache %@", filePath);
    
    return request;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma This removes all request records from the Request table
#pragma ------------------------------------------------------------------------------------------------------
+(void)removeAllCachedRequestsUsingContext:(NSManagedObjectContext*)context{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Request"];
    NSError *error = nil;
    
    NSArray *requests = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error){
        NSLog(@"error clearing cache: %@", [error description]);
        return;
    }
    else{
        for (Request *request in requests) {
            /// remove any trace of the file or record
            [FileStore deleteFileWithPath:request.responseFilePath];
            [context deleteObject:request];
        }
    }
    /// save changes to the db
    [[CoreDataStack sharedStackManager] saveChangesToContext:context];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Delete old data from cache if cache size excedes a specified limit
#pragma ------------------------------------------------------------------------------------------------------
+(void)runCacheMaintainanceWithContext:(NSManagedObjectContext*)context{
    
    /// we do this once and only once, per application lifecycle
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ///get the current cache size
        unsigned long long cacheSize = [FileStore directorySizeForFileType:KStoreCacheNormalFile];
        
        /// Phase 1
        /// Delete the expired data (requests with exceded timeouts)
        if (cacheSize > CACHE_SIZE_LIMIT_BYTES){
            NSArray *expiredRequestsArray = [Request expiredRequestsWithContext:context];
            NSLog(@"Deleting %lu expired requests", (unsigned long)expiredRequestsArray.count);
            [Request performMaintenanceUsingRequestsArray:expiredRequestsArray cacheSize:(cacheSize) andContext:context];
        }
        
        /// Phase 2
        /// Delete the old data, from the oldes to the newest
        cacheSize = [FileStore directorySizeForFileType:KStoreCacheNormalFile];
        if (cacheSize > CACHE_SIZE_LIMIT_BYTES){
            NSArray *oldRequestsArray = [Request requestsOrderedByDateAscendingWithContext:context];
            NSLog(@"Deleting %lu old requests", (unsigned long)oldRequestsArray.count);
            [Request performMaintenanceUsingRequestsArray:oldRequestsArray cacheSize:(cacheSize) andContext:context];
        }
    });
}

+(void)performMaintenanceUsingRequestsArray:(NSArray*)requestsArray
                                  cacheSize:(unsigned long long)cacheSize
                                 andContext:(NSManagedObjectContext*)context{
    
    if (requestsArray.count == 0){
        return;
    }
    
    /// calculate the amount of data to remove
    long long batchDeleteMaxAmountBytes = cacheSize - CACHE_SIZE_LIMIT_BYTES + CACHE_BATCH_DELETE_BYTES;
    
    [Request deleteRequestsFromArray:requestsArray usingContext:context untilFreeing:batchDeleteMaxAmountBytes];
    
    /// save changes to the db
    [[CoreDataStack sharedStackManager] saveChangesToContext:context];
}


+(void)deleteRequestsFromArray:(NSArray*)requestArray
                  usingContext:(NSManagedObjectContext*)context
                  untilFreeing:(long long)batchDeleteMaxAmountBytes{
    
    /// choose how many requests to delete
    long long batchDeletedBytes = 0;
    for (int requestIndex = 0; requestIndex < requestArray.count; requestIndex++) {
        Request *request = [requestArray objectAtIndex:requestIndex];
        batchDeletedBytes += [FileStore fileSizeWithPath:request.responseFilePath];
        if (batchDeletedBytes > batchDeleteMaxAmountBytes){
            break;
        }
        /// delete both file and record
        [FileStore deleteFileWithPath:request.responseFilePath];
        [context deleteObject:request];
    }
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Returns expired requests(that exceed timeout).
#pragma When running maintainance, we clear out expired data first.
#pragma ------------------------------------------------------------------------------------------------------
+(NSArray*)requestsOrderedByDateAscendingWithContext:(NSManagedObjectContext*)context{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Request"];
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error){
        NSLog(@"error quering for items ordered by date");
    }
    return results;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Returns old requests ordered by their date of creation.
#pragma We use this to choose which requests are the oldest so we can delete them
#pragma ------------------------------------------------------------------------------------------------------
+(NSArray*)expiredRequestsWithContext:(NSManagedObjectContext*)context{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Request"];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error){
        NSLog(@"error quering for items ordered by date");
    }
    
    NSPredicate* requestPredicate = [NSPredicate predicateWithFormat:
                                     @"CAST(CAST(date, 'NSNumber') + timeout, 'NSDate') < %@", [NSDate date]];
    results = [results filteredArrayUsingPredicate:requestPredicate];
    
    return results;
}


@end
