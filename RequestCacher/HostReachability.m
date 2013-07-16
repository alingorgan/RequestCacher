//
//  HostReachability.m
//  RequestCacher
//
//  Created by Gorgan Alin on 2/21/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "HostReachability.h"
#import "Reachability.h"

@interface HostReachability()

@property (nonatomic, strong) NSMutableDictionary *hostCollection;

@end

@implementation HostReachability

@synthesize hostCollection = _hostCollection;

+(BOOL)isReachableHost:(NSURL*)hostURL{
    
    BOOL isReachable = YES;
    HostReachability *hostReachability = [HostReachability sharedInstance];
    NSNumber *reachableNumber = [hostReachability.hostCollection objectForKey:hostURL.host];
    if (reachableNumber != nil){
        isReachable = [reachableNumber boolValue];
    }
    else{
        Reachability *reachability = [Reachability reachabilityWithHostname:hostURL.host];
        
        reachability.reachableBlock = reachability.unreachableBlock = reachabilityBlock;
    
        @synchronized(hostReachability.hostCollection){
            [hostReachability.hostCollection setObject:[NSNumber numberWithInt:ReachableViaWiFi] forKey:hostURL.host];
        }
        [reachability startNotifier];
    }
    return isReachable;
}

+(HostReachability*)sharedInstance{
    static HostReachability* sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HostReachability alloc] init];
        sharedInstance.hostCollection = [[NSMutableDictionary alloc] init];
    });
    
    return sharedInstance;
}

void (^reachabilityBlock)(Reachability *reach) = ^(Reachability* reachability){
    NSLog(@"reachability changed %@ status:%d", reachability.currentReachabilityString, reachability.currentReachabilityStatus);
    HostReachability *hostReachability = [HostReachability sharedInstance];
    @synchronized(hostReachability.hostCollection){
        [hostReachability.hostCollection setObject:[NSNumber numberWithInt:reachability.currentReachabilityStatus]
                                            forKey:reachability.hostURL];
    }
};


@end


