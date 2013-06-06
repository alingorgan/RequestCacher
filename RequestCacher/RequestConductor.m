//
//  RequestConductor.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/28/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "RequestConductor.h"
#import "CoreDataStack.h"
#import "FileStore.h"
#import "Request+Cache.h"

@implementation RequestConductor

#pragma mark
#pragma Constants
#define kRequestTimeout 60

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#pragma mark
#pragma Properties
/// request queue
static NSMutableDictionary *queueCollection;

/// queue specific data key
static char kQueueKey;

#pragma ------------------------------------------------------------------------------------------------------
#pragma Init data
#pragma ------------------------------------------------------------------------------------------------------
+(void)initData{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //// create the backgorund request queue
        queueCollection = [[NSMutableDictionary alloc] initWithCapacity:16];
        
        //// enable cookie support
        /// Cookies are not shared among other apps, but the accept policy is...making sure it's allways enabled
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    });
    
    /// prepare coredata stack
    [[CoreDataStack sharedStackManager] setUp];
    
    /// prepare the file store
    [FileStore setUp];
    
    /// Perform maintenance on both database and files
    [Request runCacheMaintainanceWithContext:[[CoreDataStack sharedStackManager] managedObjectContext]];
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Starts loading the request
#pragma ------------------------------------------------------------------------------------------------------
+(NSString*)performRequest:(RequestBuilder*)builder
        andCompletionBlock:(void (^)(ResponseCart **))completionBlock{
    
    /// initialize required data
    [RequestConductor initData];
    
    NSString* requestTicket = [RequestConductor requestTicket];
    
    dispatch_queue_t downloadQueue = nil;
    downloadQueue = [queueCollection objectForKey:builder.urlStringWithParams];
    
    int taskCount = 0;
    
    if (downloadQueue == nil){
        ///create a new serial queue for the task
        NSLog(@"created queue for image %@", builder.urlStringWithParams);
        
        downloadQueue = dispatch_queue_create("Downloader Queue", NULL);
        [queueCollection setObject:downloadQueue forKey:builder.urlStringWithParams];
    }
    else{
        /// we're requesting the same image more than once, before the first request has finished loading
        /// we're adding this task to the serial queue
        
        NSNumber *taskCountNumber = (__bridge NSNumber*)dispatch_queue_get_specific(downloadQueue, &kQueueKey);
        taskCount = [taskCountNumber intValue];
        
        
        NSLog(@"reused existing queue for image %@", builder.urlStringWithParams);
    }
    
    /// Set specific data to the queue
    /// This is to know when all the queued tasks finish
    NSNumber *numberForQueue = [NSNumber numberWithInt:++taskCount];
    dispatch_queue_set_specific(downloadQueue, &kQueueKey, (__bridge_retained void *)numberForQueue, &taskNumberDestructor);
    
    NSLog(@"%d tasks in queue for %@", taskCount, builder.urlStringWithParams);
    
    /// run the DB requests and download on a separate thread
    dispatch_async(downloadQueue, ^{
            
        NSManagedObjectContext *managedObjectContext = [[CoreDataStack sharedStackManager] managedObjectContext];
        Request *cachedRequest = [Request requestWithURL:builder.urlStringWithParams
                                              andContext:managedObjectContext];
        
        NSData* downloadedData = [FileStore dataUsingFilePath:cachedRequest.responseFilePath];
        
        if (downloadedData == nil){
            /// there's no record of any request with this description
            /// download the data
            NSLog(@"requesting %@", builder.urlStringWithParams);
            downloadedData = [FileStore dataUsingSyncDownloadForRequestBuilder:builder
                                                                   withTimeout:kRequestTimeout];
                              
            if (downloadedData.length == 0){
                NSLog(@"empty download");
            }
        }
        
        if (downloadedData == nil){
            NSLog(@"this should never happen. the downloaded data is nil...");
            return;
        }
        
        ResponseCart* responseCart = [[ResponseCart alloc] initWithTicket:requestTicket
                                                          andResponseData:downloadedData
                                                                fromCache:(cachedRequest != nil)];
        
        /// transfer the response cart to the completion block
        /// the result response cart will be cached, if required
        responseCart = [RequestConductor transferResponseCart:responseCart
                                                   forRequest:builder
                                                   usingBlock:completionBlock];
        
        if (responseCart != nil){
            //// save the request to the cache
            [Request requestWithData:responseCart.responseData
                          requestURL:builder.urlStringWithParams
                             timeout:responseCart.cacheTimeout
                          andContext:managedObjectContext];
            
            [[CoreDataStack sharedStackManager] saveChangesToContext:managedObjectContext];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            /// Update the task count, as this task has finished
            NSNumber *taskCountNumber = (__bridge NSNumber*)dispatch_queue_get_specific(downloadQueue, &kQueueKey);
            int taskCount = [taskCountNumber intValue];
            --taskCount;
            
            if (taskCount == 0){
                /// there are no more requests on this stack
                /// allow ARC to release it by deleting any references to the stack
                [queueCollection removeObjectForKey:builder.urlStringWithParams];
                
                NSLog(@"removed queue for %@", builder.urlStringWithParams);
            }
            else{
                NSNumber *numberForQueue = [NSNumber numberWithInt:taskCount];
                dispatch_queue_set_specific(downloadQueue, &kQueueKey, (__bridge_retained void *)numberForQueue, &taskNumberDestructor);
                
                NSLog(@"%d tasks in queue for %@", taskCount, builder.urlStringWithParams);
            }
        });
    });
    
    return requestTicket;
}


#pragma ------------------------------------------------------------------------------------------------------
#pragma Pass the response to the caller via the completion block
#pragma ------------------------------------------------------------------------------------------------------
+(ResponseCart*)transferResponseCart:(ResponseCart*)responseCart
                          forRequest:(RequestBuilder*)requestBuilder
                          usingBlock:(void (^)(ResponseCart **))completionBlock{
    
    /// Run the completion block. This will run on the same background thread.
    completionBlock(&responseCart);
    
    
    /// choose what to do with the data
    if (responseCart.retrievedFromCache == YES){
        if (responseCart.shouldFetchLatestData == YES){
            NSData *downloadedData = [FileStore dataUsingSyncDownloadForRequestBuilder:requestBuilder
                                                                           withTimeout:kRequestTimeout];
            NSLog(@"fetching latest data for URL: %@", requestBuilder.urlStringWithParams);
            
            ResponseCart* latestResponseCart = [[ResponseCart alloc] initWithTicket:responseCart.ticket
                                                                    andResponseData:downloadedData
                                                                          fromCache:responseCart.retrievedFromCache];
            
            responseCart = [RequestConductor transferResponseCart:latestResponseCart
                                                       forRequest:requestBuilder
                                                       usingBlock:completionBlock];
            
        }
        else{
            /// so we don't cache an already cached request
            responseCart = nil;
        }
    }
    else{
        if (responseCart.shouldCache == YES){
            NSLog(@"user wants to cache data for URL:%@", requestBuilder.urlStringWithParams);
        }
        else{
            NSLog(@"not caching data for URL: %@", requestBuilder.urlStringWithParams);
            responseCart = nil;
        }
    }
    
    /// te response that will be cached, if required
    return responseCart;
}

#pragma ------------------------------------------------------------------------------------------------------
#pragma Destructor stub for the queue specific data
#pragma ------------------------------------------------------------------------------------------------------
static void taskNumberDestructor (void *taskNumber) {
	// although CFRelease() will crash if given NULL, dispatch_queue_set_specific()
	// will never invoke it if the queue is nil
	CFRelease(taskNumber);
}


#pragma ------------------------------------------------------------------------------------------------------
#pragma Generate a new UUID
#pragma ------------------------------------------------------------------------------------------------------
+(NSString *)requestTicket
{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")){
        return [[NSUUID UUID] UUIDString];
    }
    
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

@end
