//
//  CoreDataStack.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/10/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataStack : NSObject

+(CoreDataStack*)sharedStackManager;
-(NSManagedObjectContext*)managedObjectContext;

- (void)setUp;
- (void)saveChangesToContext:(NSManagedObjectContext*)managedObjectContext;
- (void)saveCurrentContextChanges;

@end
