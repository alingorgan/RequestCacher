//
//  RequestBuilder.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/28/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestBuilder : NSObject

typedef enum RequestType{
    RequestUsingGet = 0,
    RequestUsingPost = 1
} RequestType;

#pragma Properties
@property(nonatomic, strong) NSURL* url;
@property (nonatomic, strong) NSString* paramsString;
@property (nonatomic, readonly) NSString* urlStringWithParams;
@property (nonatomic) RequestType requestType;

#pragma Constructor
- (id)initWithRequestURL:(NSURL*)url;


@end
