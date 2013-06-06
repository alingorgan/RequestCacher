//
//  RequestBuilder.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/28/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "RequestBuilder.h"

@implementation RequestBuilder

@synthesize url = _url;
@synthesize urlStringWithParams = _urlStringWithParams;
@synthesize paramsString = _paramsString;
@synthesize requestType = _requestType;

#pragma Constructor

- (id)initWithRequestURL:(NSURL*)url{
    if (self = [super init]){
        /// Custom initialization
        self.url = url;
        self.requestType = RequestUsingGet;
    }
    return self;
}

#pragma Properties

//// returns a string representation of the data contained in the instance object
- (NSString*)urlStringWithParams{
    if (_urlStringWithParams == nil){
        
        /// set the url
        NSMutableString* resultString = [NSMutableString stringWithString:[self.url absoluteString]];
        
        /// set the params
        if (![self.paramsString isEqualToString:@""]){
            [resultString appendFormat:@"?%@",self.paramsString];
        }
        
        /// set the string url
        _urlStringWithParams = resultString;
        NSLog(@"urlString = %@", _urlStringWithParams);
    }
    
    return _urlStringWithParams;
}

@end
