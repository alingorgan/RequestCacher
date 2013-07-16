//
//  ResponseCart.m
//  RequestCacher
//
//  Created by Gorgan Alin on 2/1/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "ResponseCart.h"

@interface ResponseCart()

@property (nonatomic, strong) NSString* ticket;
@property (nonatomic, strong) NSData* responseData;
@property (nonatomic) BOOL retrievedFromCache;

@end

@implementation ResponseCart

@synthesize ticket = _ticket;
@synthesize responseData = _responseData;
@synthesize shouldCache = _shouldCache;
@synthesize shouldFetchLatestData = _shouldFetchLatestData;
@synthesize retrievedFromCache = _retrievedFromCache;
@synthesize cacheTimeout = _cacheTimeout;

-(id)initWithTicket:(NSString*)requestTicket andResponseData:(NSData*)downloadedData fromCache:(BOOL)fromCache{
    if (self = [super init]){
        ///custom intialization
        self.ticket = requestTicket;
        self.responseData = downloadedData;
        self.retrievedFromCache = fromCache;
        
        self.shouldCache = NO;
        self.shouldFetchLatestData = NO;
        self.cacheTimeout = 0;
    }
    
    return self;
}

@end
