//
//  NSDecodingFetchedResultsController.m
//  RequestCacher
//
//  Created by Gorgan Alin on 3/12/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "NSDecodingFetchedResultsController.h"
#import "CachedObject+Logic.m"

@implementation NSDecodingFetchedResultsController

-(id)objectAtIndexPath:(NSIndexPath *)indexPath{
    CachedObject *fetchedObject = [super objectAtIndexPath:indexPath];
    return [self decodeData:fetchedObject.encodedData];
}

-(id)decodeData:(NSData*)encodedData{
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
}

@end
