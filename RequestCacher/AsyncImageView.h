//
//  AsyncImageView.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/7/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AsyncImageView : UIImageView

#pragma Properties
@property (nonatomic, strong) NSURL* photoURL;
@property (nonatomic, strong) NSString* photoURLParams;
@property (nonatomic) BOOL shouldDisplayActivityIndicator;

-(void)loadImageWithURL:(NSURL*)photoURL;
-(void)loadImageWithURL:(NSURL*)photoURL withParams:(NSString*)urlParams;

@end
