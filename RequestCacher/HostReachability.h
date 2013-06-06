//
//  HostReachability.h
//  RequestCacher
//
//  Created by Gorgan Alin on 2/21/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HostReachability : NSObject

+(BOOL)isReachableHost:(NSURL*)hostURL;

@end
