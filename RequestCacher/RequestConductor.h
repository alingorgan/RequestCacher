//
//  RequestConductor.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/28/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RequestBuilder.h"
#import "ResponseCart.h"

@interface RequestConductor : NSObject

#pragma Methods
+(NSString*)performRequest:(RequestBuilder*)builder
        andCompletionBlock:(void (^)(ResponseCart **))completionBlock;

@end
