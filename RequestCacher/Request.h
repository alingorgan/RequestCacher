//
//  Request.h
//  RequestCacher
//
//  Created by Gorgan Alin on 2/27/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Request : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * responseFilePath;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * timeout;

@end
