//
//  Request+Cache.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/30/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "Request.h"

@interface Request (Cache)

+(Request*)requestWithURL:(NSString*)requestURL
               andContext:(NSManagedObjectContext*)context;

+(Request*)requestWithData:(NSData*)requestData
                requestURL:(NSString*)requestURL
                   timeout:(NSTimeInterval)timeout
                andContext:(NSManagedObjectContext*)context;

+(void)removeAllCachedRequestsUsingContext:(NSManagedObjectContext*)context;
+(void)runCacheMaintainanceWithContext:(NSManagedObjectContext*)context;


@end
