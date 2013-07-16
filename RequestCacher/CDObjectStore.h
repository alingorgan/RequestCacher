//
//  CDObjectStore.h
//  RequestCacher
//
//  Created by Gorgan Alin on 3/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSDecodingFetchedResultsController.h"

@interface CDObjectStore : NSObject

+(NSDecodingFetchedResultsController*)fetchResultsControllerForGroup:(NSString*)group
                                                        andBatchSize:(NSInteger)batchRequestSize;

-(void)addObject:(id<NSCoding>)object
      matchingId:(NSString*)matchingId
         section:(NSString*)section
           group:(NSString*)group;

-(void)saveChanges;

@end
