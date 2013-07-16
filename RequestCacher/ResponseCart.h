//
//  ResponseCart.h
//  RequestCacher
//
//  Created by Gorgan Alin on 2/1/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResponseCart : NSObject

@property (nonatomic, readonly, strong) NSString* ticket;
@property (nonatomic, readonly, strong) NSData* responseData;
@property (nonatomic, readonly) BOOL retrievedFromCache;
@property (nonatomic) BOOL shouldFetchLatestData;
@property (nonatomic) BOOL shouldCache;
@property (nonatomic) NSTimeInterval cacheTimeout;

#pragma Constructor
-(id)initWithTicket:(NSString*)requestTicket andResponseData:(NSData*)downloadedData fromCache:(BOOL)fromCache;

@end
