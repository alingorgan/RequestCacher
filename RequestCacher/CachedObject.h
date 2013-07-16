//
//  CachedObject.h
//  RequestCacher
//
//  Created by Gorgan Alin on 3/13/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CachedObject : NSManagedObject

@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSData * encodedData;
@property (nonatomic, retain) NSString * matchingId;
@property (nonatomic, retain) NSString * section;
@property (nonatomic, retain) NSString * group;

@end
