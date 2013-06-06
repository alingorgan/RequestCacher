//
//  CachedObject+Logic.h
//  RequestCacher
//
//  Created by Gorgan Alin on 3/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "CachedObject.h"

@interface CachedObject (Logic)

+(CachedObject*)objectWithEncodedData:(NSData*)encodedData
                           matchingId:(NSString*)matchingId
                                group:(NSString*)group
                              section:(NSString*)section
                           andContext:(NSManagedObjectContext*)context;

@end
